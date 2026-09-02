import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';
import { z } from 'zod';

const router = Router();

// GET /api/profiles/me - Get current user profile and wallet
router.get('/me', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const result = await query(
      `SELECT p.*, w.available_balance, w.pending_balance, w.currency
       FROM public.profiles p
       LEFT JOIN public.wallets w ON w.user_id = p.id
       WHERE p.id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }

    res.json({ success: true, profile: result.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// PATCH /api/profiles/me - Update profile (TikTok handle, phone number, full name, avatar)
const updateProfileSchema = z.object({
  full_name: z.string().min(2).optional(),
  phone_number: z.string().optional(),
  tiktok_handle: z.string().optional(),
  avatar_url: z.string().url().optional(),
  bio: z.string().optional()
});

router.patch('/me', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const body = updateProfileSchema.parse(req.body);

    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (body.full_name !== undefined) {
      fields.push(`full_name = $${idx++}`);
      values.push(body.full_name);
    }
    if (body.phone_number !== undefined) {
      fields.push(`phone_number = $${idx++}`);
      values.push(body.phone_number);
    }
    if (body.tiktok_handle !== undefined) {
      // Strip @ if provided
      const cleanHandle = body.tiktok_handle.replace(/^@/, '').trim();
      fields.push(`tiktok_handle = $${idx++}`);
      values.push(cleanHandle);
    }
    if (body.avatar_url !== undefined) {
      fields.push(`avatar_url = $${idx++}`);
      values.push(body.avatar_url);
    }
    if (body.bio !== undefined) {
      fields.push(`bio = $${idx++}`);
      values.push(body.bio);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided for update' });
    }

    fields.push(`updated_at = NOW()`);
    values.push(userId);

    const sql = `UPDATE public.profiles SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const result = await query(sql, values);

    res.json({ success: true, message: 'Profile updated successfully', profile: result.rows[0] });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

export default router;
