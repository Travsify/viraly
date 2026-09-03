import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/profile.dart';

class KycScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onVerified;

  const KycScreen({super.key, required this.profile, required this.onVerified});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();
  bool _isSaving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _bvnController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final bvn = _bvnController.text.trim();
    if (bvn.length != 11 || !RegExp(r'^\d{11}$').hasMatch(bvn)) {
      setState(() => _errorMsg = 'BVN must be exactly 11 digits.');
      return;
    }

    setState(() { _isSaving = true; _errorMsg = null; });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken ?? '';

      // Live verification with Prembly IdentityPass / NIBSS
      final response = await http.post(
        Uri.parse('${ViralyConstants.apiBaseUrl}/api/kyc/verify-bvn'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bvn': bvn,
          'nin': _ninController.text.trim(),
        }),
      );

      final resJson = jsonDecode(response.body);

      if (response.statusCode == 200 && resJson['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Verified: ${resJson["verified_name"] ?? "BVN confirmed via NIBSS"}'),
              backgroundColor: ViralyTheme.emerald,
            ),
          );
          widget.onVerified();
        }
      } else {
        setState(() => _errorMsg = resJson['error'] ?? 'BVN verification failed with NIBSS.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Network error during verification. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Identity Verification (KYC)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ViralyTheme.indigo.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ViralyTheme.indigo.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: ViralyTheme.indigo, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CBN Compliance Required',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified instantly against the NIBSS regulatory registry via Prembly IdentityPass.',
                          style: TextStyle(fontSize: 11, color: ViralyTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('FULL LEGAL NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: ViralyTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: Text(widget.profile.fullName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            const Text('BVN (BANK VERIFICATION NUMBER)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: ViralyTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: TextField(
                controller: _bvnController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2),
                decoration: const InputDecoration(
                  hintText: '22123456789',
                  hintStyle: TextStyle(color: ViralyTheme.textMuted, letterSpacing: 0),
                  prefixIcon: Icon(LucideIcons.creditCard, color: ViralyTheme.textMuted, size: 18),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Verified securely with NIBSS. Only the last 4 digits are retained.', style: TextStyle(fontSize: 10, color: ViralyTheme.textMuted)),
            const SizedBox(height: 20),
            const Text('NIN (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: ViralyTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: TextField(
                controller: _ninController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '12345678901',
                  hintStyle: TextStyle(color: ViralyTheme.textMuted),
                  prefixIcon: const Icon(LucideIcons.fileText, color: ViralyTheme.textMuted, size: 18),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViralyTheme.rose.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ViralyTheme.rose.withAlpha(80)),
                ),
                child: Text(_errorMsg!, style: const TextStyle(color: ViralyTheme.rose, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViralyTheme.emerald,
                  foregroundColor: const Color(0xFF07090E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07090E)))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shieldCheck, size: 18),
                          SizedBox(width: 8),
                          Text('Verify with Prembly IdentityPass', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
