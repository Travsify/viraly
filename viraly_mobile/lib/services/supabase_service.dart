import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campaign.dart';
import '../models/submission.dart';
import '../models/profile.dart';
import '../models/wallet.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // 1. Current Session & User
  static User? get currentUser => _client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<UserProfile?> fetchCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 2. Fetch Active Campaigns (100% Live from Supabase)
  static Future<List<Campaign>> fetchActiveCampaigns({String? category}) async {
    var query = _client.from('campaigns').select().eq('status', 'active');
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Campaign.fromJson(json)).toList();
  }

  // 3. Fetch Campaign Details & Assets
  static Future<Map<String, dynamic>> fetchCampaignWithAssets(String campaignId) async {
    final campData = await _client.from('campaigns').select().eq('id', campaignId).single();
    final assetsData = await _client.from('campaign_assets').select().eq('campaign_id', campaignId);

    return {
      'campaign': Campaign.fromJson(campData),
      'assets': (assetsData as List).map((a) => CampaignAsset.fromJson(a)).toList(),
    };
  }

  // 4. Creator Submissions
  static Future<List<Submission>> fetchMySubmissions(String creatorId) async {
    final response = await _client
        .from('submissions')
        .select('*, campaigns(title, cpm_rate, cpc_rate)')
        .eq('creator_id', creatorId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final camp = json['campaigns'] as Map<String, dynamic>?;
      return Submission.fromJson({
        ...json,
        'campaign_title': camp?['title'],
        'cpm_rate': camp?['cpm_rate'],
        'cpc_rate': camp?['cpc_rate'],
      });
    }).toList();
  }

  // 5. Submit TikTok Video Link
  static Future<Submission> submitVideo({
    required String campaignId,
    required String creatorId,
    required String tiktokUrl,
  }) async {
    final videoId = DateTime.now().millisecondsSinceEpoch.toString();
    final res = await _client.from('submissions').insert({
      'campaign_id': campaignId,
      'creator_id': creatorId,
      'tiktok_video_url': tiktokUrl,
      'tiktok_video_id': videoId,
      'status': 'pending_review',
    }).select().single();

    // Auto-create referral shortlink if campaign has a destination
    final camp = await _client.from('campaigns').select('target_destination_url').eq('id', campaignId).single();
    if (camp['target_destination_url'] != null) {
      final slug = 'c-${creatorId.substring(0, 5)}-${campaignId.substring(0, 5)}';
      await _client.from('referral_links').upsert({
        'campaign_id': campaignId,
        'creator_id': creatorId,
        'slug': slug,
        'target_url': camp['target_destination_url'],
      }, onConflict: 'campaign_id,creator_id');
    }

    return Submission.fromJson(res);
  }

  // 6. Fetch Wallet, Bank Accounts & Transactions
  static Future<Wallet> fetchWallet(String userId) async {
    final data = await _client.from('wallets').select().eq('user_id', userId).maybeSingle();
    if (data == null) {
      return Wallet(id: '', userId: userId, availableBalance: 0.0, pendingBalance: 0.0, currency: 'NGN');
    }
    return Wallet.fromJson(data);
  }

  static Future<List<BankAccount>> fetchBankAccounts(String userId) async {
    final data = await _client.from('bank_accounts').select().eq('creator_id', userId).order('is_primary', ascending: false);
    return (data as List).map((b) => BankAccount.fromJson(b)).toList();
  }

  static Future<List<WalletTransaction>> fetchTransactions(String walletId) async {
    if (walletId.isEmpty) return [];
    final data = await _client.from('transactions').select().eq('wallet_id', walletId).order('created_at', ascending: false).limit(25);
    return (data as List).map((t) => WalletTransaction.fromJson(t)).toList();
  }

  // 7. Request Cashout / Withdrawal
  static Future<void> requestWithdrawal({
    required String walletId,
    required String userId,
    required double amount,
    required String bankDetailsDescription,
  }) async {
    final ref = 'wdr_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 5)}';
    
    // Deduct from wallet balance
    await _client.rpc('decrement_wallet_balance', params: {
      'p_wallet_id': walletId,
      'p_amount': amount,
    }).catchError((_) async {
      // Fallback direct update
      final w = await _client.from('wallets').select('available_balance').eq('id', walletId).single();
      final currentBal = (w['available_balance'] as num).toDouble();
      await _client.from('wallets').update({'available_balance': currentBal - amount}).eq('id', walletId);
    });

    // Record pending transaction
    await _client.from('transactions').insert({
      'wallet_id': walletId,
      'type': 'withdrawal',
      'amount': amount,
      'status': 'pending',
      'reference': ref,
      'description': 'Cashout to $bankDetailsDescription',
    });
  }

  // 8. Agency Operations (Campaigns & Approvals)
  static Future<List<Campaign>> fetchAgencyCampaigns(String agencyId) async {
    final data = await _client.from('campaigns').select().eq('agency_id', agencyId).order('created_at', ascending: false);
    return (data as List).map((c) => Campaign.fromJson(c)).toList();
  }

  static Future<List<Submission>> fetchAgencySubmissions(String agencyId) async {
    final data = await _client
        .from('submissions')
        .select('*, campaigns!inner(agency_id, title, cpm_rate), profiles(full_name, tiktok_handle)')
        .eq('campaigns.agency_id', agencyId)
        .order('created_at', ascending: false);

    return (data as List).map((json) {
      final camp = json['campaigns'] as Map<String, dynamic>?;
      return Submission.fromJson({
        ...json,
        'campaign_title': camp?['title'],
        'cpm_rate': camp?['cpm_rate'],
      });
    }).toList();
  }

  static Future<void> reviewSubmission(String submissionId, String status, {String? reason}) async {
    await _client.from('submissions').update({
      'status': status,
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', submissionId);
  }

  static Future<Campaign> createCampaign({
    required String agencyId,
    required String title,
    required String description,
    required String category,
    required String objective,
    required double totalBudget,
    required double cpmRate,
    required double cpcRate,
    String? targetUrl,
  }) async {
    final data = await _client.from('campaigns').insert({
      'agency_id': agencyId,
      'title': title,
      'description': description,
      'category': category,
      'objective': objective,
      'status': 'active',
      'total_budget': totalBudget,
      'remaining_budget': totalBudget,
      'cpm_rate': cpmRate,
      'cpc_rate': cpcRate,
      'target_destination_url': targetUrl,
    }).select().single();

    return Campaign.fromJson(data);
  }
}
