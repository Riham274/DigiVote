import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';
import 'add_candidate_screen.dart';
import 'add_voting_center_screen.dart';
import 'city_voting_stats_screen.dart';
import 'election_results_screen.dart';
import 'send_notification_screen.dart';
import '../../widgets/election_countdown_card.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _Stats {
  final int totalVoters;
  final int votedCount;
  final int totalCenters;
  final int activeCenters;
  final int totalCandidates;

  const _Stats({
    required this.totalVoters,
    required this.votedCount,
    required this.totalCenters,
    required this.activeCenters,
    required this.totalCandidates,
  });

  double get votingRate => totalVoters == 0 ? 0 : votedCount / totalVoters;
  int get notVotedCount => totalVoters - votedCount;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_Stats> _statsFuture;
  String? _adminImageUrl;
  bool _adminImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adminImageLoaded) {
      _adminImageLoaded = true;
      _loadAdminImage();
    }
  }

  Future<void> _loadAdminImage() async {
    final nationalId =
        AuthStateWidget.of(context).currentUser?.nationalId ?? '';
    if (nationalId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(nationalId)
          .get();
      if (!mounted) return;
      final url = doc.data()?['image'] as String? ?? '';
      if (url.isNotEmpty) setState(() => _adminImageUrl = url);
    } catch (_) {}
  }

  Future<_Stats> _loadStats() async {
    final db = FirebaseFirestore.instance;

    final results = await Future.wait([
      db.collection('voters').count().get(),
      db.collection('voters').where('has_voted', isEqualTo: true).count().get(),
      db.collection('voting_center').count().get(),
      db
          .collection('voting_center')
          .where('status', isEqualTo: 'مفتوح')
          .count()
          .get(),
      db.collection('candidates').count().get(),
    ]);

    return _Stats(
      totalVoters: results[0].count ?? 0,
      votedCount: results[1].count ?? 0,
      totalCenters: results[2].count ?? 0,
      activeCenters: results[3].count ?? 0,
      totalCandidates: results[4].count ?? 0,
    );
  }

  void _refresh() => setState(() => _statsFuture = _loadStats());

  @override
  Widget build(BuildContext context) {
    final adminName = AuthStateWidget.of(context).currentUser?.name ?? 'المشرف';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('لوحة تحكم المشرف',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'تحديث',
              onPressed: _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'تسجيل الخروج',
              onPressed: () => AuthStateWidget.of(context).logout(),
            ),
          ],
        ),
        body: FutureBuilder<_Stats>(
          future: _statsFuture,
          builder: (context, snap) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome ─────────────────────────────────────────────
                  Text(
                    'مرحباً، $adminName',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إليك نظرة عامة على حالة الانتخابات',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // ── Election countdown ───────────────────────────────────
                  const ElectionCountdownCard(),
                  const SizedBox(height: 28),

                  // ── Stats ────────────────────────────────────────────────
                  Text(
                    'الإحصائيات العامة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),

                  if (snap.connectionState == ConnectionState.waiting)
                    const _LoadingStats()
                  else if (snap.hasError)
                    _ErrorCard(onRetry: _refresh)
                  else ...[
                    _StatsGrid(stats: snap.data!),
                    const SizedBox(height: 24),
                    _VotingChart(stats: snap.data!),
                  ],

                  const SizedBox(height: 32),

                  // ── Quick actions 2×2 grid ───────────────────────────────
                  Text(
                    'الإجراءات السريعة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'إضافة مركز',
                            subtitle: 'توسيع نطاق التغطية',
                            icon: Icons.add_location_alt_rounded,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AddVotingCenterScreen()),
                            ).then((_) => _refresh()),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            title: 'إضافة مرشح',
                            subtitle: 'تسجيل بيانات جديد',
                            icon: Icons.person_add_rounded,
                            color: const Color(0xFF1E293B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddCandidateScreen()),
                            ).then((_) => _refresh()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'نتائج الانتخابات',
                            subtitle: 'ترتيب المرشحين',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFF0D7377),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ElectionResultsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            title: 'إحصائيات المدن',
                            subtitle: 'نسب التصويت',
                            icon: Icons.location_city_rounded,
                            color: const Color(0xFF7C3AED),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CityVotingStatsScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'إرسال إشعار جديد',
                    subtitle: 'إعلام جميع الناخبين بتحديثات الانتخابات',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFF0369A1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SendNotificationScreen()),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Recent candidates ────────────────────────────────────
                  Text(
                    'آخر المرشحين المضافين',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const _RecentCandidates(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _Stats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'إجمالي الناخبين',
                value: _fmt(stats.totalVoters),
                icon: Icons.people_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                label: 'صوّتوا حتى الآن',
                value: _fmt(stats.votedCount),
                icon: Icons.how_to_vote_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'المراكز النشطة',
                value: '${stats.activeCenters} / ${stats.totalCenters}',
                icon: Icons.location_on_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                label: 'المرشحون',
                value: _fmt(stats.totalCandidates),
                icon: Icons.assignment_ind_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Voting chart ─────────────────────────────────────────────────────────────

class _VotingChart extends StatelessWidget {
  final _Stats stats;
  const _VotingChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rate = stats.votingRate;
    final pct = (rate * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text('نسبة المشاركة في التصويت',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 28),

          // Donut chart + legend
          Row(
            children: [
              // Chart
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
                      painter: _DonutPainter(
                        percentage: rate,
                        activeColor: const Color(0xFF10B981),
                        inactiveColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$pct%',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                        const Text('صوّتوا',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                      color: const Color(0xFF10B981),
                      label: 'صوّتوا',
                      count: stats.votedCount,
                      total: stats.totalVoters,
                    ),
                    const SizedBox(height: 16),
                    _LegendItem(
                      color: const Color(0xFFE2E8F0),
                      label: 'لم يصوّتوا',
                      count: stats.notVotedCount,
                      total: stats.totalVoters,
                      textColor: Colors.grey[600],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'إجمالي الناخبين: ${stats.totalVoters}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  final Color? textColor;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppColors.primary)),
              Text('$count ناخب (${pct.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Donut chart painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double percentage;
  final Color activeColor;
  final Color inactiveColor;

  const _DonutPainter({
    required this.percentage,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 20.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background ring
    paint.color = inactiveColor;
    canvas.drawCircle(center, radius, paint);

    // Foreground arc
    if (percentage > 0) {
      paint.color = activeColor;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * percentage,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.percentage != percentage;
}

// ─── Recent candidates ────────────────────────────────────────────────────────

class _RecentCandidates extends StatelessWidget {
  const _RecentCandidates();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidates')
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text('لا يوجد مرشحون مضافون بعد',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? '';
              final qualification = d['qualification'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary),
                ),
                subtitle: qualification.isNotEmpty
                    ? Text(qualification,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]))
                    : null,
                trailing: const Icon(Icons.chevron_left,
                    color: Colors.grey, size: 18),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Action card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Loading & Error ──────────────────────────────────────────────────────────

class _LoadingStats extends StatelessWidget {
  const _LoadingStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('جارٍ تحميل الإحصائيات...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          const Text('تعذّر تحميل البيانات',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
