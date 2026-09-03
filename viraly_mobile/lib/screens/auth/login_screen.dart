import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../creator/creator_shell.dart';
import '../agency/agency_shell.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;

  const LoginScreen({super.key, this.initialRole = 'creator'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'role': _role,
          },
        );

        if (res.user != null) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': name,
            'email': email,
            'role': _role,
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

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
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during authentication.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTikTokAuth() async {
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
                'Link your TikTok account to start earning bounties per 10k views.',
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
            child: const Text('Connect & Enter', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (result != true) return;

    final handle = handleController.text.trim().replaceAll('@', '');
    final name = nameController.text.trim().isNotEmpty ? nameController.text.trim() : handle;

    setState(() => _isLoading = true);

    try {
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
            'role': _role,
            'tiktok_handle': handle,
          },
        );
      });

      if (authRes.user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': authRes.user!.id,
          'full_name': name,
          'email': dummyEmail,
          'role': _role,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role badge indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _role == 'creator' ? ViralyTheme.emerald.withAlpha(25) : ViralyTheme.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _role == 'creator' ? ViralyTheme.emerald.withAlpha(80) : ViralyTheme.indigo.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _role == 'creator' ? LucideIcons.sparkles : LucideIcons.rocket,
                      size: 14,
                      color: _role == 'creator' ? ViralyTheme.emerald : ViralyTheme.indigo,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _role == 'creator' ? 'CREATOR ACCOUNT' : 'BRAND / AGENCY ACCOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _role == 'creator' ? ViralyTheme.emerald : ViralyTheme.indigo,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _isSignUp ? 'Join Viraly today' : 'Sign in to your account',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isSignUp
                    ? 'Start turning your TikTok views into guaranteed Naira income.'
                    : 'Access your active campaigns, live view earnings, and Naira wallet.',
                style: TextStyle(fontSize: 13, color: ViralyTheme.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ViralyTheme.rose.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ViralyTheme.rose.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: ViralyTheme.rose, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: ViralyTheme.rose, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 1. Continue with TikTok (Primary entry)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTikTokAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161823),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: ViralyTheme.tiktokRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
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
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider(color: ViralyTheme.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR WITH EMAIL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: ViralyTheme.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider(color: ViralyTheme.border)),
                ],
              ),

              const SizedBox(height: 24),

              if (_isSignUp) ...[
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Legal Name',
                  hint: 'e.g. Chuka Obi',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: 14),
              ],

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'chuka@example.com',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••••••',
                icon: LucideIcons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViralyTheme.emerald,
                    foregroundColor: const Color(0xFF07090E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07090E)),
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Create One",
                    style: const TextStyle(
                      color: ViralyTheme.emerald,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ViralyTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ViralyTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ViralyTheme.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ViralyTheme.textMuted, fontSize: 13),
              prefixIcon: Icon(icon, color: ViralyTheme.textMuted, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
