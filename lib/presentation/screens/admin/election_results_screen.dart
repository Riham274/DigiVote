import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _CandidateResult {
  final String candidateId;
  final String candidateName;
  final int voteCount;

  const _CandidateResult({
    required this.candidateId,
    required this.candidateName,
    required this.voteCount,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ElectionResultsScreen extends StatefulWidget {
  const ElectionResultsScreen({super.key});

  @override
  State<ElectionResultsScreen> createState() => _ElectionResultsScreenState();
}

class _ElectionResultsScreenState extends State<ElectionResultsScreen> {
  late Future<List<_CandidateResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchResults();
  }

  void _refresh() => setState(() => _resultsFuture = _fetchResults());

  Future<List<_CandidateResult>> _fetchResults() async {
    final db = FirebaseFirestore.instance;

    // 1. Fetch all candidates to build an ID → name lookup
    final candidatesSnap = await db.collection('candidates').get();
    final Map<String, String> nameById = {};
    for (final doc in candidatesSnap.docs) {
      final data = doc.data();
      final candidateId = data['candidate_id'] as String? ?? doc.id;
      final name =
          data['name_ar'] as String? ?? data['name'] as String? ?? candidateId;
      // Index by both the field value and the doc ID
      nameById[candidateId] = name;
      nameById[doc.id] = name;
    }

    // 2. Fetch all votes and tally by candidate_id
    final votesSnap = await db.collection('votes').get();
    final Map<String, int> voteCounts = {};
    for (final doc in votesSnap.docs) {
      final data = doc.data();
      final candidateId =
          data['candidate_id'] as String? ?? data['candidateId'] as String? ?? '';
      if (candidateId.isEmpty) continue;
      voteCounts[candidateId] = (voteCounts[candidateId] ?? 0) + 1;
    }

    // 3. Build result list
    final results = voteCounts.entries.map((e) {
      final id = e.key;
      return _CandidateResult(
        candidateId: id,
        candidateName: nameById[id] ?? id,
        voteCount: e.value,
      );
    }).toList();

    // 4. Sort by votes descending
    results.sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'نتائج الانتخابات',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
              onPressed: _refresh,
            ),
          ],
        ),
        body: FutureBuilder<List<_CandidateResult>>(
          future: _resultsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('جارٍ تحميل النتائج...',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              );
            }

            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.grey, size: 48),
                    const SizedBox(height: 12),
                    const Text('تعذّر تحميل النتائج',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              );
            }

            final results = snap.data ?? [];

            if (results.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.how_to_vote_outlined,
                        color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text('لا توجد أصوات مسجّلة بعد',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      'ستظهر النتائج هنا بعد بدء التصويت',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            final totalVotes =
                results.fold(0, (sum, r) => sum + r.voteCount);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Total votes summary ──────────────────────────────
                  _buildTotalCard(totalVotes, results.length),
                  const SizedBox(height: 24),

                  // ── Section header ───────────────────────────────────
                  const Row(
                    children: [
                      Icon(Icons.leaderboard_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ترتيب المرشحين',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Results list ─────────────────────────────────────
                  Container(
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
                    child: Column(
                      children: results.asMap().entries.map((entry) {
                        final rank = entry.key;
                        final result = entry.value;
                        final isLast = rank == results.length - 1;
                        return _buildResultRow(
                            rank, result, totalVotes, isLast);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Total votes card ──────────────────────────────────────────────────────

  Widget _buildTotalCard(int totalVotes, int candidateCount) {
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
            blurRadius: 16,
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
                  'إجمالي الأصوات المسجّلة',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalVotes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'صوت على $candidateCount مرشح',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_vote_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  // ── Individual result row ─────────────────────────────────────────────────

  Widget _buildResultRow(
    int rank,
    _CandidateResult result,
    int totalVotes,
    bool isLast,
  ) {
    final pct = totalVotes == 0 ? 0.0 : result.voteCount / totalVotes;
    final pctStr = '${(pct * 100).toStringAsFixed(1)}%';

    final medal = switch (rank) {
      0 => '🥇',
      1 => '🥈',
      2 => '🥉',
      _ => null,
    };

    final isWinner = rank == 0;
    final rankColor = switch (rank) {
      0 => const Color(0xFFEAB308),
      1 => const Color(0xFF94A3B8),
      2 => const Color(0xFFCD7F32),
      _ => const Color(0xFFCBD5E1),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: medal != null
                    ? Text(medal,
                        style: const TextStyle(fontSize: 20))
                    : Text(
                        '#${rank + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: rankColor,
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Name + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.candidateName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWinner ? 15 : 14,
                              color: isWinner
                                  ? AppColors.primary
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.voteCount} صوت',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isWinner
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWinner
                              ? const Color(0xFF10B981)
                              : AppColors.primaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pctStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isWinner
                            ? const Color(0xFF10B981)
                            : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, indent: 74, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
