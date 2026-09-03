import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { query } from '../config/db.js';

const router = Router();

// ─── POST /api/webhooks/paystack ───────────────────────────────────────────
// Receives all Paystack server-to-server events. Verified via HMAC SHA512.
router.post('/paystack', async (req: Request, res: Response) => {
  try {
    const paystackSecret = process.env.PAYSTACK_SECRET_KEY || '';

    // 1. Verify webhook signature
    const hash = crypto
      .createHmac('sha512', paystackSecret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      console.warn('[Webhook] Invalid Paystack signature rejected.');
      return res.status(401).send('Invalid signature');
    }

    const event = req.body;
    console.log('[Webhook] Paystack event received:', event.event);

    // ── 2. Escrow/campaign funding confirmed ────────────────────────────────
    if (event.event === 'charge.success') {
      const data = event.data;
      const amountInNaira = Number(data.amount) / 100;
      const campaignId = data.metadata?.campaign_id;
      const reference = data.reference;

      if (campaignId) {
        // Activate campaign and set budget
        await query(
          `UPDATE public.campaigns 
           SET status = 'active',
               total_budget = CASE WHEN total_budget = 0 THEN $1 ELSE total_budget END,
               remaining_budget = CASE WHEN remaining_budget = 0 THEN $1 ELSE remaining_budget END,
               updated_at = NOW() 
           WHERE id = $2`,
          [amountInNaira, campaignId]
        );
        console.log(`[Webhook] ✅ Campaign ${campaignId} ACTIVATED — ₦${amountInNaira} escrow deposited (ref: ${reference})`);
      }
    }

    // ── 3. Creator payout transfer confirmed ────────────────────────────────
    if (event.event === 'transfer.success') {
      const data = event.data;
      const transferCode = data.transfer_code;

      await query(
        `UPDATE public.transactions 
         SET status = 'completed', updated_at = NOW() 
         WHERE reference = $1 OR description LIKE $2`,
        [transferCode, `%${transferCode}%`]
      );
      console.log(`[Webhook] ✅ Transfer ${transferCode} marked as completed.`);
    }

    // ── 4. Creator payout transfer failed ───────────────────────────────────
    if (event.event === 'transfer.failed' || event.event === 'transfer.reversed') {
      const data = event.data;
      const transferCode = data.transfer_code;
      const reason = data.gateway_response || event.event;

      // Reverse the wallet deduction — credit back
      const txRes = await query(
        `SELECT wallet_id, amount FROM public.transactions WHERE reference = $1`,
        [transferCode]
      );

      if (txRes.rows.length > 0) {
        const { wallet_id, amount } = txRes.rows[0];
        await query(
          `UPDATE public.wallets SET available_balance = available_balance + $1, updated_at = NOW() WHERE id = $2`,
          [amount, wallet_id]
        );
        await query(
          `UPDATE public.transactions SET status = 'failed', description = $1, updated_at = NOW() WHERE reference = $2`,
          [`Transfer failed: ${reason}`, transferCode]
        );
        console.log(`[Webhook] ⚠️  Transfer ${transferCode} FAILED — ₦${amount} reversed back to wallet.`);
      }
    }

    // ── 5. Subscription or recurring payment events (future use) ────────────
    if (event.event === 'subscription.create') {
      console.log('[Webhook] New subscription created:', event.data?.subscription_code);
    }

    res.sendStatus(200);
  } catch (error) {
    console.error('[Webhook] Paystack webhook error:', error);
    res.sendStatus(500);
  }
});

export default router;
