import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home/public_home_screen.dart';
import 'candidates/candidates_list_screen.dart';
import 'polling_stations/polling_stations_screen.dart';
import 'notifications/notifications_screen.dart';
import 'account/account_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'user/user_home_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/auth/auth_state.dart';

// ---------------------------------------------------------------------------
// TabNavigator — keeps a per-tab navigation stack
// ---------------------------------------------------------------------------
class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootScreen;

  const TabNavigator(
      {super.key, required this.navigatorKey, required this.rootScreen});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => rootScreen),
    );
  }
}

// ---------------------------------------------------------------------------
// MainNavigationScreen
// ---------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Fixed pool — indices always map to the same screen slots.
  // (Only used when NOT admin; admin bypasses IndexedStack entirely.)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0 → Home
    GlobalKey<NavigatorState>(), // 1 → Candidates
    GlobalKey<NavigatorState>(), // 2 → Polling Stations
    GlobalKey<NavigatorState>(), // 3 → Notifications
    GlobalKey<NavigatorState>(), // 4 → Account
  ];

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------------ auth
    // InheritedNotifier registered here → rebuild fires on every login/logout
    final auth = AuthStateWidget.of(context);
    final bool isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;
    final bool isAdmin = isLoggedIn && user?.role == 'admin';
    final bool isUser  = isLoggedIn && user?.role == 'user';

    // Debug print — visible in Flutter console
    debugPrint('[Auth] isLoggedIn=$isLoggedIn  role=${user?.role ?? "guest"}');

    // ----------------------------------------------------------------- tabs
    // Guest  → [0=Home, 4=Account]
    // User   → [0=Home, 1=Cand, 2=Stations, 3=Notif, 4=Account]
    // Admin  → no bottom nav, no IndexedStack (full-screen dashboard)
    final List<int> visibleIndices = [0];
    if (isUser) visibleIndices.addAll([1, 2, 3]);
    if (!isAdmin) visibleIndices.add(4);

    // Reset stale index on next frame (can't call setState during build)
    if (!isAdmin && !visibleIndices.contains(_currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }

    final int safeIndex = isAdmin ? 0 : _currentIndex.clamp(0, 4);
    final int barIndex  =
        visibleIndices.indexOf(safeIndex).clamp(0, visibleIndices.length - 1);

    // ----------------------------------------------------------------- key
    // Changing this key forces Flutter to destroy and recreate the entire
    // IndexedStack subtree (including all nested Navigators), so there is
    // NEVER a stale route left over from a previous auth state.
    final String authKey = isAdmin ? 'admin' : (isUser ? 'user' : 'guest');

    // ------------------------------------------------------------------ ui
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          if (isAdmin) return false; // admin has no back-stack to pop
          final canPop = await _navigatorKeys[safeIndex]
                  .currentState
                  ?.maybePop() ??
              false;
          if (!canPop && safeIndex != 0) {
            setState(() => _currentIndex = 0);
            return false;
          }
          return !canPop;
        },
        child: Scaffold(
          // ---------------------------------------------------------------
          // ADMIN: render AdminDashboardScreen DIRECTLY as the body.
          // This completely bypasses IndexedStack so there is NO possibility
          // of a stale Navigator showing the wrong screen.
          // ---------------------------------------------------------------
          body: isAdmin
              ? const AdminDashboardScreen()
              // -----------------------------------------------------------
              // USER / GUEST: IndexedStack with ValueKey(authKey).
              // When authKey changes (guest→user, user→guest, etc.) Flutter
              // tears down the old stack and builds fresh Navigators — no
              // stale routes.
              // -----------------------------------------------------------
              : IndexedStack(
                  key: ValueKey(authKey),
                  index: safeIndex,
                  children: [
                    // 0 — Home
                    TabNavigator(
                      navigatorKey: _navigatorKeys[0],
                      rootScreen: isUser
                          ? const UserHomeScreen()
                          : const PublicHomeScreen(),
                    ),
                    // 1 — Candidates
                    TabNavigator(
                      navigatorKey: _navigatorKeys[1],
                      rootScreen: const CandidatesListScreen(),
                    ),
                    // 2 — Polling Stations
                    TabNavigator(
                      navigatorKey: _navigatorKeys[2],
                      rootScreen: const PollingStationsScreen(),
                    ),
                    // 3 — Notifications
                    TabNavigator(
                      navigatorKey: _navigatorKeys[3],
                      rootScreen: const NotificationsScreen(),
                    ),
                    // 4 — Account
                    TabNavigator(
                      navigatorKey: _navigatorKeys[4],
                      rootScreen: const AccountScreen(),
                    ),
                  ],
                ),

          // Admin: no bottom navigation bar (dashboard is the only screen)
          bottomNavigationBar: isAdmin
              ? null
              : Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: barIndex,
                    onTap: (tappedBarIndex) {
                      final targetIndex = visibleIndices[tappedBarIndex];
                      HapticFeedback.lightImpact();
                      if (_currentIndex == targetIndex) {
                        _navigatorKeys[targetIndex]
                            .currentState
                            ?.popUntil((r) => r.isFirst);
                      } else {
                        setState(() => _currentIndex = targetIndex);
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: Colors.grey[400],
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 10),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 10),
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'الرئيسية',
                      ),
                      if (isUser) ...[
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.people_outline),
                          activeIcon: Icon(Icons.people),
                          label: 'المرشحون',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.location_on_outlined),
                          activeIcon: Icon(Icons.location_on),
                          label: 'المراكز',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.notifications_outlined),
                          activeIcon: Icon(Icons.notifications),
                          label: 'الإشعارات',
                        ),
                      ],
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: 'حسابي',
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
