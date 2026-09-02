import cron from 'node-cron';
import { query } from '../config/db.js';
import { fetchLiveTikTokMetrics } from './tiktok.js';

export function startBackgroundWorker() {
  console.log('[Worker] Viraly live view auditor & budget cap worker initialized.');

  // Run audit every 15 minutes
  cron.schedule('*/15 * * * *', async () => {
    try {
      console.log('[Worker] Starting live TikTok view audit cycle...');

      // 1. Fetch all active submissions in tracking state
      const trackingSubs = await query(`
        SELECT s.id, s.campaign_id, s.creator_id, s.tiktok_video_url, s.current_views, 
               s.view_earnings, s.total_earnings,
               c.cpm_rate, c.remaining_budget, c.total_budget, c.view_cap, c.max_payout_per_creator,
               c.status as campaign_status
        FROM public.submissions s
        JOIN public.campaigns c ON s.campaign_id = c.id
        WHERE s.status = 'tracking' AND c.status = 'active'
      `);

      for (const sub of trackingSubs.rows) {
        try {
          const metrics = await fetchLiveTikTokMetrics(sub.tiktok_video_url);
          if (!metrics || metrics.views <= Number(sub.current_views)) {
            continue; // No new views recorded
          }

          const newViews = metrics.views;
          const deltaViews = newViews - Number(sub.current_views);
          const cpmRate = Number(sub.cpm_rate || 0);

          // Calculate payout for new views: e.g. ₦1,500 per 10,000 views
          let payoutAdded = (deltaViews / 10000) * cpmRate;

          // Check creator cap
          if (sub.max_payout_per_creator) {
            const maxCap = Number(sub.max_payout_per_creator);
            const currentTotal = Number(sub.total_earnings);
            if (currentTotal + payoutAdded > maxCap) {
              payoutAdded = Math.max(0, maxCap - currentTotal);
            }
          }

          // Check campaign remaining budget
          const remainingBudget = Number(sub.remaining_budget);
          if (payoutAdded > remainingBudget) {
            payoutAdded = remainingBudget;
          }

          // 1. Update submission metrics and earnings
          await query(`
            UPDATE public.submissions 
            SET current_views = $1,
                likes_count = $2,
                comments_count = $3,
                view_earnings = view_earnings + $4,
                total_earnings = total_earnings + $4,
                last_audited_at = NOW(),
                updated_at = NOW()
            WHERE id = $5
          `, [newViews, metrics.likes, metrics.comments, payoutAdded, sub.id]);

          // 2. Credit creator's live wallet if payout was generated
          if (payoutAdded > 0) {
            await query(`
              UPDATE public.wallets 
              SET available_balance = available_balance + $1,
                  updated_at = NOW()
              WHERE user_id = $2
            `, [payoutAdded, sub.creator_id]);

            // 3. Deduct from campaign remaining budget and add to campaign total views
            await query(`
              UPDATE public.campaigns 
              SET current_views = current_views + $1,
                  remaining_budget = GREATEST(0, remaining_budget - $2),
                  updated_at = NOW()
              WHERE id = $3
            `, [deltaViews, payoutAdded, sub.campaign_id]);

            // 4. Log view audit trail
            await query(`
              INSERT INTO public.view_audit_logs (submission_id, recorded_views, delta_views, payout_added)
              VALUES ($1, $2, $3, $4)
            `, [sub.id, newViews, deltaViews, payoutAdded]);

            console.log(`[Worker] Credited ₦${payoutAdded.toFixed(2)} to creator for +${deltaViews} views on video ${metrics.videoId}`);
          }

          // 5. Check if campaign pool is now exhausted
          const checkCamp = await query('SELECT remaining_budget, view_cap, current_views FROM public.campaigns WHERE id = $1', [sub.campaign_id]);
          const cData = checkCamp.rows[0];
          if (cData && (Number(cData.remaining_budget) <= 0 || (cData.view_cap && Number(cData.current_views) >= Number(cData.view_cap)))) {
            console.log(`[Worker] Campaign ${sub.campaign_id} has reached its view or budget cap. Freezing campaign.`);
            await query("UPDATE public.campaigns SET status = 'completed', updated_at = NOW() WHERE id = $1", [sub.campaign_id]);
            await query("UPDATE public.submissions SET status = 'capped', updated_at = NOW() WHERE campaign_id = $1 AND status = 'tracking'", [sub.campaign_id]);
          }

        } catch (subErr) {
          console.error(`[Worker] Error auditing submission ${sub.id}:`, subErr);
        }
      }

      console.log('[Worker] Live audit cycle finished.');
    } catch (error) {
      console.error('[Worker] Fatal error in view auditor cycle:', error);
    }
  });
}
