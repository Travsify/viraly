import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAdmin, AuthenticatedRequest } from '../middleware/auth.js';
import { getNigerianBanksList, resolveBankAccount, createTransferRecipient, initiatePaystackTransfer } from '../services/paystack.js';
import { z } from 'zod';

const router = Router();

// Apply requireAdmin to all admin API endpoints
router.use(requireAdmin);

// 0. GET /api/admin/me - Verify admin identity
router.get('/me', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const profile = await query('SELECT id, full_name, email, role, avatar_url FROM public.profiles WHERE id = $1', [req.user!.id]);
    res.json({ success: true, admin: profile.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 1. GET /api/admin/stats - Real-time aggregates directly from PostgreSQL
router.get('/stats', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const statsQuery = `
      SELECT 
        (SELECT COUNT(*) FROM public.profiles WHERE role = 'creator') AS total_creators,
        (SELECT COUNT(*) FROM public.profiles WHERE role = 'agency') AS total_agencies,
        (SELECT COUNT(*) FROM public.campaigns WHERE status = 'active') AS active_campaigns,
        (SELECT COALESCE(SUM(total_budget), 0) FROM public.campaigns) AS total_escrow_deposited,
        (SELECT COALESCE(SUM(remaining_budget), 0) FROM public.campaigns WHERE status = 'active') AS active_escrow_remaining,
        (SELECT COALESCE(SUM(current_views), 0) FROM public.campaigns) AS total_views_generated,
        (SELECT COALESCE(SUM(current_clicks), 0) FROM public.campaigns) AS total_clicks_generated,
        (SELECT COUNT(*) FROM public.submissions WHERE status = 'pending_review') AS pending_submissions,
        (SELECT COUNT(*) FROM public.transactions WHERE type = 'withdrawal' AND status = 'pending') AS pending_payouts,
        (SELECT COALESCE(SUM(amount), 0) FROM public.transactions WHERE type = 'withdrawal' AND status = 'completed') AS total_paid_out
    `;

    const result = await query(statsQuery);
    res.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 2. GET /api/admin/submissions - List submissions with creator & campaign details
router.get('/submissions', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { status } = req.query;
    let sql = `
      SELECT s.*, 
             c.title AS campaign_title, c.cpm_rate, c.cpc_rate, c.status AS campaign_status,
             p.full_name AS creator_name, p.email AS creator_email, p.tiktok_handle AS creator_tiktok,
             r.slug AS referral_slug, r.qualified_clicks
      FROM public.submissions s
      JOIN public.campaigns c ON s.campaign_id = c.id
      JOIN public.profiles p ON s.creator_id = p.id
      LEFT JOIN public.referral_links r ON (r.campaign_id = s.campaign_id AND r.creator_id = s.creator_id)
      WHERE 1=1
    `;
    const params: any[] = [];

    if (status && status !== 'all') {
      params.push(status);
      sql += ` AND s.status = $${params.length}`;
    }

    sql += ` ORDER BY s.created_at DESC LIMIT 100`;

    const result = await query(sql, params);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 3. POST /api/admin/submissions/:id/review - Approve or Reject submission
const reviewSchema = z.object({
  status: z.enum(['tracking', 'rejected', 'capped', 'pending_review']),
  rejection_reason: z.string().optional()
});

router.post('/submissions/:id/review', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status, rejection_reason } = reviewSchema.parse(req.body);

    const result = await query(
      `UPDATE public.submissions 
       SET status = $1, rejection_reason = $2, updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [status, rejection_reason || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Submission not found' });
    }

    res.json({ success: true, message: `Submission updated to ${status}`, data: result.rows[0] });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// 4. GET /api/admin/campaigns - List all brand campaigns
router.get('/campaigns', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const sql = `
      SELECT c.*, p.full_name AS agency_name, p.email AS agency_email,
             (SELECT COUNT(*) FROM public.submissions s WHERE s.campaign_id = c.id) AS submission_count,
             (SELECT COUNT(*) FROM public.referral_links r WHERE r.campaign_id = c.id) AS active_creator_links
      FROM public.campaigns c
      JOIN public.profiles p ON c.agency_id = p.id
      ORDER BY c.created_at DESC
    `;
    const result = await query(sql);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 5. POST /api/admin/campaigns - Create a new campaign from the Admin Portal
const adminCreateCampaignSchema = z.object({
  agency_id: z.string().uuid().optional(),
  title: z.string().min(3),
  description: z.string().min(10),
  category: z.string(),
  objective: z.enum(['views_only', 'clicks_only', 'hybrid']),
  total_budget: z.number().positive(),
  cpm_rate: z.number().default(0),
  cpc_rate: z.number().default(0),
  max_payout_per_creator: z.number().optional(),
  view_cap: z.number().optional(),
  click_cap: z.number().optional(),
  target_destination_url: z.string().url().optional(),
  required_hashtags: z.array(z.string()).default([]),
  required_mentions: z.array(z.string()).default([])
});

router.post('/campaigns', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const body = adminCreateCampaignSchema.parse(req.body);

    let agencyId = body.agency_id || req.user!.id;

    const result = await query(
      `INSERT INTO public.campaigns (
        agency_id, title, description, category, objective, status,
        total_budget, remaining_budget, cpm_rate, cpc_rate, max_payout_per_creator,
        view_cap, click_cap, target_destination_url, required_hashtags, required_mentions
      ) VALUES ($1, $2, $3, $4, $5, 'active', $6, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        agencyId,
        body.title,
        body.description,
        body.category,
        body.objective,
        body.total_budget,
        body.cpm_rate,
        body.cpc_rate,
        body.max_payout_per_creator || null,
        body.view_cap || null,
        body.click_cap || null,
        body.target_destination_url || null,
        body.required_hashtags,
        body.required_mentions
      ]
    );

    res.status(201).json({ success: true, message: 'Campaign created successfully!', data: result.rows[0] });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// 6. POST /api/admin/campaigns/:id/topup - Top up campaign escrow budget
router.post('/campaigns/:id/topup', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { topup_amount } = z.object({ topup_amount: z.number().positive() }).parse(req.body);

    const result = await query(
      `UPDATE public.campaigns 
       SET total_budget = total_budget + $1,
           remaining_budget = remaining_budget + $1,
           status = CASE WHEN status = 'completed' THEN 'active' ELSE status END,
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [topup_amount, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }

    res.json({ success: true, message: `₦${topup_amount.toLocaleString()} added to escrow pool`, data: result.rows[0] });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// 7. PATCH /api/admin/campaigns/:id/status - Update campaign status (pause, resume)
router.patch('/campaigns/:id/status', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['draft', 'active', 'paused', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid campaign status' });
    }

    const result = await query(
      `UPDATE public.campaigns SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }

    res.json({ success: true, message: `Campaign status changed to ${status}`, data: result.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 8. GET /api/admin/users - User management (Creators & Agencies)
router.get('/users', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const sql = `
      SELECT p.*, w.available_balance, w.pending_balance,
             (SELECT COUNT(*) FROM public.submissions s WHERE s.creator_id = p.id) AS total_submissions,
             (SELECT COUNT(*) FROM public.campaigns c WHERE c.agency_id = p.id) AS total_campaigns
      FROM public.profiles p
      LEFT JOIN public.wallets w ON w.user_id = p.id
      ORDER BY p.created_at DESC
    `;
    const result = await query(sql);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 9. PATCH /api/admin/users/:id/verify - Toggle user verification badge
router.patch('/users/:id/verify', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { is_verified } = req.body;

    const result = await query(
      `UPDATE public.profiles SET is_verified = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [Boolean(is_verified), id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 10. GET /api/admin/payouts - Payout requests & transactions ledger
router.get('/payouts', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const sql = `
      SELECT t.*, w.user_id, p.full_name, p.email, p.phone_number,
             b.bank_code, b.bank_name, b.account_number, b.account_name, b.paystack_recipient_code
      FROM public.transactions t
      JOIN public.wallets w ON t.wallet_id = w.id
      JOIN public.profiles p ON w.user_id = p.id
      LEFT JOIN public.bank_accounts b ON (b.creator_id = p.id AND b.is_primary = true)
      ORDER BY t.created_at DESC
      LIMIT 100
    `;
    const result = await query(sql);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 11. GET /api/admin/payouts/banks - Fetch live Nigerian banks list
router.get('/payouts/banks', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const banks = await getNigerianBanksList();
    res.json({ success: true, banks });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 12. POST /api/admin/payouts/resolve-bank - Resolve Nigerian NUBAN account name
router.post('/payouts/resolve-bank', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { account_number, bank_code } = z.object({
      account_number: z.string().length(10),
      bank_code: z.string()
    }).parse(req.body);

    const resolved = await resolveBankAccount(account_number, bank_code);
    if (!resolved) {
      return res.status(400).json({ success: false, message: 'Could not resolve account name. Check details.' });
    }

    res.json({ success: true, data: resolved });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// 13. POST /api/admin/payouts/:id/disburse - Execute live Paystack NIP transfer
router.post('/payouts/:id/disburse', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;

    const txRes = await query(`
      SELECT t.*, w.user_id, p.full_name,
             b.bank_code, b.bank_name, b.account_number, b.account_name, b.paystack_recipient_code
      FROM public.transactions t
      JOIN public.wallets w ON t.wallet_id = w.id
      JOIN public.profiles p ON w.user_id = p.id
      LEFT JOIN public.bank_accounts b ON (b.creator_id = p.id AND b.is_primary = true)
      WHERE t.id = $1 AND t.type = 'withdrawal' AND t.status = 'pending'
    `, [id]);

    if (txRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pending withdrawal transaction not found' });
    }

    const tx = txRes.rows[0];

    // Verify creator has a valid bank account
    if (!tx.account_number || !tx.bank_code) {
      return res.status(400).json({ success: false, message: 'Creator has no primary bank account attached' });
    }

    let recipientCode = tx.paystack_recipient_code;
    if (!recipientCode) {
      recipientCode = await createTransferRecipient(tx.account_name || tx.full_name, tx.account_number, tx.bank_code);
      if (recipientCode) {
        await query('UPDATE public.bank_accounts SET paystack_recipient_code = $1 WHERE creator_id = $2', [recipientCode, tx.user_id]);
      }
    }

    if (!recipientCode) {
      // If Paystack secret is not active yet, mark as manual completion
      await query("UPDATE public.transactions SET status = 'completed' WHERE id = $1", [id]);
      return res.json({ success: true, message: 'Marked as completed manually (Paystack live credentials pending).' });
    }

    // Initiate automated transfer
    const transferResult = await initiatePaystackTransfer(Number(tx.amount), recipientCode, `Viraly Creator Cashout: ${tx.reference}`);

    await query(
      `UPDATE public.transactions 
       SET status = 'completed', paystack_transfer_code = $1 
       WHERE id = $2`,
      [transferResult.data?.transfer_code || 'manual', id]
    );

    res.json({ success: true, message: `₦${Number(tx.amount).toLocaleString()} disbursed successfully to ${tx.full_name}`, data: transferResult });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 14. GET /api/admin/clicks - Live click audit log
router.get('/clicks', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const sql = `
      SELECT cl.*, r.slug, r.target_url, c.title AS campaign_title, p.full_name AS creator_name
      FROM public.clicks cl
      JOIN public.referral_links r ON cl.referral_link_id = r.id
      JOIN public.campaigns c ON r.campaign_id = c.id
      JOIN public.profiles p ON r.creator_id = p.id
      ORDER BY cl.created_at DESC
      LIMIT 100
    `;
    const result = await query(sql);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
