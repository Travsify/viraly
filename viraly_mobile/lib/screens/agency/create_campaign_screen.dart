import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';
import 'paystack_checkout_screen.dart';

class CreateCampaignScreen extends StatefulWidget {
  final UserProfile? profile;

  const CreateCampaignScreen({super.key, this.profile});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _cpmController = TextEditingController(text: '1500');
  final _cpcController = TextEditingController(text: '30');
  final _targetUrlController = TextEditingController();

  String _category = 'Apps & Tech';
  String _objective = 'hybrid';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _cpmController.dispose();
    _cpcController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    final cpm = double.tryParse(_cpmController.text.trim()) ?? 0.0;
    final cpc = double.tryParse(_cpcController.text.trim()) ?? 0.0;
    final targetUrl = _targetUrlController.text.trim();

    if (title.isEmpty || desc.isEmpty || budget < 1000) {
      setState(() => _errorMessage = 'Please provide a title, description, and minimum ₦1,000 budget.');
      return;
    }

    final agencyId = widget.profile?.id ?? SupabaseService.currentUser?.id;
    final email = widget.profile?.email ?? SupabaseService.currentUser?.email ?? '';

    if (agencyId == null) {
      setState(() => _errorMessage = 'Please sign in to launch a campaign.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create campaign in Supabase with status = 'pending_payment'
      final campaign = await SupabaseService.createCampaign(
        agencyId: agencyId,
        title: title,
        description: desc,
        category: _category,
        objective: _objective,
        totalBudget: budget,
        cpmRate: cpm,
        cpcRate: cpc,
        targetUrl: targetUrl.isNotEmpty ? targetUrl : null,
      );

      // 2. Initialize Paystack checkout to collect real escrow payment
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? '';

      final fundRes = await http.post(
        Uri.parse('${ViralyConstants.apiBaseUrl}/api/agency/campaigns/fund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'campaign_id': campaign.id,
          'amount': budget,
          'email': email,
        }),
      );

      if (fundRes.statusCode != 200) {
        // Campaign created but payment init failed — show fallback
        throw Exception('Payment initialization failed. Campaign saved as draft.');
      }

      final fundJson = jsonDecode(fundRes.body) as Map<String, dynamic>;
      final authorizationUrl = fundJson['authorization_url'] as String?;

      if (authorizationUrl == null) {
        throw Exception('No payment URL received from server.');
      }

      if (!mounted) return;

      // 3. Open Paystack Checkout WebView
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutScreen(authorizationUrl: authorizationUrl),
        ),
      );

      if (!mounted) return;

      if (paymentSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Escrow funded! Campaign is now live — creators will see it shortly.'),
            backgroundColor: ViralyTheme.emerald,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign saved as draft. Complete payment to activate it.'),
            backgroundColor: ViralyTheme.amber,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Launch Brand Campaign', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViralyTheme.rose.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ViralyTheme.rose.withAlpha(80)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: ViralyTheme.rose, fontSize: 12)),
              ),
              const SizedBox(height: 16),
            ],

            _buildField('Campaign Title', _titleController, 'e.g. My Brand Virality Campaign'),
            const SizedBox(height: 14),
            _buildField('Creative Brief & Instructions', _descController, 'Explain what creators should do in their 30s TikTok.', maxLines: 3),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: ViralyTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ViralyTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            dropdownColor: ViralyTheme.surfaceElevated,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'Apps & Tech', child: Text('Apps & Tech')),
                              DropdownMenuItem(value: 'Fintech', child: Text('Fintech')),
                              DropdownMenuItem(value: 'Real Estate', child: Text('Real Estate')),
                              DropdownMenuItem(value: 'Food & Delivery', child: Text('Food & Delivery')),
                              DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
                              DropdownMenuItem(value: 'Lifestyle', child: Text('Lifestyle')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Objective', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: ViralyTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ViralyTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _objective,
                            isExpanded: true,
                            dropdownColor: ViralyTheme.surfaceElevated,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'hybrid', child: Text('Hybrid (Views+Clicks)')),
                              DropdownMenuItem(value: 'views_only', child: Text('Views Only')),
                              DropdownMenuItem(value: 'clicks_only', child: Text('Clicks Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _objective = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _buildField('Escrow Budget (₦)', _budgetController, '500000', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('CPM Rate (₦/10k views)', _cpmController, '1500', keyboardType: TextInputType.number)),
              ],
            ),

            const SizedBox(height: 14),

            _buildField('Target App / Website URL', _targetUrlController, 'https://yourbrand.com/download', keyboardType: TextInputType.url),

            const SizedBox(height: 12),

            // Paystack payment info badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ViralyTheme.emerald.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ViralyTheme.emerald.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: ViralyTheme.emerald, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escrow is collected securely via Paystack. Creators are only paid per verified view or qualified click.',
                      style: TextStyle(fontSize: 11, color: ViralyTheme.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViralyTheme.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pay Escrow & Launch Campaign', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ViralyTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ViralyTheme.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
