class Submission {
  final String id;
  final String campaignId;
  final String creatorId;
  final String tiktokVideoUrl;
  final String tiktokVideoId;
  final String status;
  final String? rejectionReason;
  final int currentViews;
  final int likesCount;
  final int commentsCount;
  final double viewEarnings;
  final double clickEarnings;
  final double totalEarnings;
  final DateTime? lastAuditedAt;
  final DateTime createdAt;

  // Joined fields
  final String? campaignTitle;
  final double? cpmRate;
  final double? cpcRate;
  final String? referralSlug;
  final int? qualifiedClicks;

  Submission({
    required this.id,
    required this.campaignId,
    required this.creatorId,
    required this.tiktokVideoUrl,
    required this.tiktokVideoId,
    required this.status,
    this.rejectionReason,
    required this.currentViews,
    required this.likesCount,
    required this.commentsCount,
    required this.viewEarnings,
    required this.clickEarnings,
    required this.totalEarnings,
    this.lastAuditedAt,
    required this.createdAt,
    this.campaignTitle,
    this.cpmRate,
    this.cpcRate,
    this.referralSlug,
    this.qualifiedClicks,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      creatorId: json['creator_id'] as String,
      tiktokVideoUrl: json['tiktok_video_url'] as String? ?? '',
      tiktokVideoId: json['tiktok_video_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      rejectionReason: json['rejection_reason'] as String?,
      currentViews: (json['current_views'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      viewEarnings: (json['view_earnings'] as num?)?.toDouble() ?? 0.0,
      clickEarnings: (json['click_earnings'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      lastAuditedAt: json['last_audited_at'] != null ? DateTime.tryParse(json['last_audited_at']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      campaignTitle: json['campaign_title'] as String?,
      cpmRate: (json['cpm_rate'] as num?)?.toDouble(),
      cpcRate: (json['cpc_rate'] as num?)?.toDouble(),
      referralSlug: json['referral_slug'] as String?,
      qualifiedClicks: (json['qualified_clicks'] as num?)?.toInt(),
    );
  }
}
