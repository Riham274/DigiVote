import 'package:flutter/material.dart';
import '../../../core/auth/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SafeArea(
          child: Stack(
            children: [
              // Background Shield Image (very faint)
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Logo Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF000613),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.how_to_vote, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    // UniVote text
                    const Text(
                      "UniVote",
                      style: TextStyle(
                        color: Color(0xFF001F3F),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      "المنصة الوطنية للانتخابات",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 48),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          const Text("رقم الهوية الوطنية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "100xxxxxxx",
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                                Icon(Icons.badge_outlined, color: Colors.grey[500]),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Password
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("نسيت كلمة المرور؟", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF000613))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "••••••••",
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                                Icon(Icons.lock_outline, color: Colors.grey[500]),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Login Buttons (Mocking Role Based Login)
                          GestureDetector(
                            onTap: () {
                              AuthStateWidget.of(context).login('user');
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004488),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text("تسجيل الدخول كمستخدم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              AuthStateWidget.of(context).login('admin');
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000613),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text("تسجيل الدخول كمشرف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    // Badges row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text("تشفير نهاية لنهاية", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(height: 16, width: 1, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Icon(Icons.verified_user, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text("تحقق وطني", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 48), // Padding bottom
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
