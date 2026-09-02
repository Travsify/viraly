import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/submission.dart';
import '../../services/supabase_service.dart';

class ReviewSubmissionsScreen extends StatefulWidget {
  final UserProfile? profile;

  const ReviewSubmissionsScreen({super.key, this.profile});

  @override
  State<ReviewSubmissionsScreen> createState() => _ReviewSubmissionsScreenState();
}

class _ReviewSubmissionsScreenState extends State<ReviewSubmissionsScreen> {
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    final agencyId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    if (agencyId != null) {
      _submissionsFuture = SupabaseService.fetchAgencySubmissions(agencyId);
    } else {
      _submissionsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Submissions Approvals', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadSubmissions();
          });
        },
        color: ViralyTheme.indigo,
        backgroundColor: ViralyTheme.surface,
        child: FutureBuilder<List<Submission>>(
          future: _submissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: ViralyTheme.indigo),
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
                      const Icon(LucideIcons.checkCheck, size: 40, color: ViralyTheme.textMuted),
                      const SizedBox(height: 14),
                      const Text(
                        'All Caught Up!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No creator submissions currently pending review for your campaigns.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary),
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
                          Text(sub.campaignTitle ?? 'Campaign', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ViralyTheme.amber.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(sub.status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ViralyTheme.amber)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(sub.tiktokVideoUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(LucideIcons.playCircle, size: 16, color: ViralyTheme.indigo),
                            const SizedBox(width: 8),
                            Text('Watch Submitted TikTok Video ↗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.indigo)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (sub.status == 'pending_review') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await SupabaseService.reviewSubmission(sub.id, 'tracking');
                                  setState(() => _loadSubmissions());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ViralyTheme.emerald,
                                  foregroundColor: const Color(0xFF07090E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Approve Video', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await SupabaseService.reviewSubmission(sub.id, 'rejected', reason: 'Did not follow creative guidelines');
                                  setState(() => _loadSubmissions());
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ViralyTheme.rose,
                                  side: const BorderSide(color: ViralyTheme.rose),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
