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

  final _nationalIdCtrl    = TextEditingController(); // used as document ID
  final _candidateIdCtrl   = TextEditingController();
  final _nameCtrl          = TextEditingController();
  final _ageCtrl           = TextEditingController();
  final _qualCtrl          = TextEditingController();
  final _expCtrl           = TextEditingController();
  final _bioCtrl           = TextEditingController();
  final _achievementsCtrl  = TextEditingController();
  final _sloganCtrl        = TextEditingController();

  // Dynamic goals list
  final List<TextEditingController> _goalCtrls = [TextEditingController()];

  bool _isSaving   = false;
  String _statusMsg = 'حفظ المرشح';

  // Image
  XFile?     _pickedXFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Auto-generate a candidate ID that the admin can override
    _candidateIdCtrl.text =
        'cand_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  @override
  void dispose() {
    _nationalIdCtrl.dispose();
    _candidateIdCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _qualCtrl.dispose();
    _expCtrl.dispose();
    _bioCtrl.dispose();
    _achievementsCtrl.dispose();
    _sloganCtrl.dispose();
    for (final c in _goalCtrls) c.dispose();
    super.dispose();
  }

  void _addGoal() =>
      setState(() => _goalCtrls.add(TextEditingController()));

  void _removeGoal(int index) {
    if (_goalCtrls.length <= 1) return;
    _goalCtrls[index].dispose();
    setState(() => _goalCtrls.removeAt(index));
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
      _imageBytes  = bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nationalIdCtrl.text.trim().isEmpty) return;

    setState(() {
      _isSaving  = true;
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
            _isSaving  = false;
            _statusMsg = 'حفظ المرشح';
          });
          return;
        }
        imageUrl = url;
      }

      setState(() => _statusMsg = 'جارٍ الحفظ...');

      final goals = _goalCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final nationalId  = _nationalIdCtrl.text.trim();
      final candidateId = _candidateIdCtrl.text.trim();
      await FirebaseFirestore.instance
          .collection('candidates')
          .doc(nationalId)       // document ID = national ID
          .set({
        'national_id':   nationalId,
        'candidate_id':  candidateId,
        'name':          _nameCtrl.text.trim(),
        'age':           int.tryParse(_ageCtrl.text.trim()) ?? 0,
        'qualification': _qualCtrl.text.trim(),
        'experience':    _expCtrl.text.trim(),
        'bio':           _bioCtrl.text.trim(),
        'achievements':  _achievementsCtrl.text.trim(),
        'slogan':        _sloganCtrl.text.trim(),
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
    } catch (_) {
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
          _isSaving  = false;
          _statusMsg = 'حفظ المرشح';
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 35),
              const SizedBox(width: 6),
              const Text(
                'DigiVote',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: AppColors.primaryContainer),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text('ADMIN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                backgroundColor: AppColors.primaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                const Text(
                  'إضافة مرشح جديد',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                    width: 64,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2))),
                const Text(
                  'يرجى ملء كافة البيانات بدقة لضمان نزاهة العملية الانتخابية.',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // ── Section 1: Identity ──────────────────────────────────
                _card([
                  _fieldLabel('رقم الهوية الوطنية * (يُستخدم كمعرّف في قاعدة البيانات)'),
                  _textField(
                    controller: _nationalIdCtrl,
                    hint: '1020304050',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                      if (int.tryParse(v.trim()) == null) return 'أدخل أرقاماً فقط';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('رقم المرشح *'),
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _candidateIdCtrl,
                          hint: 'cand_001',
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'توليد رقم تلقائي',
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.primaryContainer),
                        onPressed: () => setState(() {
                          _candidateIdCtrl.text =
                              'cand_${DateTime.now().millisecondsSinceEpoch % 100000}';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('الاسم الكامل *'),
                  _textField(
                    controller: _nameCtrl,
                    hint: 'أحمد محمد العمري',
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('العمر'),
                            _textField(
                              controller: _ageCtrl,
                              hint: '45',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('المؤهل العلمي'),
                            _textField(
                              controller: _qualCtrl,
                              hint: 'بكالوريوس علوم سياسية',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Section 2: Professional ──────────────────────────────
                _card([
                  _fieldLabel('الخبرة'),
                  _textField(
                    controller: _expCtrl,
                    hint: '15 سنة في العمل البرلماني',
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('نبذة شخصية'),
                  _textField(
                    controller: _bioCtrl,
                    hint: 'اكتب نبذة مختصرة عن المرشح...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('الإنجازات السابقة'),
                  _textField(
                    controller: _achievementsCtrl,
                    hint: 'اذكر أبرز إنجازاته...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('الشعار الانتخابي'),
                  _textField(
                    controller: _sloganCtrl,
                    hint: 'شعار المرشح...',
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Section 3: Goals ─────────────────────────────────────
                _card([
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded,
                          color: AppColors.primaryContainer, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'البرنامج الانتخابي',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._goalCtrls.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                hintText: 'هدف ${i + 1}...',
                                hintStyle:
                                    const TextStyle(color: Color(0xFFB0B7C3)),
                                filled: true,
                                fillColor: const Color(0xFFF4F6F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          if (_goalCtrls.length > 1) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded,
                                  color: Colors.redAccent, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeGoal(i),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _isSaving ? null : _addGoal,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primaryContainer),
                    label: const Text(
                      'إضافة هدف جديد',
                      style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Section 4: Image ─────────────────────────────────────
                _card([
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
                const SizedBox(height: 28),

                // ── Verification banner ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تحقق من البيانات قبل الحفظ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
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
                const SizedBox(height: 20),

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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    final hasImage = _imageBytes != null;
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        height: 180,
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
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'اختر صورة المرشح',
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط لاختيار من المعرض',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;
}
