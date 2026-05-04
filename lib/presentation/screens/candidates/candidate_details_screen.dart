import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/candidate_model.dart';

class CandidateDetailsScreen extends StatelessWidget {
  final Candidate candidate;
  const CandidateDetailsScreen({super.key, required this.candidate});

  // Rotating icon set for goals
  static const List<IconData> _goalIcons = [
    Icons.health_and_safety_outlined,
    Icons.construction_outlined,
    Icons.work_outline,
    Icons.shield_outlined,
    Icons.school_outlined,
    Icons.eco_outlined,
    Icons.people_outline,
    Icons.star_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          slivers: [
            // ── Hero image ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              backgroundColor: AppColors.primaryContainer,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    candidate.image.isNotEmpty
                        ? Image.network(
                            candidate.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _imageFallback(),
                          )
                        : _imageFallback(),
                    // Gradient fade to surface
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.surface.withOpacity(0.6),
                            AppColors.surface,
                          ],
                          stops: const [0.45, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      candidate.name,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // District badge
                    if (candidate.district.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryContainer,
                              AppColors.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 15, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              candidate.district,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // ── Three info boxes ──────────────────────────────────
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _infoBox(
                              context,
                              value: candidate.experience,
                              label: 'سنوات الخبرة',
                              icon: Icons.workspace_premium_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoBox(
                              context,
                              value: candidate.qualification,
                              label: 'المؤهل العلمي',
                              icon: Icons.school_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoBox(
                              context,
                              value: candidate.affiliation,
                              label: 'الانتماء',
                              icon: Icons.account_balance_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── السيرة الذاتية ────────────────────────────────────
                    _sectionHeader(context, 'السيرة الذاتية'),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        candidate.description.isNotEmpty
                            ? candidate.description
                            : 'لا توجد معلومات إضافية.',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── البرنامج الانتخابي والأهداف ───────────────────────
                    if (candidate.goals.isNotEmpty) ...[
                      _sectionHeader(context, 'البرنامج الانتخابي والأهداف'),
                      const SizedBox(height: 14),
                      ...candidate.goals.asMap().entries.map(
                            (entry) => _goalCard(
                              context,
                              text: entry.value,
                              icon: _goalIcons[entry.key % _goalIcons.length],
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }

  Widget _infoBox(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? value : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(BuildContext context, {required String text, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
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
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.person, size: 80, color: AppColors.onSurfaceVariant),
        ),
      );
}
