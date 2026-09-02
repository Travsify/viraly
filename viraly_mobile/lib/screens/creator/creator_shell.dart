import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import 'gigs_home_screen.dart';
import 'my_submissions_screen.dart';
import 'wallet_screen.dart';
import '../shared/profile_screen.dart';

class CreatorShell extends StatefulWidget {
  final UserProfile? profile;

  const CreatorShell({super.key, this.profile});

  @override
  State<CreatorShell> createState() => _CreatorShellState();
}

class _CreatorShellState extends State<CreatorShell> {
  int _currentIndex = 0;
  late UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      GigsHomeScreen(
        profile: _profile,
        onNavigateToWallet: () => setState(() => _currentIndex = 2),
      ),
      MySubmissionsScreen(profile: _profile),
      WalletScreen(profile: _profile),
      ProfileScreen(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: ViralyTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ViralyTheme.surface,
          border: Border(
            top: BorderSide(color: ViralyTheme.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ViralyTheme.emerald,
          unselectedItemColor: ViralyTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.briefcase, size: 20),
              ),
              label: 'Gigs',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.video, size: 20),
              ),
              label: 'My Videos',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.wallet, size: 20),
              ),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.user, size: 20),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
