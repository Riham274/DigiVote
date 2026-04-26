import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class CandidateDetailsScreen extends StatelessWidget {
  const CandidateDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: AppColors.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/image_10.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceContainerHigh),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withOpacity(0.8),
                          AppColors.surface,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المرشح الوطني 1',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'الدائرة الانتخابية الأولى',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryContainer,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(context, '15+', 'سنوات خبرة'),
                      ),
                      Container(width: 1, height: 40, color: AppColors.outlineVariant),
                      Expanded(
                        child: _buildStatItem(context, 'دكتوراه', 'المؤهل العلمي'),
                      ),
                      Container(width: 1, height: 40, color: AppColors.outlineVariant),
                      Expanded(
                        child: _buildStatItem(context, 'مستقل', 'الانتماء'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'السيرة الذاتية',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خبير في السياسات العامة والاقتصاد، شغل عدة مناصب استشارية في تطوير البنية التحتية. يسعى لتمثيل المواطنين بصدق وشفافية لضمان مستقبل أفضل.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'البرنامج الانتخابي والأهداف',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildGoalItem(context, 'تحسين جودة الخدمات الصحية والتعليمية', Icons.health_and_safety_outlined),
                  _buildGoalItem(context, 'تطوير البنية التحتية والمشاريع الوطنية', Icons.construction_outlined),
                  _buildGoalItem(context, 'خلق فرص عمل للشباب ودعم المشاريع الصغيرة', Icons.work_outline),
                  _buildGoalItem(context, 'تعزيز الشفافية ومكافحة الفساد المالي', Icons.shield_outlined),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoalItem(BuildContext context, String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

