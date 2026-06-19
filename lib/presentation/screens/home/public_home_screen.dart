import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/login_screen.dart';
import '../../widgets/election_countdown_card.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  void _goToLogin(BuildContext context, [String? msg]) {
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF001F3F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 35),
              const SizedBox(width: 6),
              const Text(
                'DigiVote',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF001F3F),
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _goToLogin(context),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Live countdown ──────────────────────────────────────
              const ElectionCountdownCard(),
              const SizedBox(height: 28),

              // ── 2. Voting steps ────────────────────────────────────────
              _sectionTitle(
                'خطوات التصويت',
                'دليلك السريع للمشاركة في اختيار ممثليك',
              ),
              const SizedBox(height: 16),
              const _VotingSteps(),
              const SizedBox(height: 28),

              // ── 3. Candidates preview ──────────────────────────────────
              Row(
                children: [
                  const Text(
                    'أبرز المرشحين',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF001F3F),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _goToLogin(
                      context,
                      'يرجى تسجيل الدخول للاطلاع على تفاصيل المرشحين',
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'عرض جميع المرشحين',
                          style: TextStyle(
                            color: Color(0xFF001F3F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_back_ios_rounded,
                            size: 12, color: Color(0xFF001F3F)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'تعرف على الكفاءات الأكاديمية والطلابية المتقدمة للدورة الحالية',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
              _CandidatesSection(
                onLoginRequired: () => _goToLogin(
                  context,
                  'يرجى تسجيل الدخول للاطلاع على تفاصيل المرشحين',
                ),
              ),
              const SizedBox(height: 28),

              // ── 4. Polling centers ─────────────────────────────────────
              _sectionTitle(
                'مراكز الاقتراع',
                'ابحث عن أقرب مركز اقتراع معتمد في منطقتك',
              ),
              const SizedBox(height: 16),
              _CentersSection(
                onLoginRequired: () => _goToLogin(
                  context,
                  'يرجى تسجيل الدخول لتحديد أقرب مركز',
                ),
              ),
              const SizedBox(height: 28),

              // ── 5. Support CTA ─────────────────────────────────────────
              _SupportBanner(onTap: () => _goToLogin(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF001F3F),
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ─── Voting steps ─────────────────────────────────────────────────────────────

class _VotingSteps extends StatelessWidget {
  const _VotingSteps();

  static const _titles = [
    'تسجيل الدخول',
    'تحديد المركز',
    'شارك بصوتك',
  ];

  static const _descs = [
    'تحقق من توفر حسابك من خلال تسجيل الدخول باستخدام بياناتك الرسمية.',
    'ابحث عن أقرب مركز اقتراع معتمد من خلال تبويب المراكز المتاح على المنصة.',
    'توجه إلى المركز المختار خلال ساعات الاقتراع وأدِّ صوتك في أماكن مخصصة.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _titles.length; i++) ...[
          _StepCard(number: i + 1, title: _titles[i], desc: _descs[i]),
          if (i < _titles.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String desc;

  const _StepCard({
    required this.number,
    required this.title,
    required this.desc,
  });

  String _toArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF001F3F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _toArabic(number),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF001F3F),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Candidates section ───────────────────────────────────────────────────────

class _CandidatesSection extends StatelessWidget {
  final VoidCallback onLoginRequired;
  const _CandidatesSection({required this.onLoginRequired});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidates')
          .limit(10)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(210);
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyBox('لا يوجد مرشحون حالياً');

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name =
                  d['name_ar'] as String? ?? d['name'] as String? ?? '';
              final image = d['image'] as String? ?? '';
              final affiliation = d['affiliation'] as String? ??
                  d['qualification'] as String? ??
                  '';
              final role = d['slogan'] as String? ?? '';

              return GestureDetector(
                onTap: onLoginRequired,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      children: [
                        // Circular photo with affiliation badge
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF001F3F)
                                      .withOpacity(0.12),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: image.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: image,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            _avatarPlaceholder(),
                                        errorWidget: (_, __, ___) =>
                                            _avatarPlaceholder(),
                                      )
                                    : _avatarPlaceholder(),
                              ),
                            ),
                            if (affiliation.isNotEmpty)
                              Positioned(
                                bottom: -10,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 120),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001F3F),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    affiliation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Name
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F3F),
                            height: 1.3,
                          ),
                        ),

                        if (role.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // View profile
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001F3F).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'عرض الملف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: const Color(0xFFE8EDF5),
        child: const Icon(Icons.person_rounded,
            color: Color(0xFF001F3F), size: 34),
      );
}

// ─── Polling centers section ──────────────────────────────────────────────────

class _CentersSection extends StatelessWidget {
  final VoidCallback onLoginRequired;
  const _CentersSection({required this.onLoginRequired});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('voting_center')
          .snapshots(),
      builder: (_, snap) {
        final total = snap.data?.docs.length ?? 0;
        final active = snap.data?.docs.where((d) {
              return (d.data() as Map<String, dynamic>)['status'] ==
                  'مفتوح';
            }).length ??
            0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            total > 0 ? '$total مركزاً معتمداً' : 'مراكز الاقتراع',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF001F3F),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            active > 0
                                ? '$active مركز مفتوح في جميع المحافظات'
                                : 'في جميع المحافظات',
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFF001F3F).withOpacity(0.18),
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Map illustration area
              Container(
                height: 160,
                color: const Color(0xFFF1F5F9),
                child: Stack(
                  children: [
                    // Grid pattern background
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    // Center icon
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001F3F).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: Color(0xFF001F3F),
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // CTA button
                    Positioned(
                      bottom: 14,
                      left: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: onLoginRequired,
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: const Text(
                          'تحديد أقرب مركز',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF001F3F),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.15),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF001F3F).withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Support CTA banner ───────────────────────────────────────────────────────

class _SupportBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000613), Color(0xFF001F3F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هل تواجه مشكلة في التسجيل؟',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'فريق الدعم الفني متاح على مدار الساعة لمساعدتك في إتمام عملية التسجيل.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text(
                    'تواصل معنا',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF001F3F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white54, size: 36),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _shimmer(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(20),
      ),
    );

Widget _emptyBox(String msg) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(msg,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
