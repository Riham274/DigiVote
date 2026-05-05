import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';

class AddCandidateScreen extends StatefulWidget {
  const AddCandidateScreen({super.key});

  @override
  State<AddCandidateScreen> createState() => _AddCandidateScreenState();
}

class _AddCandidateScreenState extends State<AddCandidateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameEnController     = TextEditingController();
  final _nameArController     = TextEditingController();
  final _dobController        = TextEditingController();
  final _districtController   = TextEditingController();
  final _qualController       = TextEditingController();
  final _expController        = TextEditingController();
  final _descController       = TextEditingController();
  final _goalsController      = TextEditingController();
  final _imageController      = TextEditingController();

  String? _affiliation;
  bool _isSaving = false;

  static const List<String> _affiliations = [
    'مستقل',
    'تحالف العدالة',
    'كتلة البناء',
    'تيار الإصلاح',
    'الحزب الوطني',
    'أخرى',
  ];

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _dobController.dispose();
    _districtController.dispose();
    _qualController.dispose();
    _expController.dispose();
    _descController.dispose();
    _goalsController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final goals = _goalsController.text
          .split(RegExp(r'[،,\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('candidates').add({
        'name':           _nameEnController.text.trim(),
        'name_ar':        _nameArController.text.trim(),
        'date_of_birth':  _dobController.text.trim(),
        'district':       _districtController.text.trim(),
        'qualification':  _qualController.text.trim(),
        'experience':     _expController.text.trim(),
        'description':    _descController.text.trim(),
        'affiliation':    _affiliation ?? '',
        'goals':          goals,
        'image':          _imageController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة المرشح بنجاح ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
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
              child: Chip(
                label: Text('ADMIN PANEL',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                backgroundColor: AppColors.primaryContainer,
                avatar: CircleAvatar(
                    backgroundColor: Colors.green, radius: 4),
                padding: EdgeInsets.zero,
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
                  'إضافة مرشح جديد',
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
                  'يرجى ملء كافة البيانات المطلوبة بدقة لضمان نزاهة وشفافية العملية الانتخابية.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // ── Section: Basic Info ──────────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'الاسم بالعربية *',
                    hint: 'أحمد محمد العمري',
                    controller: _nameArController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الاسم بالإنجليزية *',
                    hint: 'Ahmad Mohammad Al-Omari',
                    controller: _nameEnController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'تاريخ الميلاد',
                    hint: '1980-05-15',
                    controller: _dobController,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الدائرة الانتخابية *',
                    hint: 'دائرة العاصمة الأولى',
                    controller: _districtController,
                    validator: _required,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Professional Info ───────────────────────────
                _sectionCard(children: [
                  _dropdownField(
                    label: 'الانتماء السياسي *',
                    hint: 'اختر الحزب أو التيار',
                    items: _affiliations,
                    value: _affiliation,
                    onChanged: (v) => setState(() => _affiliation = v),
                    validator: (v) =>
                        v == null ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'المؤهل العلمي *',
                    hint: 'بكالوريوس علوم سياسية',
                    controller: _qualController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'سنوات الخبرة',
                    hint: '15 سنة في العمل البرلماني',
                    controller: _expController,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Bio & Goals ─────────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'نبذة تعريفية *',
                    hint: 'اكتب نبذة مختصرة عن المرشح...',
                    controller: _descController,
                    maxLines: 4,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الأهداف الانتخابية',
                    hint:
                        'اكتب كل هدف في سطر منفصل أو افصل بين الأهداف بفاصلة',
                    controller: _goalsController,
                    maxLines: 4,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Image URL ───────────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'رابط صورة المرشح',
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
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تحقق من البيانات قبل الحفظ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            SizedBox(height: 4),
                            Text(
                                'بصفتك مسؤولاً، إدراج بيانات المرشح يُعدّ وثيقة رسمية.',
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
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ المرشح'),
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
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
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
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F6F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
          hint: Text(hint,
              style: const TextStyle(color: Color(0xFFB0B7C3))),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;
}
