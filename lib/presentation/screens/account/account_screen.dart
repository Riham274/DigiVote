import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  bool _obscurePassword = true;
  bool _isSaving        = false;
  bool _hasInit         = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Pre-populate editable fields only on first data arrival
  void _initControllers(Map<String, dynamic> data) {
    if (_hasInit) return;
    _nameCtrl.text    = data['full_name'] as String? ?? '';
    _addressCtrl.text = data['address']   as String? ?? '';
    _phoneCtrl.text   = data['phone']     as String? ?? '';
    _hasInit = true;
  }

  Future<void> _save(String nationalId) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('voters')
          .doc(nationalId)
          .update({
        'full_name': _nameCtrl.text.trim(),
        'address':   _addressCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التغييرات بنجاح ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الحفظ، حاول مجدداً'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth      = AuthStateWidget.of(context);
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
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6),
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
  // ADMIN
  // ═══════════════════════════════════════════════════════════════════════════

  // Safely decode a base64 image string; returns null on any error
  Uint8List? _tryDecodeBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAdminView(
      BuildContext context, dynamic user, AuthNotifier auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(user, isAdmin: true, imageBase64: null),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoCard(
                  title: 'معلومات المشرف',
                  icon: Icons.admin_panel_settings_rounded,
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
                const SizedBox(height: 24),
                _logoutButton(auth),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUserView(
      BuildContext context, dynamic user, AuthNotifier auth) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('voters')
          .doc(user.nationalId)
          .snapshots(),
      builder: (ctx, snap) {
        final data = snap.hasData && (snap.data?.exists ?? false)
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        if (snap.hasData) _initControllers(data);

        final password    = data['password']       as String? ?? '';
        final imageBase64 = data['image']           as String? ??
                            data['face_image_base64'] as String? ?? '';
        final hasVoted =
            data['has_voted'] as bool? ?? (user.hasVoted as bool? ?? false);
        final gender = data['gender'] as String? ?? (user.gender as String? ?? '');
        final dob = data['date_of_birth'] as String? ??
            (user.birthDate as String? ?? '');

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user, isAdmin: false, imageBase64: imageBase64),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Read-only identity card ──────────────────────────
                    _infoCard(
                      title: 'معلومات الهوية',
                      icon: Icons.badge_outlined,
                      children: [
                        _infoRow(Icons.badge_outlined, 'رقم الهوية',
                            user.nationalId),
                        _infoRow(Icons.cake_outlined, 'تاريخ الميلاد', dob),
                        _infoRow(Icons.wc_rounded, 'الجنس', gender),
                        _infoRowColored(
                          icon: hasVoted
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          label: 'حالة التصويت',
                          value: hasVoted ? '✅  تم التصويت' : '❌  لم يصوّت بعد',
                          color: hasVoted ? Colors.green : Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Password card ────────────────────────────────────
                    _passwordCard(password),
                    const SizedBox(height: 16),

                    // ── Editable fields card ─────────────────────────────
                    _editableCard(user.nationalId),
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

  Widget _buildHeader(dynamic user,
      {required bool isAdmin, required String? imageBase64}) {
    final avatarBytes = _tryDecodeBase64(imageBase64);

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
              backgroundImage:
                  avatarBytes != null ? MemoryImage(avatarBytes) : null,
              child: avatarBytes == null
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

  // ── Password card ──────────────────────────────────────────────────────────

  Widget _passwordCard(String password) {
    return _cardShell(
      title: 'بيانات الحساب',
      icon: Icons.lock_outline_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كلمة المرور',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    _obscurePassword
                        ? '••••••••'
                        : (password.isEmpty ? '—' : password),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword ? 'إظهار' : 'إخفاء',
            ),
          ],
        ),
      ),
    );
  }

  // ── Editable fields card ───────────────────────────────────────────────────

  Widget _editableCard(String nationalId) {
    return _cardShell(
      title: 'البيانات القابلة للتعديل',
      icon: Icons.edit_outlined,
      child: Column(
        children: [
          _editField(
            controller: _nameCtrl,
            label: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _editField(
            controller: _addressCtrl,
            label: 'العنوان',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          _editField(
            controller: _phoneCtrl,
            label: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _save(nationalId),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.primaryContainer, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
