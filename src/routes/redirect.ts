import { Router, Request, Response } from 'express';
import { query } from '../config/db.js';
import { hashIp, evaluateClickLegitimacy } from '../services/fraud.js';

const router = Router();

router.get('/r/:slug', async (req: Request, res: Response) => {
  const { slug } = req.params;

  try {
    // 1. Look up the referral link and associated campaign
    const linkRes = await query(
      `SELECT r.id AS link_id, r.target_url, r.campaign_id, r.creator_id,
              c.status AS campaign_status, c.cpc_rate, c.remaining_budget, c.click_cap, c.current_clicks
       FROM public.referral_links r
       JOIN public.campaigns c ON r.campaign_id = c.id
       WHERE r.slug = $1`,
      [slug]
    );

    if (linkRes.rows.length === 0) {
      return res.status(404).send('Link not found or has expired.');
    }

    const link = linkRes.rows[0];
    const destinationUrl = link.target_url;

    // 2. Anti-fraud extraction
    const rawIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0].trim() || req.socket.remoteAddress || '127.0.0.1';
    const userAgent = req.headers['user-agent'] || '';
    const ipHash = hashIp(rawIp);

    const fraudCheck = evaluateClickLegitimacy(ipHash, userAgent);

    // 3. Deduplication check: Has this IP clicked this link in the last 24 hours?
    const recentClick = await query(
      `SELECT id FROM public.clicks 
       WHERE referral_link_id = $1 AND ip_hash = $2 AND created_at > NOW() - INTERVAL '24 hours'`,
      [link.link_id, ipHash]
    );

    const isDuplicate = recentClick.rows.length > 0;
    const isCampaignActive = link.campaign_status === 'active' && Number(link.remaining_budget) > 0;
    const isQualified = fraudCheck.isQualified && !isDuplicate && isCampaignActive;
    const rejectionReason = isDuplicate ? 'Duplicate IP within 24h' : fraudCheck.reason;

    // 4. Log the click record
    await query(
      `INSERT INTO public.clicks (referral_link_id, ip_hash, user_agent, country_code, is_qualified, rejection_reason)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [link.link_id, ipHash, userAgent.substring(0, 255), 'NG', isQualified, rejectionReason]
    );

    // 5. Update click counts and credit earnings if qualified
    await query(
      `UPDATE public.referral_links 
       SET total_clicks = total_clicks + 1,
           qualified_clicks = qualified_clicks + CASE WHEN $1::boolean THEN 1 ELSE 0 END
       WHERE id = $2`,
      [isQualified, link.link_id]
    );

    if (isQualified && Number(link.cpc_rate) > 0) {
      const cpcEarning = Number(link.cpc_rate);

      // Increment campaign current_clicks and decrement remaining_budget
      await query(
        `UPDATE public.campaigns 
         SET current_clicks = current_clicks + 1,
             remaining_budget = GREATEST(0, remaining_budget - $1),
             updated_at = NOW()
         WHERE id = $2`,
        [cpcEarning, link.campaign_id]
      );

      // Credit the creator's wallet
      await query(
        `UPDATE public.wallets 
         SET available_balance = available_balance + $1,
             updated_at = NOW()
         WHERE user_id = $2`,
        [cpcEarning, link.creator_id]
      );

      // Log transaction
      await query(
        `INSERT INTO public.transactions (wallet_id, type, amount, status, reference, description)
         SELECT id, 'click_earning', $1, 'completed', $2, 'CPC earning from referral link'
         FROM public.wallets WHERE user_id = $3`,
        [cpcEarning, `cpc_${Date.now()}_${link.link_id.substring(0, 8)}`, link.creator_id]
      );
    }

    // 6. Fast 302 Redirect to the partner's landing page or App Store
    return res.redirect(302, destinationUrl);
  } catch (error) {
    console.error('Error during referral redirection:', error);
    return res.status(500).send('Error redirecting to destination.');
  }
});

export default router;
