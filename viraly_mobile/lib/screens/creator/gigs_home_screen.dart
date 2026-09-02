import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/campaign.dart';
import '../../models/wallet.dart';
import '../../services/supabase_service.dart';
import 'campaign_detail_screen.dart';

class GigsHomeScreen extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback onNavigateToWallet;

  const GigsHomeScreen({
    super.key,
    this.profile,
    required this.onNavigateToWallet,
  });

  @override
  State<GigsHomeScreen> createState() => _GigsHomeScreenState();
}

class _GigsHomeScreenState extends State<GigsHomeScreen> {
  final currencyFormatter = NumberFormat('#,##0', 'en_US');
  String _selectedCategory = 'All';
  late Future<List<Campaign>> _campaignsFuture;
  late Future<Wallet> _walletFuture;

  final List<String> _categories = [
    'All',
    'Apps & Tech',
    'Fintech',
    'Real Estate',
    'Food & Delivery',
    'Lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _campaignsFuture = SupabaseService.fetchActiveCampaigns(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (widget.profile != null) {
      _walletFuture = SupabaseService.fetchWallet(widget.profile!.id);
    } else if (SupabaseService.currentUser != null) {
      _walletFuture = SupabaseService.fetchWallet(SupabaseService.currentUser!.id);
    } else {
      _walletFuture = Future.value(Wallet(id: '', userId: '', availableBalance: 0.0, pendingBalance: 0.0, currency: 'NGN'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final creatorName = widget.profile?.fullName.split(' ').first ?? 'Creator';

    return Scaffold(
      backgroundColor: ViralyTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadData();
            });
          },
          color: ViralyTheme.emerald,
          backgroundColor: ViralyTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER (Neo-Dark Style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: ViralyTheme.emerald, width: 2),
                            image: widget.profile?.avatarUrl != null
                                ? DecorationImage(image: NetworkImage(widget.profile!.avatarUrl!))
                                : null,
                            color: ViralyTheme.surfaceElevated,
                          ),
                          child: widget.profile?.avatarUrl == null
                              ? const Center(
                                  child: Icon(LucideIcons.user, color: ViralyTheme.emerald, size: 22),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hi $creatorName 👋',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCD7F32).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.award, size: 10, color: Color(0xFFCD7F32)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Bronze Creator',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFCD7F32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Notification Bell
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ViralyTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: ViralyTheme.border),
                      ),
                      child: const Icon(LucideIcons.bell, size: 18, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. GLOWING WALLET BALANCE CARD (Option 1 Design)
                FutureBuilder<Wallet>(
                  future: _walletFuture,
                  builder: (context, snapshot) {
                    final balance = snapshot.data?.availableBalance ?? 0.0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ViralyTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ViralyTheme.emerald.withAlpha(90), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: ViralyTheme.emerald.withAlpha(35),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Viraly Wallet Balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ViralyTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${currencyFormatter.format(balance)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: ViralyTheme.emerald,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Available to withdraw',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ViralyTheme.textMuted,
                                ),
                              ),
                            ],
                          ),

                          // Withdraw CTA
                          ElevatedButton(
                            onPressed: widget.onNavigateToWallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ViralyTheme.indigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Withdraw to OPay',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. CATEGORY FILTER PILLS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _loadData();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? ViralyTheme.emerald.withAlpha(25) : ViralyTheme.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? ViralyTheme.emerald : ViralyTheme.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? ViralyTheme.emerald : ViralyTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. ACTIVE CAMPAIGN BOUNTY CARDS (100% Live from Supabase)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE BOUNTIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: ViralyTheme.textMuted,
                      ),
                    ),
                    Text(
                      'Live Supabase Sync',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ViralyTheme.emerald.withAlpha(180),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                FutureBuilder<List<Campaign>>(
                  future: _campaignsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
                          ),
                        ),
                      );
                    }

                    final campaigns = snapshot.data ?? [];

                    if (campaigns.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: ViralyTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ViralyTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.sparkles, size: 36, color: ViralyTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No Active Gigs in this Category',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check back shortly or launch a new campaign from the Admin Portal.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: ViralyTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: campaigns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final campaign = campaigns[index];
                        return _buildCampaignCard(campaign);
                      },
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

  Widget _buildCampaignCard(Campaign campaign) {
    final progress = campaign.budgetProgressPercentage;

    return Container(
      decoration: BoxDecoration(
        color: ViralyTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ViralyTheme.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ViralyTheme.indigo.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ViralyTheme.indigo.withAlpha(80)),
                    ),
                    child: Center(
                      child: Text(
                        campaign.title.isNotEmpty ? campaign.title.substring(0, 1).toUpperCase() : 'B',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        campaign.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ViralyTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ViralyTheme.emerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTIVE POOL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: ViralyTheme.emerald,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payout Rate Badge (e.g. ₦1,500 per 10k views + ₦30/click)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ViralyTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ViralyTheme.emerald.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.trendingUp, size: 14, color: ViralyTheme.emerald),
                const SizedBox(width: 8),
                Text(
                  '₦${currencyFormatter.format(campaign.cpmRate)} per 10k views',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ViralyTheme.emerald,
                  ),
                ),
                if (campaign.cpcRate > 0) ...[
                  Text(
                    ' + ₦${currencyFormatter.format(campaign.cpcRate)}/click',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ViralyTheme.teal,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Escrow Pool Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₦${currencyFormatter.format(campaign.remainingBudget)} / ₦${currencyFormatter.format(campaign.totalBudget)} pool left',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${100 - progress}% Available',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ViralyTheme.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (campaign.remainingBudget / (campaign.totalBudget > 0 ? campaign.totalBudget : 1.0)).clamp(0.0, 1.0),
                  backgroundColor: ViralyTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Creator Cap & CTA Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earn based on performance',
                    style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted),
                  ),
                  if (campaign.maxPayoutPerCreator != null) ...[
                    Text(
                      'Max ₦${currencyFormatter.format(campaign.maxPayoutPerCreator)}/creator',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),

              // Accept Gig Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CampaignDetailScreen(
                        campaign: campaign,
                        profile: widget.profile,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViralyTheme.emerald,
                  foregroundColor: const Color(0xFF07090E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Accept Gig',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
