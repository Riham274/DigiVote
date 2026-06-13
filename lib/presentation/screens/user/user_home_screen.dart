import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';
import '../candidates/candidates_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../polling_stations/polling_stations_screen.dart';
import '../polling_stations/nearest_center_screen.dart';
import '../voting/voting_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final PageController _pageCtrl = PageController();
  int _campaignPage = 0;
  int _docsCount = 0;
  Timer? _scrollTimer;
  final Set<String> _expandedNews = {};

  late final Future<DateTime?> _electionFuture;

  @override
  void initState() {
    super.initState();
    _electionFuture = _fetchElectionDate();
    _scrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_docsCount < 2 || !mounted) return;
      final next = (_campaignPage + 1) % _docsCount;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Data fetchers ─────────────────────────────────────────────────────────

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
    } catch (e) {
      debugPrint('🔴 election fetch error: $e');
    }
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = AuthStateWidget.of(context).currentUser;
    final name = user?.name ?? 'المواطن الكريم';
    final address = user?.address ?? '';
    final hasVoted = user?.hasVoted ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 150,
          leading: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 12),
                Image.asset('assets/images/logo.png', height: 35),
                const SizedBox(width: 6),
                const Text(
                  'DigiVote',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF001F3F),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'الرئيسية',
                  style: TextStyle(
                    color: Color(0xFF001F3F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ───────────────────────────────────────────────
              Text(
                'أهلاً، $name 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF001F3F),
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                      color: Color(0xFF001F3F), fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),

              // ── TOP BANNER ─────────────────────────────────────────────
              _buildTopBanner(context),
              const SizedBox(height: 16),

              // ── Election countdown ─────────────────────────────────────
              FutureBuilder<DateTime?>(
                future: _electionFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _shimmer(120);
                  }
                  return _buildCountdownCard(snap.data);
                },
              ),

              // ── Voting status ──────────────────────────────────────────
              const SizedBox(height: 12),
              _buildVotingStatus(hasVoted),
              const SizedBox(height: 20),

              // ── Quick actions ──────────────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // ── Campaigns carousel ─────────────────────────────────────
              _sectionTitle('الحملات الإعلانية', Icons.campaign_rounded),
              const SizedBox(height: 12),
              _buildCampaigns(),
              const SizedBox(height: 24),

              // ── Latest news ────────────────────────────────────────────
              _sectionTitle('آخر الأخبار', Icons.article_rounded),
              const SizedBox(height: 12),
              _buildNews(),
              const SizedBox(height: 20),

              // ── Educational banner ─────────────────────────────────────
              _buildEducationalBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP BANNER ───────────────────────────────────────────────────────────

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يوم الانتخابات الوطنية',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'DigiVote — المنصة الوطنية للانتخابات الرقمية',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VotingScreen()),
              ),
              icon: const Icon(Icons.how_to_vote_rounded, size: 20),
              label: const Text(
                'صوّت الآن',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
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

  // ── Election countdown card ────────────────────────────────────────────────

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

    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
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
                color: const Color(0xFF000613).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              isToday ? _countdownToday() : _countdownDays(diff, dateStr),
        ),
      ],
    );
  }

  Widget _countdownToday() {
    return const Column(
      children: [
        Text('🎉', style: TextStyle(fontSize: 40)),
        SizedBox(height: 8),
        Text(
          'اليوم يوم الانتخابات!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'توجه إلى أقرب مركز اقتراع وشارك في صنع المستقبل',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _countdownDays(int days, String dateStr) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'باقي على الانتخابات',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'يوم',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'تاريخ الانتخابات: $dateStr',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today_rounded,
              color: Colors.white, size: 32),
        ),
      ],
    );
  }

  // ── Voting status card ────────────────────────────────────────────────────

  Widget _buildVotingStatus(bool hasVoted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasVoted
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasVoted
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasVoted
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasVoted
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: hasVoted ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasVoted ? 'لقد صوّت بنجاح' : 'لم تصوّت بعد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasVoted
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasVoted
                      ? 'شكراً لمشاركتك في العملية الديمقراطية'
                      : 'توجه إلى أقرب مركز اقتراع للمشاركة',
                  style: TextStyle(
                    color: hasVoted
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions row ─────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _quickBtn(
          icon: Icons.location_on_rounded,
          label: 'أقرب مركز',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NearestCenterScreen()),
          ),
        ),
        _quickBtn(
          icon: Icons.people_rounded,
          label: 'المرشحون',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CandidatesListScreen()),
          ),
        ),
        _quickBtn(
          icon: Icons.notifications_rounded,
          label: 'الإشعارات',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationsScreen()),
          ),
        ),
        _quickBtn(
          icon: Icons.ballot_rounded,
          label: 'المراكز',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PollingStationsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                Icon(icon, color: const Color(0xFF001F3F), size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF001F3F),
            ),
          ),
        ],
      ),
    );
  }

  // ── Campaigns carousel (auto-scroll, image_url field) ─────────────────────

  Widget _buildCampaigns() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(180);
        }
        if (snap.hasError) {
          return _emptyBox('تعذّر تحميل الحملات');
        }
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

        // Sync docs count for auto-scroll timer
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _docsCount != sorted.length) {
            setState(() => _docsCount = sorted.length);
          }
        });

        return _carouselContent(sorted);
      },
    );
  }

  Widget _carouselContent(List<QueryDocumentSnapshot> docs) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: docs.length,
            onPageChanged: (i) => setState(() => _campaignPage = i),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _CampaignCard(
                  title: d['title'] as String? ?? '',
                  description: d['description'] as String? ?? '',
                  imageUrl: d['image_url'] as String? ??
                      d['image'] as String? ??
                      '',
                ),
              );
            },
          ),
        ),
        if (docs.length > 1) ...[
          const SizedBox(height: 12),
          Center(
            child: AnimatedSmoothIndicator(
              activeIndex: _campaignPage,
              count: docs.length,
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
  }

  // ── Latest news ───────────────────────────────────────────────────────────

  Widget _buildNews() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer(160);
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyBox('لا توجد أخبار حالياً');

        final sorted = [...docs]..sort((a, b) {
            final aDate = _parseDate(
                (a.data() as Map<String, dynamic>)['date']);
            final bDate = _parseDate(
                (b.data() as Map<String, dynamic>)['date']);
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate);
          });

        return _newsContent(sorted);
      },
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Widget _newsContent(List<QueryDocumentSnapshot> docs) {
    return Container(
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
      child: Column(
        children: List.generate(docs.length, (i) {
          final doc = docs[i];
          final d = doc.data() as Map<String, dynamic>;
          final isExpanded = _expandedNews.contains(doc.id);
          final isLast = i == docs.length - 1;
          return _NewsItem(
            docId: doc.id,
            title: d['title'] as String? ?? '',
            content: d['content'] as String? ?? '',
            date: _fmtDate(d['date']),
            isExpanded: isExpanded,
            isLast: isLast,
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedNews.remove(doc.id);
              } else {
                _expandedNews.add(doc.id);
              }
            }),
          );
        }),
      ),
    );
  }

  String _fmtDate(dynamic raw) {
    final d = _parseDate(raw);
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Educational banner ────────────────────────────────────────────────────

  Widget _buildEducationalBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF001F3F).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF001F3F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: Color(0xFF001F3F), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 هل تعلم؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF001F3F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'صوتك يحدد مستقبل بلدك، شارك في صنع القرار',
                  style: TextStyle(
                    color: Color(0xFF001F3F),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF001F3F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F3F),
          ),
        ),
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
        padding: const EdgeInsets.all(24),
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

// ─── Campaign card ────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const _CampaignCard({
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
          // Background image with loading/error fallback
          imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _bg(),
                  errorWidget: (_, __, ___) => _bg(),
                )
              : _bg(),

          // Gradient overlay
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

          // Text content
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

// ─── News item ────────────────────────────────────────────────────────────────

class _NewsItem extends StatelessWidget {
  final String docId;
  final String title;
  final String content;
  final String date;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onTap;

  const _NewsItem({
    required this.docId,
    required this.title,
    required this.content,
    required this.date,
    required this.isExpanded,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(
                  bottom: Radius.circular(20))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001F3F).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.article_rounded,
                      color: Color(0xFF001F3F), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(date,
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        content,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFF0F4F8)),
          ),
      ],
    );
  }
}
