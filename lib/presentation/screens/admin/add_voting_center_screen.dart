import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';

class AddVotingCenterScreen extends StatefulWidget {
  const AddVotingCenterScreen({super.key});

  @override
  State<AddVotingCenterScreen> createState() => _AddVotingCenterScreenState();
}

class _AddVotingCenterScreenState extends State<AddVotingCenterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController         = TextEditingController();
  final _cityController         = TextEditingController();
  final _addressController      = TextEditingController();
  final _latController          = TextEditingController();
  final _lngController          = TextEditingController();
  final _waitingTimeController  = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _imageController        = TextEditingController();

  String _status = 'مفتوح';
  bool _isSaving = false;

  static const List<String> _statusOptions = ['مفتوح', 'مغلق', 'قريباً'];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _waitingTimeController.dispose();
    _openingHoursController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('voting_center').add({
        'center_name':    _nameController.text.trim(),
        'city':           _cityController.text.trim(),
        'address':        _addressController.text.trim(),
        'latitude':       double.tryParse(_latController.text.trim()) ?? 0.0,
        'longitude':      double.tryParse(_lngController.text.trim()) ?? 0.0,
        'status':         _status,
        'waiting_time':   _waitingTimeController.text.trim(),
        'opening_hours':  _openingHoursController.text.trim(),
        'image':          _imageController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة مركز الاقتراع بنجاح ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء الحفظ، حاول مجدداً'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text('UniVote',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryContainer)),
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
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                Container(
                    width: 64,
                    height: 4,
                    color: AppColors.primary,
                    margin: const EdgeInsets.only(bottom: 24)),
                Text(
                  'أدخل بيانات المركز الجديد بدقة لضمان نزاهة العملية الانتخابية.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // ── Section: Basic Info ──────────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'اسم المركز *',
                    hint: 'مدرسة النهضة الثانوية',
                    controller: _nameController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'المدينة *',
                          hint: 'عمّان',
                          controller: _cityController,
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dropdownField(
                          label: 'الحالة',
                          value: _status,
                          items: _statusOptions,
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'مفتوح'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'العنوان التفصيلي *',
                    hint: 'شارع الملك عبدالله، الدوار الثالث',
                    controller: _addressController,
                    maxLines: 2,
                    validator: _required,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Location ────────────────────────────────────
                _sectionCard(children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primaryContainer, size: 20),
                      const SizedBox(width: 8),
                      Text('الإحداثيات الجغرافية',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'خط العرض (Latitude)',
                          hint: '31.9539',
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _validateCoord,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _field(
                          label: 'خط الطول (Longitude)',
                          hint: '35.9106',
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _validateCoord,
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Details ─────────────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'ساعات العمل',
                    hint: '8:00 ص - 5:00 م',
                    controller: _openingHoursController,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'وقت الانتظار الحالي',
                    hint: '15 دقيقة',
                    controller: _waitingTimeController,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'رابط صورة المركز',
                    hint: 'https://...',
                    controller: _imageController,
                    keyboardType: TextInputType.url,
                  ),
                ]),
                const SizedBox(height: 32),

                // ── Verification banner ──────────────────────────────────
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
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.verified_user,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تحقق من البيانات',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            SizedBox(height: 4),
                            Text(
                                'سيتم توثيق هذا المركز كوجهة رسمية للناخبين.',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Actions ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_task_rounded),
                      label: Text(
                          _isSaving ? 'جارٍ الحفظ...' : 'تأكيد الإضافة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
            filled: true,
            fillColor: const Color(0xFFF4F6F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F6F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;

  String? _validateCoord(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (double.tryParse(v.trim()) == null) return 'أدخل رقماً صحيحاً';
    return null;
  }
}
