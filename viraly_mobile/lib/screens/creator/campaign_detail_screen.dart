import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/campaign.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  final UserProfile? profile;

  const CampaignDetailScreen({
    super.key,
    required this.campaign,
    this.profile,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final currencyFormatter = NumberFormat('#,##0', 'en_US');
  final _tiktokUrlController = TextEditingController();

  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;
  String? _referralSlug;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _referralSlug = 'c-${widget.profile!.id.substring(0, 5)}-${widget.campaign.id.substring(0, 5)}';
    }
  }

  @override
  void dispose() {
    _tiktokUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitVideo() async {
    final url = _tiktokUrlController.text.trim();
    if (url.isEmpty || !url.contains('tiktok.com')) {
      setState(() => _errorMessage = 'Please enter a valid TikTok video URL.');
      return;
    }

    final userId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'Please sign in to submit your video.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await SupabaseService.submitVideo(
        campaignId: widget.campaign.id,
        creatorId: userId,
        tiktokUrl: url,
      );

      setState(() {
        _successMessage = '🎉 Video submitted! Our AI auditor will review and begin live view tracking.';
        _tiktokUrlController.clear();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error submitting video: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;

    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CAMPAIGN HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ViralyTheme.indigo.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          campaign.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ViralyTheme.indigo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '₦${currencyFormatter.format(campaign.remainingBudget)} escrow left',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ViralyTheme.emerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    campaign.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.description,
                    style: TextStyle(fontSize: 13, color: ViralyTheme.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 16),

                  // Rates Grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ViralyTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricPill('CPM RATE', '₦${currencyFormatter.format(campaign.cpmRate)} / 10k', ViralyTheme.emerald),
                        Container(width: 1, height: 30, color: ViralyTheme.border),
                        _buildMetricPill('CPC RATE', '₦${currencyFormatter.format(campaign.cpcRate)} / click', ViralyTheme.teal),
                        if (campaign.maxPayoutPerCreator != null) ...[
                          Container(width: 1, height: 30, color: ViralyTheme.border),
                          _buildMetricPill('MAX CAP', '₦${currencyFormatter.format(campaign.maxPayoutPerCreator)}', Colors.white),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. YOUR UNIQUE SMART SHORTLINK (If CPC enabled)
            if (campaign.targetDestinationUrl != null && _referralSlug != null) ...[
              const Text(
                'YOUR BIO LINK (EARN PER CLICK)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ViralyTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ViralyTheme.teal.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.link, size: 18, color: ViralyTheme.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'viraly.ng/r/$_referralSlug',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 16, color: ViralyTheme.teal),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'https://iswitch-l82a.onrender.com/r/$_referralSlug'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Referral link copied to clipboard!'),
                            backgroundColor: ViralyTheme.surfaceElevated,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3. VIRAL PLAYBOOK & HOOKS
            const Text(
              'CREATIVE PLAYBOOK & HOOKS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
            ),
            const SizedBox(height: 10),
            _buildHookCard(
              'Hook Angle 1: "The House Hunt Dilemma"',
              '“If you are still paying 100k agency fee for house in Lagos, you need to watch this right now…”',
            ),
            const SizedBox(height: 10),
            _buildHookCard(
              'Hook Angle 2: "POV / Reality Check"',
              '“POV: Finding a clean 1-bedroom in Yaba with 0 landlord drama using Rentilly.”',
            ),

            const SizedBox(height: 28),

            // 4. SUBMIT YOUR TIKTOK VIDEO
            const Text(
              'SUBMIT YOUR PUBLISHED VIDEO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
            ),
            const SizedBox(height: 10),

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ViralyTheme.emerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ViralyTheme.emerald.withAlpha(80)),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: ViralyTheme.emerald, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ViralyTheme.rose.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ViralyTheme.rose.withAlpha(80)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: ViralyTheme.rose, fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
            ],

            Container(
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: TextField(
                controller: _tiktokUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://www.tiktok.com/@yourname/video/728...',
                  hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(LucideIcons.video, color: ViralyTheme.textMuted, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViralyTheme.emerald,
                  foregroundColor: const Color(0xFF07090E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07090E)),
                      )
                    : const Text(
                        'Submit Video for Live Tracking',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildHookCard(String title, String quote) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ViralyTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ViralyTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(quote, style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
