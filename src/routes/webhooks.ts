import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { query } from '../config/db.js';

const router = Router();

// ─── POST /api/webhooks/flutterwave ────────────────────────────────────────
// Flutterwave server-to-server webhook for campaign escrow funding
router.post('/flutterwave', async (req: Request, res: Response) => {
  try {
    const secretHash = process.env.FLUTTERWAVE_SECRET_HASH || 'hometrust_flw_webhook_secret_2026';
    const signature = req.headers['verif-hash'];

    if (secretHash && signature !== secretHash) {
      console.warn('[Webhook] Invalid Flutterwave secret hash rejected.');
      return res.status(401).send('Invalid signature');
    }

    const payload = req.body;
    console.log('[Webhook] Flutterwave event received:', payload.event, payload.data?.status);

    if (payload.event === 'charge.completed' && payload.data?.status === 'successful') {
      const data = payload.data;
      const campaignId = data.meta?.campaign_id;
      const amount = Number(data.amount || 0);

      if (campaignId) {
        await query(
          `UPDATE public.campaigns 
           SET status = 'active', 
               total_budget = CASE WHEN total_budget = 0 THEN $1 ELSE total_budget END,
               remaining_budget = CASE WHEN remaining_budget = 0 THEN $1 ELSE remaining_budget END,
               updated_at = NOW() 
           WHERE id = $2`,
          [amount, campaignId]
        );
        console.log(`[Webhook] ✅ Campaign ${campaignId} ACTIVATED via Flutterwave escrow (₦${amount})`);
      }
    }

    return res.sendStatus(200);
  } catch (error) {
    console.error('[Webhook] Flutterwave webhook error:', error);
    return res.sendStatus(500);
  }
});

// ─── POST /api/webhooks/paystack ───────────────────────────────────────────
// Paystack server-to-server webhook for escrow deposits and creator payouts
router.post('/paystack', async (req: Request, res: Response) => {
  try {
    const paystackSecret = process.env.PAYSTACK_SECRET_KEY || '';

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

    // 1. Escrow deposit success
    if (event.event === 'charge.success') {
      const data = event.data;
      const amountInNaira = Number(data.amount) / 100;
      const campaignId = data.metadata?.campaign_id;
      const reference = data.reference;

      if (campaignId) {
        await query(
          `UPDATE public.campaigns 
           SET status = 'active',
               total_budget = CASE WHEN total_budget = 0 THEN $1 ELSE total_budget END,
               remaining_budget = CASE WHEN remaining_budget = 0 THEN $1 ELSE remaining_budget END,
               updated_at = NOW() 
           WHERE id = $2`,
          [amountInNaira, campaignId]
        );
        console.log(`[Webhook] ✅ Campaign ${campaignId} ACTIVATED via Paystack escrow (₦${amountInNaira}, ref: ${reference})`);
      }
    }

    // 2. Creator payout transfer confirmed
    if (event.event === 'transfer.success') {
      const data = event.data;
      const transferCode = data.transfer_code;

      await query(
        `UPDATE public.transactions 
         SET status = 'completed', updated_at = NOW() 
         WHERE reference = $1 OR description LIKE $2`,
        [transferCode, `%${transferCode}%`]
      );
      console.log(`[Webhook] ✅ Creator payout ${transferCode} marked as completed.`);
    }

    // 3. Creator payout transfer failed — reverse back to wallet
    if (event.event === 'transfer.failed' || event.event === 'transfer.reversed') {
      const data = event.data;
      const transferCode = data.transfer_code;
      const reason = data.gateway_response || event.event;

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
        console.log(`[Webhook] ⚠️  Transfer ${transferCode} FAILED — ₦${amount} restored to creator wallet.`);
      }
    }

    res.sendStatus(200);
  } catch (error) {
    console.error('[Webhook] Paystack webhook error:', error);
    res.sendStatus(500);
  }
});

export default router;
