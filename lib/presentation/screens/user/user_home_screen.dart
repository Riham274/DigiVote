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
import '../../widgets/election_countdown_card.dart';

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

  @override
  void initState() {
    super.initState();
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

              // ── Live election countdown ────────────────────────────────
              const ElectionCountdownCard(),
              const SizedBox(height: 16),

              // ── TOP BANNER ─────────────────────────────────────────────
              _buildTopBanner(context),
              const SizedBox(height: 16),

              // ── Voting status ──────────────────────────────────────────
              const SizedBox(height: 12),
              _buildVotingStatus(hasVoted),
              const SizedBox(height: 20),

              // ── Quick actions ──────────────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // ── Notifications preview ──────────────────────────────────
              _buildNotificationsPreview(context),
              const SizedBox(height: 24),

              // ── Campaigns carousel ─────────────────────────────────────
              _sectionTitle('الحملات الإعلانية', Icons.campaign_rounded),
              const SizedBox(height: 12),
              _buildCampaigns(),
              const SizedBox(height: 24),

              // ── Tips & Information ─────────────────────────────────────
              _buildTipsSection(),
              const SizedBox(height: 20),
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

  // ── Notifications preview (latest 3) ─────────────────────────────────────

  Widget _buildNotificationsPreview(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (_, snap) {
        // Header row always visible
        final header = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('الإشعارات', Icons.notifications_rounded),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              ),
              child: const Row(
                children: [
                  Text(
                    'عرض الكل',
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
        );

        if (snap.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              header,
              const SizedBox(height: 12),
              _shimmer(90),
            ],
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Column(
            children: [
              header,
              const SizedBox(height: 12),
              _emptyBox('لا توجد إشعارات حالياً'),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final isAuto = d['auto'] as bool? ?? false;
              final title = d['title'] as String? ?? 'إشعار';
              final message = d['message'] as String? ?? '';
              final ts = d['timestamp'];
              final accentColor = isAuto
                  ? const Color(0xFF0369A1)
                  : const Color(0xFF001F3F);
              final iconData = isAuto
                  ? Icons.smart_toy_rounded
                  : Icons.campaign_rounded;

              String timeStr = '';
              if (ts is Timestamp) {
                final dt = ts.toDate().toLocal();
                final h = dt.hour.toString().padLeft(2, '0');
                final m = dt.minute.toString().padLeft(2, '0');
                timeStr = '${dt.day}/${dt.month}/${dt.year}  $h:$m';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData,
                              color: accentColor, size: 18),
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
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
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

  // ── Tips & Information ────────────────────────────────────────────────────

  static const _tips = [
    _Tip(
      icon: Icons.how_to_vote,
      title: 'كيف تصوّت؟',
      desc: 'توجه لأقرب مركز اقتراع، سيتم التعرف على وجهك تلقائياً، اختر مرشحك وأكد صوتك',
    ),
    _Tip(
      icon: Icons.lock,
      title: 'صوتك سري',
      desc: 'نظام التوكنات المجهولة يضمن عدم ربط صوتك بهويتك — لا أحد يعرف لمن صوّتت',
    ),
    _Tip(
      icon: Icons.verified_user,
      title: 'التحقق بالوجه',
      desc: 'يتم التعرف على هويتك عبر الكاميرا الذكية — لا حاجة لإبراز أي وثائق',
    ),
    _Tip(
      icon: Icons.access_time,
      title: 'ساعات التصويت',
      desc: 'مراكز الاقتراع مفتوحة من الساعة ٨ صباحاً حتى ٧ مساءً',
    ),
    _Tip(
      icon: Icons.location_on,
      title: 'أقرب مركز',
      desc: 'استخدم خاصية أقرب مركز اقتراع لتحديد الموقع الأقرب إليك والتوجه إليه عبر الخريطة',
    ),
    _Tip(
      icon: Icons.block,
      title: 'صوت واحد فقط',
      desc: 'كل ناخب يحق له التصويت مرة واحدة فقط — النظام يمنع التصويت المتكرر تلقائياً',
    ),
    _Tip(
      icon: Icons.gavel,
      title: 'حقك الانتخابي',
      desc: 'التصويت حق وواجب وطني — صوتك يصنع الفرق في مستقبل مدينتك',
    ),
  ];

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('نصائح ومعلومات', Icons.lightbulb_rounded),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _tips.length,
            itemBuilder: (_, i) => _TipCard(tip: _tips[i]),
          ),
        ),
      ],
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

// ─── Tip data model ───────────────────────────────────────────────────────────

class _Tip {
  final IconData icon;
  final String title;
  final String desc;

  const _Tip({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

// ─── Tip card ─────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final _Tip tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000613), Color(0xFF001F3F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip.icon, color: Colors.white, size: 40),
          const Spacer(),
          Text(
            tip.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
