import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/login_screen.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final PageController _campaignCtrl = PageController();
  int _campaignPage = 0;
  int _campaignCount = 0;
  Timer? _scrollTimer;

  late final Future<DateTime?> _electionFuture;

  @override
  void initState() {
    super.initState();
    _electionFuture = _fetchElectionDate();
    _scrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_campaignCount < 2 || !mounted) return;
      final next = (_campaignPage + 1) % _campaignCount;
      _campaignCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _campaignCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _fetchElectionDate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('elections_info')
          .doc('current_election')
          .get();
      if (!doc.exists) return null;
      final raw = doc.data()?['election_date'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    } catch (_) {}
    return null;
  }

  void _goToLogin(BuildContext context, [String? msg]) {
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF001F3F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF000613),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.how_to_vote,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'UniVote',
                style: TextStyle(
                  color: Color(0xFF001F3F),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _goToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000613),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('تسجيل الدخول',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Main banner ──────────────────────────────────────────────
              _buildTopBanner(context),
              const SizedBox(height: 20),

              // ── Election countdown ───────────────────────────────────────
              FutureBuilder<DateTime?>(
                future: _electionFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _shimmer(120);
                  }
                  final card = _buildCountdownCard(snap.data);
                  return card;
                },
              ),
              const SizedBox(height: 24),

              // ── Campaigns carousel ───────────────────────────────────────
              _sectionHeader(
                icon: Icons.campaign_rounded,
                title: 'الحملات الإعلانية',
              ),
              const SizedBox(height: 12),
              _buildCampaigns(),
              const SizedBox(height: 24),

              // ── Candidates preview ───────────────────────────────────────
              _sectionHeader(
                icon: Icons.people_rounded,
                title: 'المرشحون',
                trailing: GestureDetector(
                  onTap: () => _goToLogin(context, 'يرجى تسجيل الدخول للاطلاع على تفاصيل المرشحين'),
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: Color(0xFF001F3F),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCandidatesPreview(context),
              const SizedBox(height: 24),

              // ── Educational / CTA banner ─────────────────────────────────
              _buildCtaBanner(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top banner ────────────────────────────────────────────────────────────

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF000613), Color(0xFF001F3F), Color(0xFF003580)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'انتخابات 2026',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنصة الوطنية\nللانتخابات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'صوتك أمانة، شارك في رسم مستقبل الوطن',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.how_to_vote_rounded,
                  color: Colors.white38, size: 64),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _goToLogin(context, 'يرجى تسجيل الدخول للتصويت'),
              icon: const Icon(Icons.how_to_vote_rounded, size: 20),
              label: const Text(
                'صوّت الآن',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF001F3F),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Election countdown card ───────────────────────────────────────────────

  Widget _buildCountdownCard(DateTime? electionDate) {
    if (electionDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elDay = DateTime(
        electionDate.year, electionDate.month, electionDate.day);
    final diff = elDay.difference(today).inDays;
    if (diff < 0) return const SizedBox.shrink();

    final dateStr =
        '${electionDate.day}/${electionDate.month}/${electionDate.year}';
    final isToday = diff == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [const Color(0xFF0D7377), const Color(0xFF14A085)]
              : [const Color(0xFF000613), const Color(0xFF003580)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000613).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isToday
          ? const Column(
              children: [
                Text('🎉', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text(
                  'اليوم يوم الانتخابات!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'توجه إلى أقرب مركز اقتراع وشارك في صنع المستقبل',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'باقي على الانتخابات',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$diff',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'يوم',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تاريخ الانتخابات: $dateStr',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 30),
                ),
              ],
            ),
    );
  }

  // ── Campaigns carousel ────────────────────────────────────────────────────

  Widget _buildCampaigns() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(190);
        }
        if (snap.hasError) return _emptyBox('تعذّر تحميل الحملات');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyBox('لا توجد حملات حالياً');

        final sorted = [...docs]..sort((a, b) {
            final aVal =
                (a.data() as Map<String, dynamic>)['order'];
            final bVal =
                (b.data() as Map<String, dynamic>)['order'];
            if (aVal == null || bVal == null) return 0;
            return (aVal as num).compareTo(bVal as num);
          });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _campaignCount != sorted.length) {
            setState(() => _campaignCount = sorted.length);
          }
        });

        return Column(
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _campaignCtrl,
                itemCount: sorted.length,
                onPageChanged: (i) =>
                    setState(() => _campaignPage = i),
                itemBuilder: (_, i) {
                  final d =
                      sorted[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2),
                    child: _GuestCampaignCard(
                      title: d['title'] as String? ?? '',
                      description:
                          d['description'] as String? ?? '',
                      imageUrl: d['image_url'] as String? ??
                          d['image'] as String? ??
                          '',
                    ),
                  );
                },
              ),
            ),
            if (sorted.length > 1) ...[
              const SizedBox(height: 12),
              Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: _campaignPage,
                  count: sorted.length,
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Color(0xFF001F3F),
                    dotColor: Color(0xFFCDD5E0),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── Candidates horizontal preview ─────────────────────────────────────────

  Widget _buildCandidatesPreview(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidates')
          .limit(10)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(140);
        }
        if (snap.hasError) return _emptyBox('تعذّر تحميل المرشحين');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyBox('لا يوجد مرشحون حالياً');

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = d['name_ar'] as String? ??
                  d['name'] as String? ??
                  '';
              final image = d['image'] as String? ?? '';
              final affiliation =
                  d['affiliation'] as String? ?? '';

              return GestureDetector(
                onTap: () => _goToLogin(context,
                    'يرجى تسجيل الدخول للاطلاع على تفاصيل المرشحين'),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Candidate photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _avatarPlaceholder(),
                                errorWidget: (_, __, ___) =>
                                    _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder(),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F3F),
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (affiliation.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          affiliation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EDF5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded,
          color: Color(0xFF001F3F), size: 32),
    );
  }

  // ── CTA / Educational banner ──────────────────────────────────────────────

  Widget _buildCtaBanner(BuildContext context) {
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
            color: const Color(0xFF001F3F).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.how_to_vote_rounded,
              color: Colors.white54, size: 40),
          const SizedBox(height: 16),
          const Text(
            'سجّل دخولك للمشاركة في الانتخابات\nوممارسة حقك الديمقراطي',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'صوتك يُحدث فرقاً — انضم إلى ملايين المواطنين',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _goToLogin(context),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'تسجيل الدخول',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF001F3F),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, size: 18, color: const Color(0xFF001F3F)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F3F),
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _shimmer(double height) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDF5),
          borderRadius: BorderRadius.circular(20),
        ),
      );

  Widget _emptyBox(String msg) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(msg,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
}

// ─── Guest campaign card ──────────────────────────────────────────────────────

class _GuestCampaignCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const _GuestCampaignCard({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _bg(),
                  errorWidget: (_, __, ___) => _bg(),
                )
              : _bg(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000613), Color(0xFF001F3F)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: const Center(
          child: Icon(Icons.campaign_rounded,
              color: Colors.white30, size: 48),
        ),
      );
}
