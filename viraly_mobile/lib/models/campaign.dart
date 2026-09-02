class Campaign {
  final String id;
  final String agencyId;
  final String title;
  final String description;
  final String category;
  final String objective;
  final String status;
  final double totalBudget;
  final double remainingBudget;
  final double cpmRate;
  final double cpcRate;
  final double? maxPayoutPerCreator;
  final int? viewCap;
  final int currentViews;
  final int? clickCap;
  final int currentClicks;
  final String? targetDestinationUrl;
  final List<String> requiredHashtags;
  final List<String> requiredMentions;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.agencyId,
    required this.title,
    required this.description,
    required this.category,
    required this.objective,
    required this.status,
    required this.totalBudget,
    required this.remainingBudget,
    required this.cpmRate,
    required this.cpcRate,
    this.maxPayoutPerCreator,
    this.viewCap,
    required this.currentViews,
    this.clickCap,
    required this.currentClicks,
    this.targetDestinationUrl,
    required this.requiredHashtags,
    required this.requiredMentions,
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      title: json['title'] as String? ?? 'Untitled Campaign',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Apps & Tech',
      objective: json['objective'] as String? ?? 'hybrid',
      status: json['status'] as String? ?? 'draft',
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      remainingBudget: (json['remaining_budget'] as num?)?.toDouble() ?? 0.0,
      cpmRate: (json['cpm_rate'] as num?)?.toDouble() ?? 0.0,
      cpcRate: (json['cpc_rate'] as num?)?.toDouble() ?? 0.0,
      maxPayoutPerCreator: (json['max_payout_per_creator'] as num?)?.toDouble(),
      viewCap: json['view_cap'] as int?,
      currentViews: (json['current_views'] as num?)?.toInt() ?? 0,
      clickCap: json['click_cap'] as int?,
      currentClicks: (json['current_clicks'] as num?)?.toInt() ?? 0,
      targetDestinationUrl: json['target_destination_url'] as String?,
      requiredHashtags: (json['required_hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      requiredMentions: (json['required_mentions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  int get budgetProgressPercentage {
    if (totalBudget <= 0) return 0;
    final consumed = totalBudget - remainingBudget;
    return ((consumed / totalBudget) * 100).clamp(0, 100).toInt();
  }
}

class CampaignAsset {
  final String id;
  final String campaignId;
  final String assetType;
  final String title;
  final String contentOrUrl;

  CampaignAsset({
    required this.id,
    required this.campaignId,
    required this.assetType,
    required this.title,
    required this.contentOrUrl,
  });

  factory CampaignAsset.fromJson(Map<String, dynamic> json) {
    return CampaignAsset(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      assetType: json['asset_type'] as String? ?? 'hook_script',
      title: json['title'] as String? ?? 'Hook Angle',
      contentOrUrl: json['content_or_url'] as String? ?? '',
    );
  }
}
