import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthStateWidget lives above MaterialApp → always found, even inside
    // nested Navigators inside IndexedStack.
    final auth = AuthStateWidget.of(context);
    final isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'حسابي',
          style: TextStyle(
              color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: isLoggedIn
            ? [
                IconButton(
                  icon:
                      const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () => auth.logout(),
                ),
              ]
            : null,
      ),
      body: isLoggedIn && user != null
          ? _buildProfileView(context, user, auth)
          : _buildGuestView(context),
    );
  }

  // ------------------------------------------------------------------
  // GUEST VIEW
  // ------------------------------------------------------------------
  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Icon(Icons.lock_person_outlined,
                  size: 64, color: Colors.grey[350]),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              'تسجيل الدخول مطلوب',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'سجّل دخولك للوصول إلى بياناتك الشخصية\nومتابعة كل ما يخص الانتخابات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 48),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('تسجيل الدخول',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // PROFILE VIEW (logged-in user or admin)
  // ------------------------------------------------------------------
  Widget _buildProfileView(
      BuildContext context, dynamic user, AuthNotifier auth) {
    final bool isAdmin = user.role == 'admin';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ---- Header gradient banner ----
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                    : [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            const AssetImage('assets/images/image_6.jpg'),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_outlined,
                            size: 16,
                            color: isAdmin
                                ? const Color(0xFF1E293B)
                                : AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.how_to_vote_outlined,
                          color: Colors.white70,
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                        isAdmin ? 'مسؤول النظام' : 'مواطن مسجّل',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- Cards ----
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoCard(
                  title: 'المعلومات الشخصية',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _infoRow(Icons.badge_outlined, 'رقم الهوية الوطنية',
                        user.nationalId),
                    _infoRow(Icons.cake_outlined, 'تاريخ الميلاد',
                        user.birthDate),
                    _infoRow(Icons.wc_rounded, 'الجنس', user.gender),
                    _infoRow(Icons.location_on_outlined, 'العنوان',
                        user.address),
                  ],
                ),
                const SizedBox(height: 16),
                _infoCard(
                  title: 'إعدادات الحساب',
                  icon: Icons.settings_outlined,
                  children: [
                    _infoRow(Icons.lock_outline_rounded, 'كلمة المرور',
                        '••••••••'),
                    _infoRow(Icons.language_rounded, 'اللغة', 'العربية'),
                    _infoRow(
                        Icons.notifications_outlined, 'الإشعارات', 'مفعّلة'),
                  ],
                ),
                const SizedBox(height: 16),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                    label: const Text('تسجيل الخروج',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),

          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
