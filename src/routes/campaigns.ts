import { Router, Response } from 'express';
import { query } from '../config/db.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';
import { z } from 'zod';

const router = Router();

// GET /api/campaigns - List active campaigns for creators or agencies
router.get('/', async (req, res) => {
  try {
    const { category, status } = req.query;
    let sql = `
      SELECT c.*, p.full_name as agency_name, p.avatar_url as agency_avatar,
             (SELECT COUNT(*) FROM public.submissions s WHERE s.campaign_id = c.id) as total_submissions
      FROM public.campaigns c
      JOIN public.profiles p ON c.agency_id = p.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (category) {
      params.push(category);
      sql += ` AND c.category = $${params.length}`;
    }

    if (status) {
      params.push(status);
      sql += ` AND c.status = $${params.length}`;
    } else {
      sql += ` AND c.status = 'active'`;
    }

    sql += ` ORDER BY c.created_at DESC`;

    const result = await query(sql, params);
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/campaigns/:id - Get details with assets & sample hooks
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const campaignRes = await query(
      `SELECT c.*, p.full_name as agency_name, p.avatar_url as agency_avatar
       FROM public.campaigns c
       JOIN public.profiles p ON c.agency_id = p.id
       WHERE c.id = $1`,
      [id]
    );

    if (campaignRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Campaign not found' });
    }

    const assetsRes = await query(
      `SELECT * FROM public.campaign_assets WHERE campaign_id = $1 ORDER BY created_at ASC`,
      [id]
    );

    res.json({
      success: true,
      data: {
        ...campaignRes.rows[0],
        assets: assetsRes.rows
      }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/campaigns - Create a new campaign (Auth required: Agency/Brand)
const createCampaignSchema = z.object({
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
  required_mentions: z.array(z.string()).default([]),
  assets: z.array(z.object({
    asset_type: z.string(),
    title: z.string(),
    content_or_url: z.string()
  })).default([])
});

router.post('/', requireAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const body = createCampaignSchema.parse(req.body);

    // 1. Insert campaign record
    const campaignRes = await query(
      `INSERT INTO public.campaigns (
        agency_id, title, description, category, objective, status,
        total_budget, remaining_budget, cpm_rate, cpc_rate, max_payout_per_creator,
        view_cap, click_cap, target_destination_url, required_hashtags, required_mentions
      ) VALUES ($1, $2, $3, $4, $5, 'active', $6, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        userId,
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

    const campaign = campaignRes.rows[0];

    // 2. Insert associated campaign assets (hooks, b-roll, scripts)
    if (body.assets.length > 0) {
      for (const asset of body.assets) {
        await query(
          `INSERT INTO public.campaign_assets (campaign_id, asset_type, title, content_or_url)
           VALUES ($1, $2, $3, $4)`,
          [campaign.id, asset.asset_type, asset.title, asset.content_or_url]
        );
      }
    }

    res.status(201).json({
      success: true,
      message: 'Campaign created successfully and pool is live!',
      data: campaign
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
});

export default router;
