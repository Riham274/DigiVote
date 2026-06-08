import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/models/candidate_model.dart';

// ─── State enums ──────────────────────────────────────────────────────────────

enum _DeviceStatus { checking, authorized, denied }

enum _TokenStatus { loading, available, exhausted }

enum _VoteState { idle, submitting, success }

// ─────────────────────────────────────────────────────────────────────────────

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  _DeviceStatus _deviceStatus = _DeviceStatus.checking;
  _TokenStatus  _tokenStatus  = _TokenStatus.loading;
  _VoteState    _voteState    = _VoteState.idle;
  bool          _alreadyVoted = false;

  String? _tokenDocId;
  String? _tokenValue;
  Candidate? _selected;

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _checkDevice();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ── TTS ──────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // ── Device check ──────────────────────────────────────────────────────────

  Future<String> _getDeviceId() async {
    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      final info = await plugin.webBrowserInfo;
      return '${info.browserName.name}-${info.platform}';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return (await plugin.androidInfo).id;
      case TargetPlatform.iOS:
        return (await plugin.iosInfo).identifierForVendor ?? '';
      case TargetPlatform.windows:
        return (await plugin.windowsInfo).deviceId;
      case TargetPlatform.macOS:
        return (await plugin.macOsInfo).systemGUID ?? '';
      case TargetPlatform.linux:
        return (await plugin.linuxInfo).machineId ?? '';
      default:
        return '';
    }
  }

  Future<void> _checkDevice() async {
    try {
      final deviceId = await _getDeviceId();
      debugPrint('>>> DEVICE ID: $deviceId <<<');

      final query = await FirebaseFirestore.instance
          .collection('authorized_devices')
          .where('device_id', isEqualTo: deviceId)
          .limit(1)
          .get();

      final isAuthorized = query.docs.isNotEmpty &&
          (query.docs.first.data()['is_active'] as bool? ?? false);

      if (!mounted) return;
      setState(() => _deviceStatus = isAuthorized
          ? _DeviceStatus.authorized
          : _DeviceStatus.denied);

      if (isAuthorized) {
        // Check voter's has_voted from auth state before fetching token
        final hasVoted =
            AuthStateWidget.of(context).currentUser?.hasVoted ?? false;
        if (mounted && hasVoted) {
          setState(() => _alreadyVoted = true);
          return;
        }
        await _fetchToken();
      }
    } catch (_) {
      if (mounted) setState(() => _deviceStatus = _DeviceStatus.denied);
    }
  }

  // ── Token fetch ───────────────────────────────────────────────────────────

  Future<void> _fetchToken() async {
    setState(() => _tokenStatus = _TokenStatus.loading);
    try {
      final query = await FirebaseFirestore.instance
          .collection('tokens')
          .where('used', isEqualTo: false)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isEmpty) {
        setState(() => _tokenStatus = _TokenStatus.exhausted);
        return;
      }

      final doc = query.docs.first;
      _tokenDocId = doc.id;
      // The token value — fall back to the document ID if field is absent
      _tokenValue = doc.data()['token'] as String? ?? doc.id;
      setState(() => _tokenStatus = _TokenStatus.available);
    } catch (_) {
      if (mounted) setState(() => _tokenStatus = _TokenStatus.exhausted);
    }
  }

  // ── Confirm & submit ──────────────────────────────────────────────────────

  Future<void> _onConfirmPressed() async {
    if (_selected == null) return;

    final displayName = _selected!.nameAr.isNotEmpty
        ? _selected!.nameAr
        : _selected!.name;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.how_to_vote_rounded,
                  color: Color(0xFF001F3F), size: 24),
              SizedBox(width: 10),
              Text('تأكيد التصويت',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F))),
            ],
          ),
          content: RichText(
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF1E293B), height: 1.6),
              children: [
                const TextSpan(text: 'هل أنت متأكد من تصويتك للمرشح '),
                TextSpan(
                  text: displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F)),
                ),
                const TextSpan(text: '؟'),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text('تأكيد',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    await _submitVote();
  }

  Future<void> _submitVote() async {
    setState(() => _voteState = _VoteState.submitting);

    try {
      final db = FirebaseFirestore.instance;
      final tokenRef = db.collection('tokens').doc(_tokenDocId!);
      final candidateId = _selected!.candidateId; // e.g. 'cand_001'
      final tokenVal = _tokenValue!;
      final nationalId =
          AuthStateWidget.of(context).currentUser?.nationalId ?? '';

      // Transaction: re-verify token is still unused, then record vote atomically
      await db.runTransaction((tx) async {
        final tokenSnap = await tx.get(tokenRef);
        if (tokenSnap.data()?['used'] == true) {
          throw Exception('token_already_used');
        }

        // Anonymous vote — only candidate_id and token, no personal data
        tx.set(db.collection('votes').doc(), {
          'candidate_id': candidateId,
          'token': tokenVal,
        });

        tx.update(tokenRef, {'used': true});

        // Mark voter as having voted
        if (nationalId.isNotEmpty) {
          tx.update(
            db.collection('voters').doc(nationalId),
            {'has_voted': true},
          );
        }
      });

      if (!mounted) return;
      setState(() => _voteState = _VoteState.success);

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      AuthStateWidget.of(context).logout();
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _voteState = _VoteState.idle);

      final msg = e.toString().contains('token_already_used')
          ? 'تم استخدام هذا الرمز مسبقاً، يرجى التواصل مع المسؤول'
          : 'حدث خطأ أثناء حفظ التصويت، حاول مجدداً';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: switch (_deviceStatus) {
        _DeviceStatus.checking => _buildChecking(),
        _DeviceStatus.denied => _buildDenied(),
        _DeviceStatus.authorized => _alreadyVoted
            ? _buildAlreadyVoted()
            : switch (_tokenStatus) {
                _TokenStatus.loading => _buildTokenLoading(),
                _TokenStatus.exhausted => _buildTokenExhausted(),
                _TokenStatus.available => switch (_voteState) {
                    _VoteState.success => _buildSuccess(),
                    _VoteState.submitting => _buildSubmitting(),
                    _VoteState.idle => _buildVoting(),
                  },
              },
      },
    );
  }

  // ── Checking device ───────────────────────────────────────────────────────

  Widget _buildChecking() => _darkLoadingScreen(
        'جارٍ التحقق من صلاحية الجهاز...',
        color: Colors.white,
      );

  // ── Fetching token ────────────────────────────────────────────────────────

  Widget _buildTokenLoading() => _darkLoadingScreen(
        'جارٍ تجهيز جلسة التصويت...',
        color: Colors.white,
      );

  Widget _darkLoadingScreen(String message, {Color color = Colors.white}) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF001F3F)),
            const SizedBox(height: 24),
            Text(message,
                style:
                    const TextStyle(color: Color(0xFF001F3F), fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── Denied ────────────────────────────────────────────────────────────────

  Widget _buildDenied() => _statusScreen(
        icon: Icons.how_to_vote_rounded,
        iconColor: Colors.white60,
        iconBg: Colors.white.withOpacity(0.07),
        title: 'التصويت متاح فقط من داخل مركز الاقتراع',
        titleColor: Colors.white,
        message:
            'يمكنك التصويت عبر الجهاز المخصص في أقرب مركز اقتراع معتمد.\n\nتوجّه إلى المركز وأبرز هويتك للموظف المختص.',
      );

  // ── Already voted ─────────────────────────────────────────────────────────

  Widget _buildAlreadyVoted() {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_vote_rounded,
                      size: 72, color: Colors.amber),
                ),
                const SizedBox(height: 32),
                const Text(
                  'لقد صوّتت مسبقاً',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سبق أن شاركت في هذه الانتخابات.\nشكراً لك على مشاركتك في العملية الديمقراطية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white54),
                  label: const Text('العودة',
                      style: TextStyle(color: Colors.white54)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── No tokens ─────────────────────────────────────────────────────────────

  Widget _buildTokenExhausted() => _statusScreen(
        icon: Icons.token_rounded,
        iconColor: Colors.orangeAccent,
        iconBg: Colors.orange.withOpacity(0.12),
        title: 'لا توجد رموز متاحة',
        titleColor: Colors.orangeAccent,
        message:
            'لا توجد رموز تصويت متاحة حالياً،\nيرجى التواصل مع المسؤول',
      );

  // ── Shared status screen ──────────────────────────────────────────────────

  Widget _statusScreen({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Color titleColor,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration:
                      BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, size: 72, color: iconColor),
                ),
                const SizedBox(height: 32),
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 15, height: 1.7)),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white54),
                  label: const Text('العودة',
                      style: TextStyle(color: Colors.white54)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Submitting ────────────────────────────────────────────────────────────

  Widget _buildSubmitting() {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF001F3F)),
            SizedBox(height: 24),
            Text('جارٍ تسجيل تصويتك...',
                style: TextStyle(
                    color: Color(0xFF001F3F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Success ───────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 80, color: Colors.greenAccent),
                ),
                const SizedBox(height: 32),
                const Text(
                  'تم التصويت بنجاح!',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                const Text(
                  'شكراً لك على تصويتك،\nتمت العملية بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 16, height: 1.7),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      color: Colors.white30, strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                const Text('سيتم تسجيل الخروج تلقائياً...',
                    style:
                        TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Voting screen ─────────────────────────────────────────────────────────

  Widget _buildVoting() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('التصويت الإلكتروني',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded,
              color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000613), Color(0xFF001F3F)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF001F3F).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.how_to_vote_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختر مرشحك',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      SizedBox(height: 4),
                      Text(
                          'اختر مرشحاً واحداً فقط ثم اضغط تأكيد التصويت',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Candidates list ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('candidates')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF001F3F)));
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('تعذّر تحميل المرشحين',
                          style: TextStyle(color: Colors.grey)));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد مرشحون حتى الآن',
                          style: TextStyle(color: Colors.grey)));
                }

                final candidates = docs
                    .map((d) => Candidate.fromFirestore(
                        d.id, d.data() as Map<String, dynamic>))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CandidateTile(
                    candidate: candidates[i],
                    isSelected: _selected?.id == candidates[i].id,
                    onSelect: () =>
                        setState(() => _selected = candidates[i]),
                    onSpeak: () {
                      final ar = candidates[i].nameAr;
                      final en = candidates[i].name;
                      _speak(ar.isNotEmpty ? '$ar، $en' : en);
                    },
                  ),
                );
              },
            ),
          ),

          // ── Confirm button ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _selected != null ? _onConfirmPressed : null,
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: const Text('تأكيد التصويت',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Candidate tile ───────────────────────────────────────────────────────────

class _CandidateTile extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onSpeak;

  const _CandidateTile({
    required this.candidate,
    required this.isSelected,
    required this.onSelect,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        candidate.nameAr.isNotEmpty ? candidate.nameAr : candidate.name;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF001F3F).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF001F3F)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio
            Radio<String>(
              value: candidate.id,
              groupValue: isSelected ? candidate.id : null,
              onChanged: (_) => onSelect(),
              activeColor: const Color(0xFF001F3F),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),

            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                width: 56,
                height: 56,
                child: candidate.image.isNotEmpty
                    ? Image.network(
                        candidate.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(),
                        loadingBuilder: (_, child, prog) =>
                            prog == null ? child : _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF001F3F)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (candidate.district.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      candidate.district,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            // Speaker
            IconButton(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
              color: const Color(0xFF001F3F).withOpacity(0.5),
              iconSize: 22,
              tooltip: 'استمع للاسم',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFFE8EDF2),
        child:
            const Icon(Icons.person, color: Color(0xFF94A3B8), size: 28),
      );
}
