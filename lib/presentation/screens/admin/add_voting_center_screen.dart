import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AddVotingCenterScreen extends StatelessWidget {
  const AddVotingCenterScreen({super.key});

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
            child: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
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
              'إضافة مركز اقتراع',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل بيانات المركز الجديد بدقة لضمان نزاهة العملية الانتخابية',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            // Form Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildTextField(context, 'اسم المركز', 'مثال: مدرسة النهضة الثانوية'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(context, 'المنطقة الجغرافية', ['منطقة الرياض', 'منطقة مكة المكرمة', 'المنطقة الشرقية']),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(context, 'عدد منصات الاقتراع', '00', icon: Icons.how_to_vote),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(context, 'العنوان بالتفصيل', 'أدخل العنوان بدقة...', maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Map Section Placeholder
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: AssetImage('assets/images/image_6.jpg'), // Placeholder map
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primaryContainer.withOpacity(0.8), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Verification & Submission
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
                        Text('تحقق من البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('سيتم توثيق هذا المركز كوجهة رسمية للناخبين', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_task),
                    label: const Text('تأكيد الإضافة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String hint, {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.onSurfaceVariant) : null,
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
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {},
          hint: const Text('اختر المنطقة'),
        ),
      ],
    );
  }
}
