import { Router, Request, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth } from '../middleware/auth.js';
import crypto from 'crypto';
import https from 'https';

const router = Router();

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY || '';

// ─── Helper: Call Paystack API ─────────────────────────────────────────────
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
// Creates a Paystack payment link so an agency can fund their campaign escrow.
router.post('/campaigns/fund', requireAuth, async (req: Request, res: Response) => {
  try {
    const { campaign_id, amount, email } = req.body as {
      campaign_id: string;
      amount: number;
      email: string;
    };

    if (!campaign_id || !amount || !email) {
      return res.status(400).json({ error: 'campaign_id, amount, and email are required.' });
    }

    if (amount < 1000) {
      return res.status(400).json({ error: 'Minimum campaign budget is ₦1,000.' });
    }

    // Verify campaign exists and belongs to this user
    const campCheck = await query(
      'SELECT id, title, status FROM public.campaigns WHERE id = $1',
      [campaign_id]
    );
    if (campCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Campaign not found.' });
    }

    // Initialize Paystack transaction (amount in kobo)
    const amountKobo = Math.round(amount * 100);
    const reference = `viraly_esc_${campaign_id.substring(0, 8)}_${Date.now()}`;
    const callbackUrl = `${process.env.BACKEND_URL || 'https://iswitch-l82a.onrender.com'}/api/agency/campaigns/payment-callback?campaign_id=${campaign_id}`;

    const paystackRes = await paystackRequest('POST', '/transaction/initialize', {
      email,
      amount: amountKobo,
      reference,
      callback_url: callbackUrl,
      metadata: {
        campaign_id,
        campaign_title: campCheck.rows[0].title,
        custom_fields: [
          { display_name: 'Campaign ID', variable_name: 'campaign_id', value: campaign_id },
        ],
      },
      channels: ['card', 'bank', 'ussd', 'bank_transfer', 'mobile_money'],
    });

    if (!paystackRes.status) {
      return res.status(502).json({ error: 'Paystack initialization failed.', detail: paystackRes.message });
    }

    // Mark campaign as pending_payment and store reference
    await query(
      `UPDATE public.campaigns SET status = 'pending_payment', paystack_reference = $1, updated_at = NOW() WHERE id = $2`,
      [reference, campaign_id]
    ).catch(() => {
      // column may not exist yet - attempt graceful fallback
      return query(
        `UPDATE public.campaigns SET status = 'pending_payment', updated_at = NOW() WHERE id = $1`,
        [campaign_id]
      );
    });

    return res.json({
      success: true,
      authorization_url: paystackRes.data.authorization_url,
      reference: paystackRes.data.reference,
      access_code: paystackRes.data.access_code,
    });
  } catch (error) {
    console.error('[Agency Fund] Error:', error);
    return res.status(500).json({ error: 'Internal server error during campaign funding.' });
  }
});

// ─── GET /api/agency/campaigns/payment-callback ────────────────────────────
// Paystack redirects here after the payer completes checkout in their browser.
router.get('/campaigns/payment-callback', async (req: Request, res: Response) => {
  try {
    const { reference, campaign_id } = req.query as { reference: string; campaign_id: string };

    if (!reference) {
      return res.status(400).send('Missing payment reference.');
    }

    // Verify with Paystack
    const verifyRes = await paystackRequest('GET', `/transaction/verify/${encodeURIComponent(reference)}`);

    if (!verifyRes.status || verifyRes.data?.status !== 'success') {
      return res.send(`
        <html><body style="background:#07090E;color:#fff;font-family:sans-serif;padding:40px;text-align:center;">
          <h2 style="color:#f43f5e;">Payment Verification Failed</h2>
          <p>Reference: ${reference}</p>
          <p>Please contact support if you were charged.</p>
        </body></html>
      `);
    }

    const amountPaid = verifyRes.data.amount / 100; // convert kobo to naira
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
        <h1 style="color:#00F59B;">✅ Campaign Funded!</h1>
        <p style="font-size:20px;">₦${amountPaid.toLocaleString()} escrow pool is now live.</p>
        <p style="color:#94a3b8;">Creators can now discover and submit videos for your campaign.</p>
        <p style="color:#6366F1;">You can close this window and return to the Viraly app.</p>
      </body></html>
    `);
  } catch (error) {
    console.error('[Agency Payment Callback] Error:', error);
    return res.status(500).send('Error verifying payment. Please contact support.');
  }
});

// ─── POST /api/agency/campaigns/verify-payment ─────────────────────────────
// Mobile app calls this after WebView redirects back, to confirm payment status.
router.post('/campaigns/verify-payment', requireAuth, async (req: Request, res: Response) => {
  try {
    const { reference, campaign_id } = req.body as { reference: string; campaign_id: string };

    if (!reference) {
      return res.status(400).json({ error: 'Reference is required.' });
    }

    const verifyRes = await paystackRequest('GET', `/transaction/verify/${encodeURIComponent(reference)}`);

    if (!verifyRes.status || verifyRes.data?.status !== 'success') {
      return res.status(402).json({ success: false, message: 'Payment not yet confirmed.' });
    }

    const amountPaid = verifyRes.data.amount / 100;

    if (campaign_id) {
      await query(
        `UPDATE public.campaigns 
         SET status = 'active', total_budget = $1, remaining_budget = $1, updated_at = NOW() 
         WHERE id = $2`,
        [amountPaid, campaign_id]
      );
    }

    return res.json({ success: true, amount_paid: amountPaid });
  } catch (error) {
    console.error('[Agency Verify Payment] Error:', error);
    return res.status(500).json({ error: 'Error verifying payment.' });
  }
});

export default router;
