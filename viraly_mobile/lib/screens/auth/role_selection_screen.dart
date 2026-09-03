import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../creator/creator_shell.dart';
import '../agency/agency_shell.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'creator'; // 'creator' or 'agency'
  bool _isTikTokLoading = false;

  Future<void> _handleTikTokAuth() async {
    // Show TikTok handle linking dialog
    final handleController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ViralyTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: ViralyTheme.tiktokRed.withAlpha(80)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ViralyTheme.tiktokGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.video, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Continue with TikTok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your TikTok profile handle to connect your channel for live view tracking and escrow payouts.',
                style: TextStyle(fontSize: 12, color: ViralyTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              const Text('YOUR NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: ViralyTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ViralyTheme.border),
                ),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Tunde Balogun',
                    hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('TIKTOK USERNAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ViralyTheme.textMuted)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: ViralyTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ViralyTheme.border),
                ),
                child: TextField(
                  controller: handleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    prefixText: '@ ',
                    prefixStyle: TextStyle(color: ViralyTheme.tiktokCyan, fontWeight: FontWeight.w800),
                    hintText: 'your_tiktok_name',
                    hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ViralyTheme.textMuted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              if (handleController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ViralyTheme.emerald,
              foregroundColor: const Color(0xFF07090E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connect TikTok', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (result != true) return;

    final handle = handleController.text.trim().replaceAll('@', '');
    final name = nameController.text.trim().isNotEmpty ? nameController.text.trim() : handle;

    setState(() => _isTikTokLoading = true);

    try {
      // Create or sign in user via anonymous/custom TikTok auth session
      final dummyEmail = '$handle.tiktok@viraly.ng';
      final dummyPassword = 'TikTokPass_${handle}_2026!';

      var authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: dummyEmail,
        password: dummyPassword,
      ).catchError((_) async {
        return await Supabase.instance.client.auth.signUp(
          email: dummyEmail,
          password: dummyPassword,
          data: {
            'full_name': name,
            'role': _selectedRole,
            'tiktok_handle': handle,
          },
        );
      });

      if (authRes.user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': authRes.user!.id,
          'full_name': name,
          'email': dummyEmail,
          'role': _selectedRole,
          'tiktok_handle': handle,
        });

        final profile = await SupabaseService.fetchCurrentUserProfile();
        if (!mounted) return;

        if (profile != null && profile.isAgency) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AgencyShell(profile: profile)),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => CreatorShell(profile: profile)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TikTok login error: $e'),
            backgroundColor: ViralyTheme.surfaceElevated,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTikTokLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back button & branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: ViralyTheme.emeraldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'V',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF07090E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VIRALY',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24), // Balance spacing
                ],
              ),

              const SizedBox(height: 32),

              // Contained Headline
              const Text(
                'CHOOSE YOUR PATH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: ViralyTheme.emerald,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'How will you use Viraly?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Select your primary profile. You can always switch modes inside settings later.',
                style: TextStyle(
                  fontSize: 13,
                  color: ViralyTheme.textSecondary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              // Role Card 1: Creator / Clipper
              _buildContainedRoleCard(
                role: 'creator',
                title: 'I am a Creator / Clipper',
                description: 'Publish videos on TikTok, submit links, and withdraw cash straight to OPay or your Nigerian bank account.',
                icon: LucideIcons.sparkles,
                badgeText: 'EARN PER VIEW',
                badgeColor: ViralyTheme.emerald,
              ),

              const SizedBox(height: 14),

              // Role Card 2: Brand / Agency
              _buildContainedRoleCard(
                role: 'agency',
                title: 'I am a Brand / Agency',
                description: 'Fund an escrow budget via Flutterwave or Paystack. Receive dozens of organic TikTok videos and only pay for verified views.',
                icon: LucideIcons.rocket,
                badgeText: 'SCALE VIRALLY',
                badgeColor: ViralyTheme.indigo,
              ),

              const SizedBox(height: 36),

              // Action Buttons
              // 1. Continue with TikTok
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isTikTokLoading ? null : _handleTikTokAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161823),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: ViralyTheme.tiktokRed, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isTikTokLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ViralyTheme.tiktokCyan),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: ViralyTheme.tiktokGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.video, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Continue with TikTok',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Continue with Email
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(initialRole: _selectedRole),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViralyTheme.surfaceElevated,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: ViralyTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mail, size: 16, color: ViralyTheme.textSecondary),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer: Already have an account?
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(initialRole: _selectedRole),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: ViralyTheme.textSecondary),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: ViralyTheme.emerald,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainedRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? ViralyTheme.surfaceElevated : ViralyTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ViralyTheme.emerald : ViralyTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ViralyTheme.emerald.withAlpha(35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? ViralyTheme.emerald.withAlpha(30) : const Color(0xFF121722),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? ViralyTheme.emerald : ViralyTheme.textSecondary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Contained text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 12,
                      color: ViralyTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Selected radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? ViralyTheme.emerald : ViralyTheme.textMuted,
                  width: 2,
                ),
                color: isSelected ? ViralyTheme.emerald : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF07090E))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
