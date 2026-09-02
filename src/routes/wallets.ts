import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';
import { z } from 'zod';

const router = Router();

// GET /api/wallets/me - Get user's wallet balance and ledger
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
      recentTransactions: txRes.rows
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/wallets/bank-account - Add payout bank account (OPay, PalmPay, Kuda, etc.)
const addBankSchema = z.object({
  bank_code: z.string(),
  bank_name: z.string(),
  account_number: z.string().length(10),
  account_name: z.string().min(2)
});

router.post('/bank-account', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const body = addBankSchema.parse(req.body);

    const result = await query(
      `INSERT INTO public.bank_accounts (creator_id, bank_code, bank_name, account_number, account_name)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, body.bank_code, body.bank_name, body.account_number, body.account_name]
    );

    res.status(201).json({ success: true, message: 'Bank account added successfully', data: result.rows[0] });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// POST /api/wallets/withdraw - Request cashout to bank account
const withdrawSchema = z.object({
  amount: z.number().min(1000, 'Minimum withdrawal in Nigeria is ₦1,000'),
  bank_account_id: z.string().uuid()
});

router.post('/withdraw', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { amount, bank_account_id } = withdrawSchema.parse(req.body);

    // 1. Verify wallet has sufficient funds
    const walletRes = await query(
      `SELECT id, available_balance FROM public.wallets WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    const wallet = walletRes.rows[0];
    if (!wallet || Number(wallet.available_balance) < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient available balance' });
    }

    // 2. Verify bank account
    const bankRes = await query(
      `SELECT * FROM public.bank_accounts WHERE id = $1 AND creator_id = $2`,
      [bank_account_id, userId]
    );

    if (bankRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Bank account not found' });
    }

    // 3. Deduct from wallet & create transaction
    const reference = `wdr_${Date.now()}_${userId.substring(0, 6)}`;
    await query(
      `UPDATE public.wallets SET available_balance = available_balance - $1, updated_at = NOW() WHERE id = $2`,
      [amount, wallet.id]
    );

    await query(
      `INSERT INTO public.transactions (wallet_id, type, amount, status, reference, description)
       VALUES ($1, 'withdrawal', $2, 'pending', $3, $4)`,
      [wallet.id, amount, reference, `Withdrawal to ${bankRes.rows[0].bank_name} (${bankRes.rows[0].account_number})`]
    );

    res.json({
      success: true,
      message: 'Withdrawal requested successfully! Processing via instant Paystack NIP transfer.',
      reference,
      amount
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

export default router;
