import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AddCandidateScreen extends StatelessWidget {
  const AddCandidateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVote', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              label: Text('ADMIN PANEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppColors.primaryContainer,
              avatar: CircleAvatar(backgroundColor: Colors.green, radius: 4),
              padding: EdgeInsets.zero,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة مرشح جديد',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(width: 64, height: 4, color: AppColors.primary, margin: const EdgeInsets.only(bottom: 24)),
            Text(
              'يرجى ملء كافة البيانات المطلوبة بدقة لضمان نزاهة وشفافية العملية الانتخابية داخل نظام UniVote السيادي.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            // Primary Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildTextField(context, 'الاسم الكامل', 'أدخل الاسم الرباعي للمرشح'),
                  const SizedBox(height: 24),
                  _buildTextField(context, 'الرقم الوطني', '000-000-000-000'),
                  const SizedBox(height: 24),
                  _buildDropdownField(context, 'الانتماء السياسي', ['مستقل', 'تحالف العدالة', 'كتلة البناء', 'تيار الإصلاح']),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Media & Bio
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تحميل صورة المرشح', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: AppColors.onPrimary),
                              SizedBox(height: 8),
                              Text('رفع الصورة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نبذة مختصرة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'اكتب نبذة عن التاريخ المهني والأهداف الانتخابية للمرشح...',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Verification Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.verified_user, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تحقق من البيانات قبل الحفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 8),
                        Text('بصفتك مسؤولاً، فإن إدراج بيانات المرشح يعد وثيقة رسمية. تأكد من أن جميع المعلومات والروابط والصور المرفقة تتوافق مع المعايير القانونية.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء العملية', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المرشح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context, String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {},
          hint: const Text('اختر الحزب أو التيار السياسي'),
        ),
      ],
    );
  }
}
