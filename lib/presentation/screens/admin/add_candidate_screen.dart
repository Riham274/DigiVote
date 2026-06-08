import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/image_upload_service.dart';

class AddCandidateScreen extends StatefulWidget {
  const AddCandidateScreen({super.key});

  @override
  State<AddCandidateScreen> createState() => _AddCandidateScreenState();
}

class _AddCandidateScreenState extends State<AddCandidateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _candidateIdController = TextEditingController();
  final _nameArController      = TextEditingController();
  final _nameEnController      = TextEditingController();
  final _dobController         = TextEditingController();
  final _qualController        = TextEditingController();
  final _expController         = TextEditingController();
  final _descController        = TextEditingController();
  final _goalsController       = TextEditingController();

  bool _isSaving = false;
  String _statusMsg = 'حفظ المرشح';

  // Cross-platform image state
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _candidateIdController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _dobController.dispose();
    _qualController.dispose();
    _expController.dispose();
    _descController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedXFile = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusMsg = 'جارٍ رفع الصورة...';
    });

    try {
      String imageUrl = '';

      if (_pickedXFile != null && _imageBytes != null) {
        final url = await ImageUploadService.uploadBytes(_imageBytes!);
        if (url == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل رفع الصورة، تحقق من الاتصال وحاول مجدداً'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _isSaving = false;
            _statusMsg = 'حفظ المرشح';
          });
          return;
        }
        imageUrl = url;
      }

      setState(() => _statusMsg = 'جارٍ الحفظ...');

      final goals = _goalsController.text
          .split(RegExp(r'[،,\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final candidateId = _candidateIdController.text.trim();
      await FirebaseFirestore.instance
          .collection('candidates')
          .doc(candidateId)
          .set({
        'candidate_id':  candidateId,
        'name':          _nameEnController.text.trim(),
        'name_ar':       _nameArController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'qualification': _qualController.text.trim(),
        'experience':    _expController.text.trim(),
        'description':   _descController.text.trim(),
        'goals':         goals,
        'image':         imageUrl,
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
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMsg = 'حفظ المرشح';
        });
      }
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
                avatar:
                    CircleAvatar(backgroundColor: Colors.green, radius: 4),
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
                    label: 'رقم المرشح *',
                    hint: 'cand_001',
                    controller: _candidateIdController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الاسم بالعربي *',
                    hint: 'أحمد محمد العمري',
                    controller: _nameArController,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الاسم الكامل *',
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
                ]),
                const SizedBox(height: 24),

                // ── Section: Qualifications ──────────────────────────────
                _sectionCard(children: [
                  _field(
                    label: 'المؤهل العلمي',
                    hint: 'بكالوريوس علوم سياسية',
                    controller: _qualController,
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
                    label: 'الوصف / السيرة الذاتية *',
                    hint: 'اكتب نبذة مختصرة عن المرشح...',
                    controller: _descController,
                    maxLines: 4,
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'الأهداف',
                    hint:
                        'اكتب كل هدف في سطر منفصل أو افصل بين الأهداف بفاصلة',
                    controller: _goalsController,
                    maxLines: 4,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Section: Image Picker ────────────────────────────────
                _sectionCard(children: [
                  const Text(
                    'صورة المرشح',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePicker(),
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
                      label: Text(_isSaving ? _statusMsg : 'حفظ المرشح'),
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

  // ── Cross-platform image picker widget ────────────────────────────────────

  Widget _buildImagePicker() {
    final hasImage = _imageBytes != null;
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? AppColors.primaryContainer
                : const Color(0xFFCDD5E0),
            width: 2,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'اضغط لتغيير الصورة',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 52, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'اختر صورة المرشح',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط لاختيار صورة من المعرض',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;
}
