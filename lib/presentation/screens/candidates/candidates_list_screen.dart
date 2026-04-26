import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'candidate_details_screen.dart';

class CandidatesListScreen extends StatelessWidget {
  const CandidatesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
              child: const Icon(Icons.how_to_vote, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('UniVote', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Text(
              'المرشحون',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(width: 48, height: 4, color: AppColors.primaryContainer, margin: const EdgeInsets.only(bottom: 8)),
            const Text('تعرف على المرشحين وبرامجهم الانتخابية', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 32),

            // Candidates List
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCandidateCard(context, 'د. أحمد المنصور', 'متخصص في الإدارة الاستراتيجية ويهدف لتطوير المنظومة التعليمية الرقمية.', 'assets/images/image_10.jpg'),
                const SizedBox(height: 16),
                _buildCandidateCard(context, 'أ. سارة العتيبي', 'رائدة أعمال تسعى لتمكين الشباب وتعزيز فرص الابتكار والبحث العلمي.', 'assets/images/image_11.jpg'),
                const SizedBox(height: 16),
                _buildCandidateCard(context, 'م. خالد الراشد', 'خبير تقني يركز على التحول الذكي وتحسين الخدمات الحكومية الرقمية.', 'assets/images/image_12.jpg'),
                const SizedBox(height: 16),
                _buildCandidateCard(context, 'د. نورة السعيد', 'باحثة قانونية تهدف لتعزيز الشفافية والعدالة في الأنظمة التشريعية.', 'assets/images/image_13.jpg'),
              ],
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 100), // Padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, String name, String bio, String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CandidateDetailsScreen()));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceContainerLow, width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.person, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(bio, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

}
