import cron from 'node-cron';
import { query } from '../config/db.js';

export function startBackgroundWorker() {
  console.log('[Worker] Starting Viraly view auditor & budget cap scheduler...');

  // Run every 30 minutes
  cron.schedule('*/30 * * * *', async () => {
    try {
      console.log('[Worker] Auditing active campaign pools and submissions...');

      // 1. Fetch active campaigns
      const activeCampaigns = await query(
        "SELECT id, total_budget, remaining_budget, cpm_rate, view_cap, current_views FROM public.campaigns WHERE status = 'active'"
      );

      for (const campaign of activeCampaigns.rows) {
        // Fetch tracking submissions for this campaign
        const submissions = await query(
          "SELECT id, creator_id, current_views, view_earnings, total_earnings FROM public.submissions WHERE campaign_id = $1 AND status = 'tracking'",
          [campaign.id]
        );

        let totalCampaignViews = 0;
        let totalPaidOut = 0;

        for (const sub of submissions.rows) {
          totalCampaignViews += Number(sub.current_views || 0);
          totalPaidOut += Number(sub.total_earnings || 0);
        }

        const remainingBudget = Math.max(0, Number(campaign.total_budget) - totalPaidOut);

        // Check if campaign reached its view cap or budget cap
        if (
          (campaign.view_cap && totalCampaignViews >= Number(campaign.view_cap)) ||
          remainingBudget <= 0
        ) {
          console.log(`[Worker] Campaign ${campaign.id} reached view/budget cap. Marking as completed.`);
          await query(
            "UPDATE public.campaigns SET status = 'completed', remaining_budget = $1, current_views = $2, updated_at = NOW() WHERE id = $3",
            [remainingBudget, totalCampaignViews, campaign.id]
          );

          await query(
            "UPDATE public.submissions SET status = 'capped', updated_at = NOW() WHERE campaign_id = $1 AND status = 'tracking'",
            [campaign.id]
          );
        } else {
          // Update live progress
          await query(
            "UPDATE public.campaigns SET current_views = $1, remaining_budget = $2, updated_at = NOW() WHERE id = $3",
            [totalCampaignViews, remainingBudget, campaign.id]
          );
        }
      }

      console.log('[Worker] Audit cycle complete.');
    } catch (error) {
      console.error('[Worker] Error during audit cycle:', error);
    }
  });
}
