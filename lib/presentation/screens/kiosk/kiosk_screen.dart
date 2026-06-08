import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/models/candidate_model.dart';

// ─── Kiosk state machine ──────────────────────────────────────────────────────

enum _KioskState {
  welcome,       // waiting for Raspberry Pi to set status = "occupied"
  voterCheck,    // booth just became occupied — verifying voter + fetching token
  alreadyVoted,  // voter has_voted == true — show error then reset
  noTokens,      // tokens collection exhausted
  voting,        // show candidates list
  submitting,    // Firestore transaction in progress
  success,       // vote recorded — show thank-you then reset
}

// ─── Root kiosk widget ────────────────────────────────────────────────────────

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _KioskState _state = _KioskState.welcome;
  String _currentVoterId = '';
  String? _tokenDocId;
  String? _tokenValue;
  Candidate? _selected;
  List<Candidate> _candidates = [];

  // ── Services ───────────────────────────────────────────────────────────────
  StreamSubscription<DocumentSnapshot>? _boothSub;
  final FlutterTts _tts = FlutterTts();

  // ── Pulse animation (welcome screen) ───────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initPulse();
    _initTts();
    _preloadCandidates();
    _listenBooth();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _boothSub?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  void _initPulse() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _preloadCandidates() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('candidates').get();
      if (!mounted) return;
      setState(() {
        _candidates = snap.docs
            .map((d) =>
                Candidate.fromFirestore(d.id, d.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  // ── Booth status stream ────────────────────────────────────────────────────

  void _listenBooth() {
    _boothSub = FirebaseFirestore.instance
        .collection('booth_status')
        .doc('booth_001')
        .snapshots()
        .listen(_onBoothUpdate, onError: (_) {});
  }

  void _onBoothUpdate(DocumentSnapshot doc) {
    if (!doc.exists || !mounted) return;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final status = data['status'] as String? ?? 'available';
    final voterId = data['current_voter'] as String? ?? '';

    if (status == 'occupied' &&
        voterId.isNotEmpty &&
        _state == _KioskState.welcome) {
      setState(() {
        _currentVoterId = voterId;
        _selected = null;
        _state = _KioskState.voterCheck;
      });
      _checkVoterAndToken();
    } else if (status == 'available' && _state != _KioskState.welcome) {
      // Pi reset booth externally (e.g., admin override)
      _tts.stop();
      if (mounted) setState(() => _state = _KioskState.welcome);
    }
  }

  // ── Voter & token check ───────────────────────────────────────────────────

  Future<void> _checkVoterAndToken() async {
    try {
      // 1. Check has_voted flag
      final voterSnap = await FirebaseFirestore.instance
          .collection('voters')
          .doc(_currentVoterId)
          .get();

      if (!mounted) return;

      final data = voterSnap.data() as Map<String, dynamic>?;
      final hasVoted = data?['has_voted'] as bool? ?? false;

      if (hasVoted) {
        setState(() => _state = _KioskState.alreadyVoted);
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        await _resetBooth();
        return;
      }

      // 2. Grab first available token
      final tokenQuery = await FirebaseFirestore.instance
          .collection('tokens')
          .where('used', isEqualTo: false)
          .limit(1)
          .get();

      if (!mounted) return;

      if (tokenQuery.docs.isEmpty) {
        setState(() => _state = _KioskState.noTokens);
        await Future.delayed(const Duration(seconds: 5));
        if (!mounted) return;
        await _resetBooth();
        return;
      }

      _tokenDocId = tokenQuery.docs.first.id;
      _tokenValue =
          (tokenQuery.docs.first.data() as Map<String, dynamic>)['token']
                  as String? ??
              _tokenDocId;

      // 3. Reload candidates if they weren't pre-loaded
      if (_candidates.isEmpty) await _preloadCandidates();

      if (!mounted) return;
      setState(() => _state = _KioskState.voting);
    } catch (e) {
      debugPrint('Kiosk voter check error: $e');
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _state = _KioskState.welcome);
      }
    }
  }

  // ── Reset booth ───────────────────────────────────────────────────────────

  Future<void> _resetBooth() async {
    try {
      await FirebaseFirestore.instance
          .collection('booth_status')
          .doc('booth_001')
          .update({'status': 'available', 'current_voter': ''});
      // Stream will fire and switch _state back to welcome automatically
    } catch (_) {
      // Fallback: update local state even if Firestore is unreachable
      if (mounted) setState(() => _state = _KioskState.welcome);
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  Future<void> _onConfirmPressed() async {
    if (_selected == null) return;
    final displayName =
        _selected!.nameAr.isNotEmpty ? _selected!.nameAr : _selected!.name;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.how_to_vote_rounded,
                  color: Color(0xFF001F3F), size: 24),
              SizedBox(width: 10),
              Text('تأكيد التصويت',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
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
                      fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                ),
                const TextSpan(text: '؟\n\nلا يمكن التراجع عن هذا الاختيار.'),
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

  // ── Atomic vote transaction ───────────────────────────────────────────────

  Future<void> _submitVote() async {
    if (_selected == null ||
        _tokenDocId == null ||
        _tokenValue == null) return;

    setState(() => _state = _KioskState.submitting);

    try {
      final db = FirebaseFirestore.instance;
      final tokenRef = db.collection('tokens').doc(_tokenDocId!);

      await db.runTransaction((tx) async {
        // Re-verify token still unused
        final tokenSnap = await tx.get(tokenRef);
        if (tokenSnap.data()?['used'] == true) {
          throw Exception('token_already_used');
        }

        // Anonymous vote: only candidate_id + token, no personal data
        tx.set(db.collection('votes').doc(), {
          'candidate_id': _selected!.candidateId,
          'token':        _tokenValue!,
        });

        tx.update(tokenRef, {'used': true});

        tx.update(
          db.collection('voters').doc(_currentVoterId),
          {'has_voted': true},
        );
      });

      if (!mounted) return;
      await _tts.speak('شكراً لك على تصويتك');
      setState(() => _state = _KioskState.success);

      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      await _resetBooth();
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _KioskState.voting);
      final msg = e.toString().contains('token_already_used')
          ? 'خطأ في الرمز، يرجى التواصل مع المسؤول'
          : 'حدث خطأ أثناء التصويت، حاول مجدداً';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // kiosk: disable back button
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildForState(),
      ),
    );
  }

  Widget _buildForState() => switch (_state) {
        _KioskState.welcome      => _buildWelcome(),
        _KioskState.voterCheck   => _buildDark(
            icon: Icons.fingerprint_rounded,
            iconColor: Colors.blueAccent,
            message: 'جارٍ التحقق من هوية الناخب...',
          ),
        _KioskState.alreadyVoted => _buildAlreadyVoted(),
        _KioskState.noTokens     => _buildNoTokens(),
        _KioskState.voting       => _buildVoting(),
        _KioskState.submitting   => _buildDark(
            icon: Icons.how_to_vote_rounded,
            iconColor: Colors.white60,
            message: 'جارٍ تسجيل تصويتك...',
            showSpinner: true,
          ),
        _KioskState.success      => _buildSuccess(),
      };

  // ── Welcome ───────────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.how_to_vote_rounded,
                        color: Colors.white54, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'UniVote',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Pulsing circle
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          color: Colors.white54, size: 52),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title
              const Text(
                'مرحباً بك في مركز الاقتراع',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'يرجى الانتظار حتى يتم التحقق من هويتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 64),

              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white24,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'جارٍ مراقبة المنصة...',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Generic dark status screen ────────────────────────────────────────────

  Widget _buildDark({
    required IconData icon,
    required Color iconColor,
    required String message,
    bool showSpinner = false,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: iconColor),
              ),
              const SizedBox(height: 32),
              if (showSpinner)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      color: Colors.white38, strokeWidth: 2.5),
                ),
              if (showSpinner) const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 72, color: Colors.amber),
                ),
                const SizedBox(height: 32),
                const Text(
                  'لقد قمت بالتصويت مسبقاً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سجّلنا مشاركتك في هذه الانتخابات مسبقاً.\nلا يمكن التصويت مرتين.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white60, fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      color: Colors.white24, strokeWidth: 2.5),
                ),
                const SizedBox(height: 12),
                const Text('جارٍ إعادة الجهاز للحالة الاستعداد...',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── No tokens ─────────────────────────────────────────────────────────────

  Widget _buildNoTokens() {
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
                    color: Colors.orangeAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.token_rounded,
                      size: 72, color: Colors.orangeAccent),
                ),
                const SizedBox(height: 32),
                const Text(
                  'لا توجد رموز متاحة',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نفدت رموز التصويت.\nيرجى التواصل مع المسؤول.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white60, fontSize: 15, height: 1.7),
                ),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 88, color: Colors.greenAccent),
                ),
                const SizedBox(height: 36),
                const Text(
                  'تم التصويت بنجاح!',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'شكراً لك على تصويتك\nتمت العملية بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.7),
                ),
                const SizedBox(height: 52),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      color: Colors.white24, strokeWidth: 2.5),
                ),
                const SizedBox(height: 12),
                const Text('جارٍ إعادة الجهاز للحالة الاستعداد...',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Voting UI ─────────────────────────────────────────────────────────────

  Widget _buildVoting() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // no back arrow on kiosk
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote_rounded,
                color: Color(0xFF001F3F), size: 22),
            SizedBox(width: 8),
            Text(
              'التصويت الإلكتروني',
              style: TextStyle(
                color: Color(0xFF001F3F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Header card ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    color: Colors.white60, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر مرشحك',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اختر مرشحاً واحداً فقط ثم اضغط "تأكيد التصويت"',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Candidates list ─────────────────────────────────────────
          Expanded(
            child: _candidates.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF001F3F)))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: _candidates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = _candidates[i];
                      return _KioskCandidateTile(
                        candidate: c,
                        isSelected: _selected?.id == c.id,
                        onSelect: () =>
                            setState(() => _selected = c),
                        onSpeak: () {
                          final ar = c.nameAr;
                          final en = c.name;
                          _speak(ar.isNotEmpty ? '$ar، $en' : en);
                        },
                      );
                    },
                  ),
          ),

          // ── Confirm button ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
                label: const Text(
                  'تأكيد التصويت',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
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

// ─── Kiosk candidate tile ─────────────────────────────────────────────────────

class _KioskCandidateTile extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onSpeak;

  const _KioskCandidateTile({
    required this.candidate,
    required this.isSelected,
    required this.onSelect,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        candidate.nameAr.isNotEmpty ? candidate.nameAr : candidate.name;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF001F3F).withOpacity(0.07)
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
            // Radio button
            Radio<String>(
              value: candidate.id,
              groupValue: isSelected ? candidate.id : null,
              onChanged: (_) => onSelect(),
              activeColor: const Color(0xFF001F3F),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 10),

            // Candidate photo
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                width: 60,
                height: 60,
                child: candidate.image.isNotEmpty
                    ? Image.network(
                        candidate.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                        loadingBuilder: (_, child, prog) =>
                            prog == null ? child : _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF001F3F)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (candidate.name.isNotEmpty &&
                      candidate.name != candidate.nameAr) ...[
                    const SizedBox(height: 3),
                    Text(
                      candidate.name,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            // TTS button
            IconButton(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
              color: const Color(0xFF001F3F).withOpacity(0.45),
              iconSize: 24,
              tooltip: 'استمع للاسم',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFFE8EDF2),
        child: const Icon(Icons.person, color: Color(0xFF94A3B8), size: 30),
      );
}
