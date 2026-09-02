import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/submission.dart';
import '../../services/supabase_service.dart';

class MySubmissionsScreen extends StatefulWidget {
  final UserProfile? profile;

  const MySubmissionsScreen({super.key, this.profile});

  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  final currencyFormatter = NumberFormat('#,##0', 'en_US');
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    final userId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    if (userId != null) {
      _submissionsFuture = SupabaseService.fetchMySubmissions(userId);
    } else {
      _submissionsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('My Video Submissions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadSubmissions();
          });
        },
        color: ViralyTheme.emerald,
        backgroundColor: ViralyTheme.surface,
        child: FutureBuilder<List<Submission>>(
          future: _submissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
                ),
              );
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: ViralyTheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.video, size: 40, color: ViralyTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Submissions Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Go to the Gigs tab, select an active campaign, and submit your TikTok video URL.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: ViralyTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final sub = list[index];
                return _buildSubmissionCard(sub);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Submission sub) {
    Color statusColor;
    String statusLabel;

    switch (sub.status) {
      case 'tracking':
        statusColor = ViralyTheme.emerald;
        statusLabel = 'LIVE TRACKING';
        break;
      case 'pending_review':
        statusColor = ViralyTheme.amber;
        statusLabel = 'PENDING REVIEW';
        break;
      case 'capped':
        statusColor = ViralyTheme.indigo;
        statusLabel = 'BUDGET CAPPED';
        break;
      default:
        statusColor = ViralyTheme.rose;
        statusLabel = 'REJECTED';
    }

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
                sub.campaignTitle ?? 'Brand Campaign',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ViralyTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LIVE VIEWS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(sub.currentViews),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ViralyTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EARNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '₦${currencyFormatter.format(sub.totalEarnings)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ViralyTheme.emerald),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(sub.tiktokVideoUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                const Icon(LucideIcons.video, size: 14, color: ViralyTheme.indigo),
                const SizedBox(width: 6),
                Text(
                  'Watch Video on TikTok ↗',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.indigo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
