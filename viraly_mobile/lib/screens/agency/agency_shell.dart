import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import 'agency_home_screen.dart';
import 'review_submissions_screen.dart';
import '../creator/wallet_screen.dart';
import '../shared/profile_screen.dart';

class AgencyShell extends StatefulWidget {
  final UserProfile? profile;

  const AgencyShell({super.key, this.profile});

  @override
  State<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends State<AgencyShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AgencyHomeScreen(profile: widget.profile),
      ReviewSubmissionsScreen(profile: widget.profile),
      WalletScreen(profile: widget.profile),
      ProfileScreen(profile: widget.profile),
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
          border: Border(top: BorderSide(color: ViralyTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ViralyTheme.indigo,
          unselectedItemColor: ViralyTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.layoutDashboard, size: 20),
              ),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.checkSquare, size: 20),
              ),
              label: 'Approvals',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.landmark, size: 20),
              ),
              label: 'Escrow',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(LucideIcons.user, size: 20),
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
