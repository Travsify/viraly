import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class TiktokViralBanner extends StatefulWidget {
  const TiktokViralBanner({super.key});

  @override
  State<TiktokViralBanner> createState() => _TiktokViralBannerState();
}

class _TiktokViralBannerState extends State<TiktokViralBanner> with SingleTickerProviderStateMixin {
  late AnimationController _discController;
  double _viewSlider = 50000; // 50k views default

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _discController.dispose();
    super.dispose();
  }

  void _openCalculatorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ViralyTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final earnings = (_viewSlider / 10000) * 1500;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ViralyTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: ViralyTheme.tiktokGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TikTok Virality Calculator',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Calculate your payout per verified view',
                          style: TextStyle(fontSize: 11, color: ViralyTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Projected Views
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ViralyTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ViralyTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated TikTok Views', style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary, fontWeight: FontWeight.w600)),
                          Text(
                            '${(_viewSlider / 1000).toStringAsFixed(0)}k Views',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ViralyTheme.tiktokCyan),
                          ),
                        ],
                      ),
                      Slider(
                        value: _viewSlider,
                        min: 10000,
                        max: 1000000,
                        divisions: 99,
                        activeColor: ViralyTheme.emerald,
                        inactiveColor: ViralyTheme.border,
                        onChanged: (val) {
                          setModalState(() => _viewSlider = val);
                          setState(() => _viewSlider = val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('10k views', style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted)),
                          Text('500k views', style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted)),
                          Text('1M+ views', style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Projected Payout Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF131A29), Color(0xFF0F1523)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: ViralyTheme.emerald.withAlpha(90), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOU GET PAID DIRECT TO YOUR BANK / OPAY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₦${earnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: ViralyTheme.emerald,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-credited to your Viraly wallet every 15 minutes as views climb',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: ViralyTheme.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(modalCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ViralyTheme.emerald,
                      foregroundColor: const Color(0xFF07090E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Start Creating & Going Viral', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ViralyTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ViralyTheme.tiktokRed.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ViralyTheme.tiktokRed.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ViralyTheme.tiktokCyan.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background subtle duotone glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ViralyTheme.tiktokRed.withAlpha(25),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with TikTok badge and spinning disc
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: ViralyTheme.tiktokGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.flame, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'TIKTOK VIRAL SURGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spinning TikTok Vinyl Disc
                    RotationTransition(
                      turns: _discController,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF11141C),
                          border: Border.all(color: ViralyTheme.tiktokCyan, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: ViralyTheme.tiktokCyan.withAlpha(70),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: ViralyTheme.tiktokRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Headline
                const Text(
                  'Post on TikTok.\nGo Viral. Get Paid.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Brands deposit cash bounties into escrow. Our automated view auditor monitors your TikTok and pays you up to ₦5,000 per 10k views.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ViralyTheme.textSecondary,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _buildStatPill('⚡ LIVE SCRAPE', '15-min audits'),
                    const SizedBox(width: 8),
                    _buildStatPill('💰 INSTANT PAY', 'NIP Bank / OPay'),
                  ],
                ),

                const SizedBox(height: 16),

                // Action button
                InkWell(
                  onTap: () => _openCalculatorModal(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ViralyTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ViralyTheme.tiktokCyan.withAlpha(90)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.calculator, size: 16, color: ViralyTheme.tiktokCyan),
                            SizedBox(width: 8),
                            Text(
                              'Calculate Your Viral TikTok Earnings',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                        Icon(LucideIcons.chevronRight, size: 16, color: ViralyTheme.tiktokCyan),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatPill(String badge, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ViralyTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ViralyTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(badge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: ViralyTheme.emerald)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
