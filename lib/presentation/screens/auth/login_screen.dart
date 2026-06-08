import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final nationalId = _nationalIdController.text.trim();
    final password = _passwordController.text;

    if (nationalId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال رقم الهوية وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ── 1. Check admins collection first ──────────────────────────
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(nationalId)
          .get();

      if (!mounted) return;

      if (adminDoc.exists) {
        final adminData = adminDoc.data()!;
        final storedPassword = adminData['password'] as String? ?? '';
        final role = adminData['role'] as String? ?? '';

        if (password != storedPassword) {
          setState(() => _errorMessage = 'كلمة المرور غير صحيحة');
          return;
        }
        if (role != 'admin') {
          setState(() => _errorMessage = 'رقم الهوية غير صحيح');
          return;
        }

        final admin = UserModel.fromFirestore(adminDoc.id, adminData);
        AuthStateWidget.of(context).login(admin);
        Navigator.pop(context);
        return;
      }

      // ── 2. Check voters collection ────────────────────────────────
      final voterDoc = await FirebaseFirestore.instance
          .collection('voters')
          .doc(nationalId)
          .get();

      if (!mounted) return;

      if (!voterDoc.exists) {
        setState(() => _errorMessage = 'رقم الهوية غير صحيح');
        return;
      }

      final voterData = voterDoc.data()!;
      final storedPassword = voterData['password'] as String? ?? '';

      if (password != storedPassword) {
        setState(() => _errorMessage = 'كلمة المرور غير صحيحة');
        return;
      }

      final voter = UserModel.fromFirestore(voterDoc.id, voterData);

      // ── Block if already voted ───────────────────────────────────
      if (voter.hasVoted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              icon: const Icon(Icons.how_to_vote_rounded,
                  color: Color(0xFF001F3F), size: 48),
              title: const Text(
                'شكراً لمشاركتك',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F3F)),
              ),
              content: const Text(
                'لقد قمت بالتصويت مسبقاً، شكراً لمشاركتك في العملية الديمقراطية.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.6, fontSize: 14),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
      }

      AuthStateWidget.of(context).login(voter);
      // Save FCM token so admin can send push notifications to this device
      FcmService.saveToken(nationalId);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ في الاتصال، حاول مجدداً');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SafeArea(
          child: Stack(
            children: [
              // Faint background icon
              Positioned(
                bottom: -50,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.security, size: 400, color: Colors.grey[900]),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF000613),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.how_to_vote,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'UniVote',
                      style: TextStyle(
                        color: Color(0xFF001F3F),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المنصة الوطنية للانتخابات',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 48),

                    // ── Form card ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── National ID ──────────────────────────────
                          const Text(
                            'رقم الهوية الوطنية',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          _inputField(
                            controller: _nationalIdController,
                            hint: '100xxxxxxx',
                            keyboardType: TextInputType.number,
                            suffixIcon: Icons.badge_outlined,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: 20),

                          // ── Password ─────────────────────────────────
                          const Text(
                            'كلمة المرور',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          _passwordField(),
                          const SizedBox(height: 32),

                          // ── Login button ─────────────────────────────
                          GestureDetector(
                            onTap: _isLoading ? null : _login,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000613),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'دخول',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // ── Error message ─────────────────────────────
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Security badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text('تشفير نهاية لنهاية',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(
                            height: 16, width: 1, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Icon(Icons.verified_user,
                            color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text('تحقق وطني',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: !_isLoading,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '••••••••',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
