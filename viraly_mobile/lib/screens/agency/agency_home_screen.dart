import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/campaign.dart';
import '../../services/supabase_service.dart';
import 'create_campaign_screen.dart';

class AgencyHomeScreen extends StatefulWidget {
  final UserProfile? profile;

  const AgencyHomeScreen({super.key, this.profile});

  @override
  State<AgencyHomeScreen> createState() => _AgencyHomeScreenState();
}

class _AgencyHomeScreenState extends State<AgencyHomeScreen> {
  final currencyFormatter = NumberFormat('#,##0', 'en_US');
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  void _loadCampaigns() {
    final agencyId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    if (agencyId != null) {
      _campaignsFuture = SupabaseService.fetchAgencyCampaigns(agencyId);
    } else {
      _campaignsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandName = widget.profile?.fullName ?? 'Brand';

    return Scaffold(
      backgroundColor: ViralyTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadCampaigns();
            });
          },
          color: ViralyTheme.indigo,
          backgroundColor: ViralyTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Brand Command Center',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ViralyTheme.indigo),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle, color: ViralyTheme.indigo, size: 26),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateCampaignScreen(profile: widget.profile),
                          ),
                        ).then((_) => _loadCampaigns());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Aggregates FutureBuilder
                FutureBuilder<List<Campaign>>(
                  future: _campaignsFuture,
                  builder: (context, snapshot) {
                    final campaigns = snapshot.data ?? [];
                    final totalViews = campaigns.fold<int>(0, (sum, c) => sum + c.currentViews);
                    final totalEscrowRemaining = campaigns.fold<double>(0.0, (sum, c) => sum + c.remainingBudget);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metric Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: ViralyTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: ViralyTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TOTAL VIEWS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
                                    const SizedBox(height: 6),
                                    Text(
                                      currencyFormatter.format(totalViews),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Verified reach', style: TextStyle(fontSize: 10, color: ViralyTheme.emerald)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: ViralyTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: ViralyTheme.indigo.withAlpha(80)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ESCROW POOL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₦${currencyFormatter.format(totalEscrowRemaining)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ViralyTheme.indigo),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Prepaid fuel', style: TextStyle(fontSize: 10, color: ViralyTheme.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Launch Campaign CTA
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateCampaignScreen(profile: widget.profile),
                                ),
                              ).then((_) => _loadCampaigns());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ViralyTheme.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.plus, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Launch New Brand Campaign',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Active Campaigns List
                        const Text(
                          'YOUR CAMPAIGNS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
                        ),
                        const SizedBox(height: 12),

                        if (campaigns.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: ViralyTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ViralyTheme.border),
                            ),
                            child: Column(
                              children: [
                                const Icon(LucideIcons.rocket, size: 36, color: ViralyTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Campaigns Launched Yet',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Click the button above to fund an escrow pool and mobilize creators.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: campaigns.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final camp = campaigns[index];
                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: ViralyTheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: ViralyTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          camp.title,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: ViralyTheme.emerald.withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            camp.status.toUpperCase(),
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.emerald),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Escrow: ₦${currencyFormatter.format(camp.remainingBudget)} / ₦${currencyFormatter.format(camp.totalBudget)} left',
                                      style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (camp.remainingBudget / (camp.totalBudget > 0 ? camp.totalBudget : 1)).clamp(0.0, 1.0),
                                        backgroundColor: ViralyTheme.surfaceElevated,
                                        valueColor: const AlwaysStoppedAnimation<Color>(ViralyTheme.indigo),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
