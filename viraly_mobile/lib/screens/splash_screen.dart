import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/supabase_service.dart';
import 'onboarding_screen.dart';
import 'creator/creator_shell.dart';
import 'agency/agency_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    if (SupabaseService.isAuthenticated) {
      final profile = await SupabaseService.fetchCurrentUserProfile();
      if (!mounted) return;

      if (profile != null && profile.isAgency) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AgencyShell(profile: profile)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CreatorShell(profile: profile)),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Neo Logo Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ViralyTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: ViralyTheme.emerald.withAlpha(90),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF07090E),
                    letterSpacing: -2,
                  ),
                ),
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .shimmer(duration: 1200.ms, color: Colors.white.withAlpha(100)),

            const SizedBox(height: 28),

            // App Name
            Text(
              ViralyConstants.appName.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'THE PERFORMANCE VIRALITY ENGINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ViralyTheme.emerald.withAlpha(200),
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
