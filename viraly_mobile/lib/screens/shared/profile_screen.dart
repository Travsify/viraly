import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';
import '../onboarding_screen.dart';
import '../creator/creator_shell.dart';
import '../agency/agency_shell.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? profile;

  const ProfileScreen({super.key, this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _handleController = TextEditingController();
  final _phoneController = TextEditingController();

  late UserProfile? _profile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _handleController.text = _profile?.tiktokHandle ?? '';
    _phoneController.text = _profile?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _handleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final handle = _handleController.text.trim().replaceAll('@', '');
    final phone = _phoneController.text.trim();

    if (_profile == null) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'tiktok_handle': handle.isNotEmpty ? handle : null,
        'phone_number': phone.isNotEmpty ? phone : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _profile!.id);

      final updatedProfile = await SupabaseService.fetchCurrentUserProfile();
      setState(() => _profile = updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: ViralyTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSwitchRole() async {
    if (_profile == null) return;
    final newRole = _profile!.isCreator ? 'agency' : 'creator';

    try {
      await Supabase.instance.client.from('profiles').update({
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _profile!.id);

      final updatedProfile = await SupabaseService.fetchCurrentUserProfile();
      if (!mounted) return;

      if (newRole == 'agency') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AgencyShell(profile: updatedProfile)),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CreatorShell(profile: updatedProfile)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching role: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Account & Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ViralyTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ViralyTheme.emerald.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: ViralyTheme.emerald, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _profile?.fullName.isNotEmpty == true ? _profile!.fullName.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ViralyTheme.emerald),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.fullName ?? 'Viraly User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _profile?.email ?? '',
                          style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_profile?.isCreator ?? true) ? ViralyTheme.emerald.withAlpha(20) : ViralyTheme.indigo.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (_profile?.role ?? 'creator').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: (_profile?.isCreator ?? true) ? ViralyTheme.emerald : ViralyTheme.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'CREATOR PROFILE DETAILS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: ViralyTheme.textMuted),
            ),
            const SizedBox(height: 12),

            _buildField('TikTok Username', _handleController, '@yourname', icon: LucideIcons.video),
            const SizedBox(height: 12),
            _buildField('Phone Number (WhatsApp)', _phoneController, '+234 801 234 5678', icon: LucideIcons.phone),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSaveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViralyTheme.surfaceElevated,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ViralyTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ViralyTheme.indigo.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Switch Account Mode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_profile?.isCreator ?? true) ? 'Switch to Brand / Agency mode' : 'Switch to Creator mode',
                        style: TextStyle(fontSize: 11, color: ViralyTheme.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _handleSwitchRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ViralyTheme.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      (_profile?.isCreator ?? true) ? 'Agency Mode' : 'Creator Mode',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ViralyTheme.rose),
                  foregroundColor: ViralyTheme.rose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.logOut, size: 16),
                    SizedBox(width: 8),
                    Text('Sign Out of Viraly', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {required IconData icon}) {
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
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 12),
              prefixIcon: Icon(icon, color: ViralyTheme.textMuted, size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
