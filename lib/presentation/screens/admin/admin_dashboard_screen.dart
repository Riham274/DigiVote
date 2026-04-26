import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';
import 'add_candidate_screen.dart';
import 'add_voting_center_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () => AuthStateWidget.of(context).logout(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/image_6.jpg'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context),
            const SizedBox(height: 32),
            
            // Stats Section
            Text(
              'الإحصائيات العامة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            _buildAnalyticsSection(context),
            const SizedBox(height: 32),

            // Action Cards
            Text(
              'الإجراءات السريعة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: 'إضافة مركز',
                    subtitle: 'توسيع نطاق التغطية',
                    icon: Icons.add_location_alt_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVotingCenterScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: 'إضافة مرشح',
                    subtitle: 'تسجيل بيانات جديد',
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFF1E293B),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCandidateScreen()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Text(
              'آخر التحديثات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final adminName = AuthStateWidget.of(context).currentUser?.name ?? 'المشرف';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مرحباً بك، $adminName',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'إليك نظرة عامة على حالة الانتخابات اليوم',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem('إجمالي المسجلين', '2,450,120', Icons.people, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatItem('المراكز النشطة', '1,204', Icons.location_on, Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('معدل الوعي الانتخابي', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 24),
              // Simple Chart Placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final heights = [40, 70, 50, 90, 60, 80, 100];
                  return Column(
                    children: [
                      Container(
                        width: 12,
                        height: heights[index].toDouble(),
                        decoration: BoxDecoration(
                          color: index == 6 ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(['ج', 'ح', 'خ', 'ر', 'ث', 'ن', 'س'][index], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        children: [
          _buildActivityItem('تم إضافة مركز جديد في مكة المكرمة', 'منذ ساعة', Icons.add_location, Colors.green),
          _buildActivityItem('تحديث بيانات المرشح فهد سليمان', 'منذ ٣ ساعات', Icons.edit_note, Colors.blue),
          _buildActivityItem('إرسال تنبيه للمراكز في المنطقة الشرقية', 'منذ ٥ ساعات', Icons.campaign, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
      subtitle: Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
    );
  }
}

