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

  // Fixed-size list — indices always correspond to the same screens
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0 → Home / Admin Dashboard
    GlobalKey<NavigatorState>(), // 1 → Candidates
    GlobalKey<NavigatorState>(), // 2 → Polling Stations
    GlobalKey<NavigatorState>(), // 3 → Notifications
    GlobalKey<NavigatorState>(), // 4 → Account
  ];

  @override
  Widget build(BuildContext context) {
    // AuthStateWidget is above MaterialApp, so this always resolves correctly
    // even from inside a nested Navigator.
    final auth = AuthStateWidget.of(context);
    final isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;
    final isAdmin = isLoggedIn && user?.role == 'admin';
    final isUser = isLoggedIn && user?.role == 'user';

    // Build the visible tab → IndexedStack index mapping
    // Guest  : [0=Home, 4=Account]
    // User   : [0=Home, 1=Cand, 2=Stations, 3=Notif, 4=Account]
    // Admin  : no bottom nav (full-screen dashboard)
    final List<int> visibleIndices = [0];
    if (isUser) visibleIndices.addAll([1, 2, 3]);
    if (!isAdmin) visibleIndices.add(4);

    // If current index no longer visible (e.g. after logout), reset to 0
    if (!visibleIndices.contains(_currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }

    final int barIndex =
        visibleIndices.indexOf(_currentIndex).clamp(0, visibleIndices.length - 1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          final canPop = await _navigatorKeys[_currentIndex]
              .currentState
              ?.maybePop() ?? false;
          if (!canPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return false;
          }
          return !canPop;
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              // 0 — Home / Dashboard
              TabNavigator(
                navigatorKey: _navigatorKeys[0],
                rootScreen: isAdmin
                    ? const AdminDashboardScreen()
                    : isUser
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

          // Admin gets NO bottom nav — the dashboard is the only screen
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
