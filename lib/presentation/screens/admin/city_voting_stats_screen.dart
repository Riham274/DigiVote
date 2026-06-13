import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _CityStats {
  final String city;
  final int total;
  final int voted;

  const _CityStats({
    required this.city,
    required this.total,
    required this.voted,
  });

  double get rate => total == 0 ? 0 : voted / total;
  int get notVoted => total - voted;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CityVotingStatsScreen extends StatelessWidget {
  const CityVotingStatsScreen({super.key});

  /// Aggregate raw voter docs into per-city stats, sorted by voting rate desc.
  List<_CityStats> _aggregate(List<QueryDocumentSnapshot> docs) {
    final Map<String, _CityStats> map = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final city = (data['city'] as String? ?? '').trim();
      final label = city.isEmpty ? 'غير محدد' : city;
      final hasVoted = data['has_voted'] as bool? ?? false;

      final prev = map[label] ??
          _CityStats(city: label, total: 0, voted: 0);
      map[label] = _CityStats(
        city: label,
        total: prev.total + 1,
        voted: prev.voted + (hasVoted ? 1 : 0),
      );
    }

    final list = map.values.toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));
    return list;
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
          title: const Text(
            'إحصائيات التصويت حسب المدينة',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF000613)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF000613)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('voters')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF001F3F)),
              );
            }

            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('تعذّر تحميل البيانات',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            final cities = _aggregate(docs);

            // Overall totals
            final totalVoters = docs.length;
            final totalVoted =
                docs.where((d) {
                  return (d.data() as Map<String, dynamic>)['has_voted']
                          as bool? ??
                      false;
                }).length;
            final overallRate =
                totalVoters == 0 ? 0.0 : totalVoted / totalVoters;

            return CustomScrollView(
              slivers: [
                // ── Live badge ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'تحديث فوري • البيانات مباشرة',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${cities.length} مدينة',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── City cards ───────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CityCard(
                          stats: cities[i],
                          rank: i + 1,
                        ),
                      ),
                      childCount: cities.length,
                    ),
                  ),
                ),

                // ── Overall summary card ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _SummaryCard(
                      totalVoters: totalVoters,
                      totalVoted: totalVoted,
                      overallRate: overallRate,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── City card ────────────────────────────────────────────────────────────────

class _CityCard extends StatelessWidget {
  final _CityStats stats;
  final int rank;

  const _CityCard({required this.stats, required this.rank});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.rate * 100).toStringAsFixed(1);
    final isHigh = stats.rate >= 0.7;
    final isMid  = stats.rate >= 0.4 && stats.rate < 0.7;

    final Color barColor;
    if (isHigh) {
      barColor = const Color(0xFF22C55E);  // green
    } else if (isMid) {
      barColor = const Color(0xFFF59E0B);  // amber
    } else {
      barColor = const Color(0xFF001F3F);  // navy
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: rank + city name + percentage ──────────────
            Row(
              children: [
                // Rank badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? const Color(0xFF001F3F)
                        : const Color(0xFFE8EDF5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            rank <= 3 ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // City icon + name
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001F3F).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city_rounded,
                      color: Color(0xFF001F3F), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.city,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000613),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Vote count label ───────────────────────────────────────
            Text(
              'صوّت ${stats.voted} من ${stats.total}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // ── Progress bar ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.rate,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),

            // ── Sub-labels: voted vs not voted ─────────────────────────
            Row(
              children: [
                _dot(Colors.green),
                const SizedBox(width: 4),
                Text('صوّتوا: ${stats.voted}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(width: 14),
                _dot(const Color(0xFFE2E8F0)),
                const SizedBox(width: 4),
                Text('لم يصوّتوا: ${stats.notVoted}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int totalVoters;
  final int totalVoted;
  final double overallRate;

  const _SummaryCard({
    required this.totalVoters,
    required this.totalVoted,
    required this.overallRate,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (overallRate * 100).toStringAsFixed(1);

    return Container(
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 22),
              SizedBox(width: 10),
              Text(
                'الإجمالي العام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Three stat boxes
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  label: 'إجمالي الناخبين',
                  value: '$totalVoters',
                  icon: Icons.people_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  label: 'صوّتوا',
                  value: '$totalVoted',
                  icon: Icons.how_to_vote_rounded,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  label: 'لم يصوّتوا',
                  value: '${totalVoters - totalVoted}',
                  icon: Icons.pending_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overall progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('نسبة المشاركة الإجمالية',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallRate,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Icon(icon,
              color: highlight ? Colors.white : Colors.white54, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
