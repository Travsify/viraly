import { Router, Request, Response } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { PremblyService } from '../services/identitypass.js';
import { query } from '../config/db.js';

const router = Router();

// ─── POST /api/kyc/verify-bvn ─────────────────────────────────────────────
// Live verification against NIBSS using Prembly IdentityPass
router.post('/verify-bvn', requireAuth, async (req: Request, res: Response) => {
  try {
    const { bvn, nin } = req.body as { bvn: string; nin?: string };
    const userId = (req as any).user?.id;

    if (!bvn || bvn.trim().length !== 11 || !/^\d{11}$/.test(bvn.trim())) {
      return res.status(400).json({ error: 'Please provide a valid 11-digit BVN.' });
    }

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized user.' });
    }

    console.log(`[KYC] Verifying BVN for user ${userId} via Prembly IdentityPass...`);

    // 1. Call Prembly Live NIBSS API
    const result = await PremblyService.verifyBVN(bvn.trim());

    if (!result.status || !result.data) {
      return res.status(422).json({
        error: result.message || 'BVN verification failed with NIBSS. Please check your BVN number and try again.',
      });
    }

    const verifiedName = result.data.fullName;
    const bvnLast4 = bvn.trim().slice(-4);
    const ninLast4 = nin && nin.trim().length === 11 ? nin.trim().slice(-4) : null;

    // 2. Persist verified status in Supabase database
    await query(
      `UPDATE public.profiles 
       SET bvn_verified = true, 
           bvn_last4 = $1, 
           nin_last4 = COALESCE($2, nin_last4),
           kyc_verified_name = $3,
           updated_at = NOW() 
       WHERE id = $4`,
      [bvnLast4, ninLast4, verifiedName, userId]
    );

    console.log(`[KYC] User ${userId} successfully verified as "${verifiedName}" (BVN *${bvnLast4})`);

    return res.json({
      success: true,
      message: 'BVN verified successfully with NIBSS.',
      verified_name: verifiedName,
      bvn_last4: bvnLast4,
    });
  } catch (error: any) {
    console.error('[KYC] Exception during BVN verification:', error);
    return res.status(500).json({ error: 'Internal server error during KYC verification.' });
  }
});

export default router;
