import { Router, Request, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth } from '../middleware/auth.js';
import { FlutterwaveService } from '../services/flutterwave.js';
import https from 'https';

const router = Router();

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY || '';

// ─── Helper: Paystack API ──────────────────────────────────────────────────
function paystackRequest(method: string, path: string, body?: object): Promise<any> {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : undefined;
    const options = {
      hostname: 'api.paystack.co',
      port: 443,
      path,
      method,
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); }
        catch (e) { reject(new Error('Invalid JSON from Paystack')); }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// ─── POST /api/agency/campaigns/fund ──────────────────────────────────────
// Creates a Flutterwave (default) or Paystack escrow funding checkout link
router.post('/campaigns/fund', requireAuth, async (req: Request, res: Response) => {
  try {
    const { campaign_id, amount, email, gateway = 'flutterwave' } = req.body as {
      campaign_id: string;
      amount: number;
      email: string;
      gateway?: 'flutterwave' | 'paystack';
    };

    if (!campaign_id || !amount || !email) {
      return res.status(400).json({ error: 'campaign_id, amount, and email are required.' });
    }

    if (amount < 1000) {
      return res.status(400).json({ error: 'Minimum campaign budget is ₦1,000.' });
    }

    // Verify campaign exists
    const campCheck = await query(
      'SELECT id, title, status FROM public.campaigns WHERE id = $1',
      [campaign_id]
    );
    if (campCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Campaign not found.' });
    }

    const campaignTitle = campCheck.rows[0].title;

    // 1. FLUTTERWAVE CHECKOUT (Primary for Viraly Mobile)
    if (gateway === 'flutterwave') {
      const flwRes = await FlutterwaveService.initializePayment({
        campaignId: campaign_id,
        campaignTitle,
        amount,
        email,
      });

      if (!flwRes.status || !flwRes.link) {
        return res.status(502).json({ error: flwRes.message || 'Flutterwave checkout initialization failed.' });
      }

      await query(
        `UPDATE public.campaigns SET status = 'pending_payment', updated_at = NOW() WHERE id = $1`,
        [campaign_id]
      );

      return res.json({
        success: true,
        gateway: 'flutterwave',
        authorization_url: flwRes.link,
        reference: flwRes.txRef,
      });
    }

    // 2. PAYSTACK CHECKOUT (Secondary fallback)
    const amountKobo = Math.round(amount * 100);
    const reference = `viraly_esc_${campaign_id.substring(0, 8)}_${Date.now()}`;
    const callbackUrl = `${process.env.BACKEND_URL || 'https://iswitch-l82a.onrender.com'}/api/agency/campaigns/payment-callback?campaign_id=${campaign_id}`;

    const paystackRes = await paystackRequest('POST', '/transaction/initialize', {
      email,
      amount: amountKobo,
      reference,
      callback_url: callbackUrl,
      metadata: { campaign_id, campaign_title: campaignTitle },
      channels: ['card', 'bank', 'ussd', 'bank_transfer', 'mobile_money'],
    });

    if (!paystackRes.status) {
      return res.status(502).json({ error: 'Paystack initialization failed.', detail: paystackRes.message });
    }

    await query(
      `UPDATE public.campaigns SET status = 'pending_payment', updated_at = NOW() WHERE id = $1`,
      [campaign_id]
    );

    return res.json({
      success: true,
      gateway: 'paystack',
      authorization_url: paystackRes.data.authorization_url,
      reference: paystackRes.data.reference,
    });
  } catch (error) {
    console.error('[Agency Fund] Error:', error);
    return res.status(500).json({ error: 'Internal server error during campaign funding.' });
  }
});

// ─── GET /api/agency/campaigns/flutterwave-callback ────────────────────────
// Flutterwave redirects here after user completes payment
router.get('/campaigns/flutterwave-callback', async (req: Request, res: Response) => {
  try {
    const { status, tx_ref, transaction_id, campaign_id } = req.query as {
      status?: string;
      tx_ref?: string;
      transaction_id?: string;
      campaign_id?: string;
    };

    if (status !== 'successful' && status !== 'completed') {
      return res.send(`
        <html><body style="background:#07090E;color:#fff;font-family:sans-serif;padding:40px;text-align:center;">
          <h2 style="color:#f43f5e;">Payment Cancelled or Failed</h2>
          <p>Status: ${status || 'Unknown'}</p>
          <p style="color:#94a3b8;">You can close this window and try again from the app.</p>
        </body></html>
      `);
    }

    let amountPaid = 0;

    // Verify transaction with Flutterwave API
    if (transaction_id) {
      const verifyRes = await FlutterwaveService.verifyTransaction(transaction_id);
      if (verifyRes.status && verifyRes.data?.status === 'successful') {
        amountPaid = Number(verifyRes.data.amount);
      }
    }

    if (campaign_id) {
      await query(
        `UPDATE public.campaigns 
         SET status = 'active', 
             total_budget = CASE WHEN $1 > 0 THEN $1 ELSE total_budget END, 
             remaining_budget = CASE WHEN $1 > 0 THEN $1 ELSE remaining_budget END, 
             updated_at = NOW() 
         WHERE id = $2`,
        [amountPaid, campaign_id]
      );
    }

    return res.send(`
      <html><body style="background:#07090E;color:#fff;font-family:sans-serif;padding:40px;text-align:center;">
        <h1 style="color:#00F59B;">✅ Campaign Escrow Funded via Flutterwave!</h1>
        <p style="font-size:18px;">₦${amountPaid > 0 ? amountPaid.toLocaleString() : 'Funds'} confirmed and locked in escrow.</p>
        <p style="color:#94a3b8;">Creators can now see and submit videos for your bounty.</p>
        <p style="color:#6366F1;font-weight:bold;">Return to the Viraly app to track creator virality.</p>
      </body></html>
    `);
  } catch (error) {
    console.error('[Flutterwave Callback] Error:', error);
    return res.status(500).send('Error verifying Flutterwave payment.');
  }
});

// ─── GET /api/agency/campaigns/payment-callback (Paystack) ─────────────────
router.get('/campaigns/payment-callback', async (req: Request, res: Response) => {
  try {
    const { reference, campaign_id } = req.query as { reference: string; campaign_id: string };

    if (!reference) {
      return res.status(400).send('Missing payment reference.');
    }

    const verifyRes = await paystackRequest('GET', `/transaction/verify/${encodeURIComponent(reference)}`);

    if (!verifyRes.status || verifyRes.data?.status !== 'success') {
      return res.send(`
        <html><body style="background:#07090E;color:#fff;font-family:sans-serif;padding:40px;text-align:center;">
          <h2 style="color:#f43f5e;">Payment Verification Failed</h2>
          <p>Reference: ${reference}</p>
        </body></html>
      `);
    }

    const amountPaid = verifyRes.data.amount / 100;
    const campId = campaign_id || verifyRes.data.metadata?.campaign_id;

    if (campId) {
      await query(
        `UPDATE public.campaigns 
         SET status = 'active', 
             total_budget = $1, 
             remaining_budget = $1, 
             updated_at = NOW() 
         WHERE id = $2`,
        [amountPaid, campId]
      );
    }

    return res.send(`
      <html><body style="background:#07090E;color:#fff;font-family:sans-serif;padding:40px;text-align:center;">
        <h1 style="color:#00F59B;">✅ Campaign Funded via Paystack!</h1>
        <p style="font-size:20px;">₦${amountPaid.toLocaleString()} escrow pool is now live.</p>
        <p style="color:#6366F1;">You can close this window and return to the Viraly app.</p>
      </body></html>
    `);
  } catch (error) {
    console.error('[Paystack Callback] Error:', error);
    return res.status(500).send('Error verifying payment.');
  }
});

export default router;
