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

  // --- User / Guest navigator keys (5 slots) ---
  final List<GlobalKey<NavigatorState>> _userNavKeys = [
    GlobalKey<NavigatorState>(), // 0 → Home
    GlobalKey<NavigatorState>(), // 1 → Candidates
    GlobalKey<NavigatorState>(), // 2 → Polling Stations
    GlobalKey<NavigatorState>(), // 3 → Notifications
    GlobalKey<NavigatorState>(), // 4 → Account
  ];

  // --- Admin navigator keys (4 slots) ---
  final List<GlobalKey<NavigatorState>> _adminNavKeys = [
    GlobalKey<NavigatorState>(), // 0 → Dashboard
    GlobalKey<NavigatorState>(), // 1 → Add Candidate
    GlobalKey<NavigatorState>(), // 2 → Add Polling Station
    GlobalKey<NavigatorState>(), // 3 → Account
  ];

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------------ auth
    final auth = AuthStateWidget.of(context);
    final bool isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;
    final bool isAdmin = isLoggedIn && user?.role == 'admin';
    final bool isUser  = isLoggedIn && user?.role == 'user';

    debugPrint('[Auth] isLoggedIn=$isLoggedIn  role=${user?.role ?? "guest"}');

    // ----------------------------------------------------------------- key
    // Changes when auth state changes → tears down old IndexedStack/Navigators
    final String authKey = isAdmin ? 'admin' : (isUser ? 'user' : 'guest');

    // ----------------------------------------------------------------- tabs
    // Guest  → [0=Home, 4=Account]        (2 tabs)
    // User   → [0..4]                     (5 tabs)
    // Admin  → [0=Dashboard, 1=Candidate, 2=Center, 3=Account]  (4 tabs)
    final List<int> userVisibleIndices = [0];
    if (isUser) userVisibleIndices.addAll([1, 2, 3]);
    userVisibleIndices.add(4);

    // Max index for current role
    final int maxIndex = isAdmin ? 3 : 4;

    // Reset stale index on next frame
    if (_currentIndex > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }

    final int safeIndex = _currentIndex.clamp(0, maxIndex);

    // barIndex for user/guest (maps visible tabs to actual indices)
    final int userBarIndex = isAdmin
        ? safeIndex
        : userVisibleIndices
            .indexOf(safeIndex)
            .clamp(0, userVisibleIndices.length - 1);

    // ------------------------------------------------------------------ ui
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          final keys = isAdmin ? _adminNavKeys : _userNavKeys;
          final canPop =
              await keys[safeIndex].currentState?.maybePop() ?? false;
          if (!canPop && safeIndex != 0) {
            setState(() => _currentIndex = 0);
            return false;
          }
          return !canPop;
        },
        child: Scaffold(
          // ---------------------------------------------------------------
          // BODY: separate IndexedStack per role, keyed on authKey so
          // Flutter tears down stale navigators on every auth transition.
          // ---------------------------------------------------------------
          body: isAdmin
              ? _buildAdminStack(authKey)
              : _buildUserStack(authKey, isUser, userVisibleIndices, safeIndex),

          // ---------------------------------------------------------------
          // BOTTOM NAV
          // ---------------------------------------------------------------
          bottomNavigationBar: isAdmin
              ? _buildAdminNav(safeIndex)
              : _buildUserNav(safeIndex, isUser, userVisibleIndices,
                  userBarIndex),
        ),
      ),
    );
  }

  // =========================================================================
  // ADMIN
  // =========================================================================

  Widget _buildAdminStack(String authKey) {
    return IndexedStack(
      key: ValueKey(authKey),
      index: _currentIndex.clamp(0, 3),
      children: [
        // 0 — Admin Dashboard
        TabNavigator(
          navigatorKey: _adminNavKeys[0],
          rootScreen: const AdminDashboardScreen(),
        ),
        // 1 — Candidates (shared screen — admin sees extra FAB inside)
        TabNavigator(
          navigatorKey: _adminNavKeys[1],
          rootScreen: const CandidatesListScreen(),
        ),
        // 2 — Polling Stations (shared screen — admin sees extra FAB inside)
        TabNavigator(
          navigatorKey: _adminNavKeys[2],
          rootScreen: const PollingStationsScreen(),
        ),
        // 3 — Account (admin profile)
        TabNavigator(
          navigatorKey: _adminNavKeys[3],
          rootScreen: const AccountScreen(),
        ),
      ],
    );
  }

  Widget _buildAdminNav(int safeIndex) {
    return Container(
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
        currentIndex: safeIndex.clamp(0, 3),
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (_currentIndex == index) {
            _adminNavKeys[index]
                .currentState
                ?.popUntil((r) => r.isFirst);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'لوحة التحكم',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'المرشحون',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'المراكز',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // USER / GUEST
  // =========================================================================

  Widget _buildUserStack(String authKey, bool isUser,
      List<int> visibleIndices, int safeIndex) {
    return IndexedStack(
      key: ValueKey(authKey),
      index: safeIndex,
      children: [
        // 0 — Home
        TabNavigator(
          navigatorKey: _userNavKeys[0],
          rootScreen: isUser ? const UserHomeScreen() : const PublicHomeScreen(),
        ),
        // 1 — Candidates
        TabNavigator(
          navigatorKey: _userNavKeys[1],
          rootScreen: const CandidatesListScreen(),
        ),
        // 2 — Polling Stations
        TabNavigator(
          navigatorKey: _userNavKeys[2],
          rootScreen: const PollingStationsScreen(),
        ),
        // 3 — Notifications
        TabNavigator(
          navigatorKey: _userNavKeys[3],
          rootScreen: const NotificationsScreen(),
        ),
        // 4 — Account
        TabNavigator(
          navigatorKey: _userNavKeys[4],
          rootScreen: const AccountScreen(),
        ),
      ],
    );
  }

  Widget _buildUserNav(int safeIndex, bool isUser,
      List<int> visibleIndices, int barIndex) {
    return Container(
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
            _userNavKeys[targetIndex]
                .currentState
                ?.popUntil((r) => r.isFirst);
          } else {
            setState(() => _currentIndex = targetIndex);
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
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
    );
  }
}
