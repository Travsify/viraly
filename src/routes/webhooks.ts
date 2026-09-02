import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { query } from '../config/db.js';

const router = Router();

router.post('/paystack', async (req: Request, res: Response) => {
  try {
    const paystackSecret = process.env.PAYSTACK_SECRET_KEY || '';
    const hash = crypto
      .createHmac('sha512', paystackSecret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== req.headers['x-paystack-signature']) {
      return res.status(401).send('Invalid signature');
    }

    const event = req.body;
    console.log('[Webhook] Paystack event received:', event.event);

    // 1. Escrow deposit success
    if (event.event === 'charge.success') {
      const data = event.data;
      const reference = data.reference;
      const amountInNaira = Number(data.amount) / 100;
      const campaignId = data.metadata?.campaign_id;

      if (campaignId) {
        await query(
          `UPDATE public.campaigns SET status = 'active', updated_at = NOW() WHERE id = $1`,
          [campaignId]
        );
        console.log(`[Webhook] Campaign ${campaignId} activated after successful escrow deposit of ₦${amountInNaira}`);
      }
    }

    // 2. Transfer payout success
    if (event.event === 'transfer.success') {
      const data = event.data;
      const transferCode = data.transfer_code;

      await query(
        `UPDATE public.transactions 
         SET status = 'completed', updated_at = NOW() 
         WHERE paystack_transfer_code = $1`,
        [transferCode]
      );
      console.log(`[Webhook] Transfer ${transferCode} marked as completed.`);
    }

    res.sendStatus(200);
  } catch (error) {
    console.error('[Webhook] Paystack webhook error:', error);
    res.sendStatus(500);
  }
});

export default router;
