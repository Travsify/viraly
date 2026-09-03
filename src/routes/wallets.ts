import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';
import { z } from 'zod';
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

// ─── GET /api/wallets/me ───────────────────────────────────────────────────
router.get('/me', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    const walletRes = await query(
      `SELECT * FROM public.wallets WHERE user_id = $1`,
      [userId]
    );

    const bankRes = await query(
      `SELECT * FROM public.bank_accounts WHERE creator_id = $1 ORDER BY is_primary DESC`,
      [userId]
    );

    const txRes = await query(
      `SELECT * FROM public.transactions 
       WHERE wallet_id = $1 
       ORDER BY created_at DESC LIMIT 20`,
      [walletRes.rows[0]?.id]
    );

    res.json({
      success: true,
      wallet: walletRes.rows[0] || { available_balance: '0.00', pending_balance: '0.00', currency: 'NGN' },
      bankAccounts: bankRes.rows,
      recentTransactions: txRes.rows,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── POST /api/wallets/withdraw ────────────────────────────────────────────
// Bank-Grade Server-Side Cashout via Paystack Instant Disbursal
const withdrawSchema = z.object({
  amount: z.number().min(500, 'Minimum withdrawal in Nigeria is ₦500'),
  bank_code: z.string().min(2),
  account_number: z.string().length(10),
  account_name: z.string().min(2),
});

router.post('/withdraw', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { amount, bank_code, account_number, account_name } = withdrawSchema.parse(req.body);

    // 1. Regulatory KYC Check (Must have BVN verified)
    const profileRes = await query(
      `SELECT bvn_verified, full_name FROM public.profiles WHERE id = $1`,
      [userId]
    );

    if (profileRes.rows.length === 0 || !profileRes.rows[0].bvn_verified) {
      return res.status(403).json({
        success: false,
        error: 'CBN Compliance: You must complete BVN identity verification before withdrawing earnings.',
      });
    }

    // 2. Atomic Row-Locking on Creator Wallet
    const walletRes = await query(
      `SELECT id, available_balance FROM public.wallets WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    if (walletRes.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Wallet not found.' });
    }

    const wallet = walletRes.rows[0];
    const currentBalance = Number(wallet.available_balance);

    if (currentBalance < amount) {
      return res.status(400).json({
        success: false,
        error: `Insufficient funds. Available: ₦${currentBalance.toLocaleString()}, Requested: ₦${amount.toLocaleString()}`,
      });
    }

    // 3. Initiate Paystack NIP Disbursal
    let transferCode: string;
    const transferRef = `wdr_${Date.now()}_${userId.substring(0, 6)}`;

    try {
      // Step A: Create Paystack Transfer Recipient
      const recipientRes = await paystackRequest('POST', '/transferrecipient', {
        type: 'nuban',
        name: account_name,
        account_number,
        bank_code,
        currency: 'NGN',
      });

      if (!recipientRes.status || !recipientRes.data?.recipient_code) {
        throw new Error(recipientRes.message || 'Failed to create Paystack transfer recipient');
      }

      const recipientCode = recipientRes.data.recipient_code;

      // Step B: Initiate Transfer (amount in kobo)
      const transferRes = await paystackRequest('POST', '/transfer', {
        source: 'balance',
        amount: Math.round(amount * 100),
        recipient: recipientCode,
        reason: `Viraly Creator Payout - ${account_name}`,
        reference: transferRef,
      });

      if (!transferRes.status) {
        throw new Error(transferRes.message || 'Paystack transfer initiation failed');
      }

      transferCode = transferRes.data.transfer_code || transferRef;
      console.log(`[Payout] Paystack transfer initiated: ${transferCode} for ₦${amount} to ${account_name}`);
    } catch (paystackErr: any) {
      console.error('[Payout] Paystack transfer error:', paystackErr.message);
      return res.status(502).json({
        success: false,
        error: `Paystack disbursal error: ${paystackErr.message}`,
      });
    }

    // 4. Deduct balance and record transaction in atomic DB update
    await query(
      `UPDATE public.wallets 
       SET available_balance = available_balance - $1, 
           updated_at = NOW() 
       WHERE id = $2`,
      [amount, wallet.id]
    );

    await query(
      `INSERT INTO public.transactions (wallet_id, type, amount, status, reference, description)
       VALUES ($1, 'withdrawal', $2, 'processing', $3, $4)`,
      [
        wallet.id,
        amount,
        transferCode,
        `Withdrawal to ${account_name} (${account_number}) via Paystack NIP`,
      ]
    );

    return res.json({
      success: true,
      message: `₦${amount.toLocaleString()} cashout initiated via Paystack NIP transfer!`,
      reference: transferCode,
      amount,
    });
  } catch (error: any) {
    console.error('[Payout] Withdrawal exception:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
