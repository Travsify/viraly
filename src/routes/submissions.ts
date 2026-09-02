import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';
import { verifyTikTokVideo, extractTikTokVideoId } from '../services/tiktok.js';
import { z } from 'zod';

const router = Router();

// POST /api/submissions - Creator submits a video for a campaign
const submitVideoSchema = z.object({
  campaign_id: z.string().uuid(),
  tiktok_video_url: z.string().url()
});

router.post('/', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const creatorId = req.user!.id;
    const { campaign_id, tiktok_video_url } = submitVideoSchema.parse(req.body);

    // 1. Verify campaign is active
    const campaignRes = await query(
      `SELECT id, status, remaining_budget, target_destination_url FROM public.campaigns WHERE id = $1`,
      [campaign_id]
    );

    if (campaignRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }

    const campaign = campaignRes.rows[0];
    if (campaign.status !== 'active' || Number(campaign.remaining_budget) <= 0) {
      return res.status(400).json({ success: false, message: 'Campaign is no longer active or budget cap is reached.' });
    }

    // 2. Validate TikTok URL & extract video metadata
    const tiktokMeta = await verifyTikTokVideo(tiktok_video_url);
    const videoId = tiktokMeta?.videoId || extractTikTokVideoId(tiktok_video_url) || Date.now().toString();

    // 3. Check for duplicate video submission
    const existingSub = await query(
      `SELECT id FROM public.submissions WHERE campaign_id = $1 AND tiktok_video_id = $2`,
      [campaign_id, videoId]
    );

    if (existingSub.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'This video has already been submitted for this campaign.' });
    }

    // 4. Create submission record
    const subRes = await query(
      `INSERT INTO public.submissions (
        campaign_id, creator_id, tiktok_video_url, tiktok_video_id, status
      ) VALUES ($1, $2, $3, $4, 'pending_review')
      RETURNING *`,
      [campaign_id, creatorId, tiktok_video_url, videoId]
    );

    // 5. Automatically create a custom referral shortlink for this creator on this campaign
    let referralSlug = `c-${creatorId.substring(0, 5)}-${campaign_id.substring(0, 5)}`;
    if (campaign.target_destination_url) {
      await query(
        `INSERT INTO public.referral_links (campaign_id, creator_id, slug, target_url)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (campaign_id, creator_id) DO NOTHING`,
        [campaign_id, creatorId, referralSlug, campaign.target_destination_url]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Video submitted successfully! Currently under review.',
      data: subRes.rows[0],
      referralLink: `/r/${referralSlug}`
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// GET /api/submissions/my - Creator views their submissions & live view earnings
router.get('/my', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const creatorId = req.user!.id;
    const result = await query(
      `SELECT s.*, c.title as campaign_title, c.cpm_rate, c.cpc_rate, r.slug as referral_slug, r.qualified_clicks
       FROM public.submissions s
       JOIN public.campaigns c ON s.campaign_id = c.id
       LEFT JOIN public.referral_links r ON (r.campaign_id = s.campaign_id AND r.creator_id = s.creator_id)
       WHERE s.creator_id = $1
       ORDER BY s.created_at DESC`,
      [creatorId]
    );

    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// PATCH /api/submissions/:id/review - Agency/Admin approves or rejects submission
router.patch('/:id/review', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status, rejection_reason } = req.body;

    if (!['tracking', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Status must be tracking or rejected' });
    }

    const updated = await query(
      `UPDATE public.submissions 
       SET status = $1, rejection_reason = $2, updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [status, rejection_reason || null, id]
    );

    if (updated.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Submission not found' });
    }

    res.json({ success: true, message: `Submission marked as ${status}`, data: updated.rows[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
