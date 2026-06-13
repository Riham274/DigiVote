import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Uint8List? _tryDecodeBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth       = AuthStateWidget.of(context);
    final isLoggedIn = auth.isLoggedIn;
    final user       = auth.currentUser;
    final isAdmin    = isLoggedIn && user?.role == 'admin';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () => auth.logout(),
                  ),
                ]
              : null,
        ),
        body: isLoggedIn && user != null
            ? isAdmin
                ? _buildAdminView(context, user, auth)
                : _buildUserView(context, user, auth)
            : _buildGuestView(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GUEST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.lock_person_outlined,
                  size: 64, color: Colors.grey[350]),
            ),
            const SizedBox(height: 28),
            const Text(
              'تسجيل الدخول مطلوب',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 12),
            Text(
              'سجّل دخولك للوصول إلى بياناتك الشخصية\nومتابعة كل ما يخص الانتخابات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 48),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN — reads image URL from admins/{nationalId}
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAdminView(
      BuildContext context, dynamic user, AuthNotifier auth) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(user.nationalId as String)
          .snapshots(),
      builder: (ctx, snap) {
        final data = snap.hasData && (snap.data?.exists ?? false)
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final imageUrl = data['image'] as String? ?? '';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user,
                  isAdmin: true, imageBase64: null, imageUrl: imageUrl),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _infoCard(
                      title: 'معلومات المشرف',
                      icon: Icons.admin_panel_settings_rounded,
                      children: [
                        _infoRow(Icons.badge_outlined, 'رقم الهوية الوطنية',
                            user.nationalId as String? ?? ''),
                        _infoRow(Icons.cake_outlined, 'تاريخ الميلاد',
                            user.birthDate as String? ?? ''),
                        _infoRow(Icons.wc_rounded, 'الجنس',
                            user.gender as String? ?? ''),
                        _infoRow(Icons.location_on_outlined, 'العنوان',
                            user.address as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _logoutButton(auth),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER — fully read-only information card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUserView(
      BuildContext context, dynamic user, AuthNotifier auth) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('voters')
          .doc(user.nationalId as String)
          .snapshots(),
      builder: (ctx, snap) {
        final data = snap.hasData && (snap.data?.exists ?? false)
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final imageBase64 = data['image'] as String? ??
            data['face_image_base64'] as String? ??
            '';
        final hasVoted =
            data['has_voted'] as bool? ?? (user.hasVoted as bool? ?? false);
        final gender =
            data['gender'] as String? ?? (user.gender as String? ?? '');
        final dob = data['date_of_birth'] as String? ??
            (user.birthDate as String? ?? '');
        final fullName =
            data['full_name'] as String? ?? (user.name as String? ?? '');
        final address =
            data['address'] as String? ?? (user.address as String? ?? '');
        final phone = data['phone'] as String? ?? '';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user,
                  isAdmin: false, imageBase64: imageBase64),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Read-only info banner ────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F3F).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                const Color(0xFF001F3F).withOpacity(0.12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Color(0xFF001F3F), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'بياناتك الشخصية محمية ولا يمكن تعديلها.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF001F3F),
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Personal data card ───────────────────────────────
                    _infoCard(
                      title: 'البيانات الشخصية',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _infoRow(Icons.person_outline_rounded, 'الاسم الكامل',
                            fullName),
                        _infoRow(Icons.badge_outlined, 'رقم الهوية الوطنية',
                            user.nationalId as String? ?? ''),
                        _infoRow(
                            Icons.cake_outlined, 'تاريخ الميلاد', dob),
                        _infoRow(Icons.wc_rounded, 'الجنس', gender),
                        _infoRow(
                            Icons.location_on_outlined, 'العنوان', address),
                        _infoRow(Icons.phone_outlined, 'رقم الهاتف', phone),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Voting status card ───────────────────────────────
                    _infoCard(
                      title: 'حالة التصويت',
                      icon: Icons.how_to_vote_outlined,
                      children: [
                        _infoRowColored(
                          icon: hasVoted
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          label: 'المشاركة في الانتخابات',
                          value: hasVoted
                              ? '✅  تم التصويت'
                              : '❌  لم يصوّت بعد',
                          color:
                              hasVoted ? Colors.green : Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _logoutButton(auth),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
    dynamic user, {
    required bool isAdmin,
    required String? imageBase64,
    String? imageUrl,
  }) {
    // Resolve avatar image provider: URL takes priority over base64
    ImageProvider? avatarImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      avatarImage = NetworkImage(imageUrl);
    } else {
      final bytes = _tryDecodeBase64(imageBase64);
      if (bytes != null) avatarImage = MemoryImage(bytes);
    }

    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE8EDF5),
              backgroundImage: avatarImage,
              onBackgroundImageError: avatarImage != null
                  ? (_, __) {}
                  : null,
              child: avatarImage == null
                  ? const Icon(Icons.person_rounded,
                      size: 48, color: Color(0xFF001F3F))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name as String? ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  size: 14,
                ),
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
    );
  }

  // ── Card shell ─────────────────────────────────────────────────────────────

  Widget _cardShell({
    required String title,
    required IconData icon,
    required Widget child,
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Info card (read-only rows) ─────────────────────────────────────────────

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _cardShell(
      title: title,
      icon: icon,
      child: Column(children: children),
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
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowColored({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
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
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────

  Widget _logoutButton(AuthNotifier auth) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => auth.logout(),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text('تسجيل الخروج',
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
