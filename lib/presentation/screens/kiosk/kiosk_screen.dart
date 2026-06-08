import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/models/candidate_model.dart';

// ─── State machine ─────────────────────────────────────────────────────────────

enum _KioskState {
  welcome,       // waiting for Pi to set booth_status → "occupied"
  voterCheck,    // verifying voter + fetching token
  alreadyVoted,  // voter already voted — show error, auto-reset
  noTokens,      // token pool exhausted
  voting,        // show candidates, audio guide, confirm
  submitting,    // Firestore transaction in progress
  success,       // vote recorded — show thank-you, auto-reset
}

// ─── Root kiosk widget ────────────────────────────────────────────────────────

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with TickerProviderStateMixin {
  // ── Core state ─────────────────────────────────────────────────────────────
  _KioskState _state = _KioskState.welcome;
  String _currentVoterId = '';
  String? _tokenDocId;
  String? _tokenValue;
  Candidate? _selected;
  List<Candidate> _candidates = [];

  // ── Audio guide state ──────────────────────────────────────────────────────
  bool _guideActive = false;
  int _highlightedIndex = -1; // index in _candidates being read aloud (-1 = none)

  // ── Controllers ────────────────────────────────────────────────────────────
  late final PageController _pageCtrl;
  StreamSubscription<DocumentSnapshot>? _boothSub;
  final FlutterTts _tts = FlutterTts();

  // ── Welcome pulse animation ────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── Arabic cardinal numbers for TTS ───────────────────────────────────────
  static const List<String> _arabicNums = [
    '',
    'واحد', 'اثنين', 'ثلاثة', 'أربعة', 'خمسة',
    'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة',
  ];
  String _arabicOrdinal(int n) =>
      (n >= 1 && n <= 10) ? _arabicNums[n] : '$n';

  // ── Init / dispose ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.65);
    _initPulse();
    _initTts();
    _preloadCandidates();
    _listenBooth();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pageCtrl.dispose();
    _boothSub?.cancel();
    _tts.stop();
    super.dispose();
  }

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
    await _tts.setPitch(1.0);
  }

  Future<void> _preloadCandidates() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('candidates').get();
      if (!mounted) return;
      setState(() {
        _candidates = snap.docs
            .map((d) => Candidate.fromFirestore(
                d.id, d.data()))
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
        _highlightedIndex = -1;
        _state = _KioskState.voterCheck;
      });
      _checkVoterAndToken();
    } else if (status == 'available' && _state != _KioskState.welcome) {
      // External reset (admin / Pi override)
      _guideActive = false;
      _tts.stop();
      if (mounted) setState(() => _state = _KioskState.welcome);
    }
  }

  // ── Voter & token check ───────────────────────────────────────────────────

  Future<void> _checkVoterAndToken() async {
    try {
      final voterSnap = await FirebaseFirestore.instance
          .collection('voters')
          .doc(_currentVoterId)
          .get();

      if (!mounted) return;

      final data = voterSnap.data();
      final hasVoted = data?['has_voted'] as bool? ?? false;

      if (hasVoted) {
        await _tts.speak('لقد قمت بالتصويت مسبقاً');
        setState(() => _state = _KioskState.alreadyVoted);
        await Future.delayed(const Duration(seconds: 4));
        if (!mounted) return;
        await _resetBooth();
        return;
      }

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
          tokenQuery.docs.first.data()['token'] as String? ?? _tokenDocId;

      if (_candidates.isEmpty) await _preloadCandidates();
      if (!mounted) return;

      setState(() => _state = _KioskState.voting);
      _runAudioGuide(); // fire and forget — guide runs alongside UI
    } catch (e) {
      debugPrint('Kiosk voter check error: $e');
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _state = _KioskState.welcome);
      }
    }
  }

  // ── Full audio guide ──────────────────────────────────────────────────────
  //
  // 1. Welcome phrase
  // 2. For each candidate: highlight card → speak name → 2s pause
  // 3. Instruction to tap

  Future<void> _runAudioGuide() async {
    _guideActive = true;
    _highlightedIndex = -1;

    await _speakAndWait('مرحباً بك في شاشة التصويت');
    if (!_guideActive || !mounted) { return; }

    for (int i = 0; i < _candidates.length; i++) {
      if (!_guideActive || !mounted) { return; }

      setState(() => _highlightedIndex = i);
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          i,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }

      final name = _candidates[i].nameAr.isNotEmpty
          ? _candidates[i].nameAr
          : _candidates[i].name;
      await _speakAndWait('المرشح رقم ${_arabicOrdinal(i + 1)}: $name');
      if (!_guideActive || !mounted) { return; }

      await Future.delayed(const Duration(seconds: 2));
      if (!_guideActive || !mounted) { return; }
    }

    if (mounted) setState(() => _highlightedIndex = -1);
    await _speakAndWait('اضغط على صورة المرشح الذي تريد التصويت له');
    _guideActive = false;
  }

  /// Speaks [text] then waits an estimated duration for speech to finish.
  /// Estimation: ~120 ms per non-space character, min 700 ms, max 9 s.
  Future<void> _speakAndWait(String text) async {
    await _tts.stop();
    await _tts.speak(text);
    final chars = text.replaceAll(' ', '').length;
    await Future.delayed(
        Duration(milliseconds: (chars * 120).clamp(700, 9000)));
  }

  // ── Candidate selection ───────────────────────────────────────────────────

  void _onCandidateSelected(Candidate c) {
    _guideActive = false; // abort audio guide
    _tts.stop();
    if (!mounted) return;
    setState(() {
      _selected = c;
      _highlightedIndex = -1;
    });
    final name = c.nameAr.isNotEmpty ? c.nameAr : c.name;
    Future.delayed(
      const Duration(milliseconds: 150),
      () => _tts.speak('لقد اخترت المرشح $name'),
    );
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  Future<void> _onConfirmPressed() async {
    if (_selected == null) return;
    final name =
        _selected!.nameAr.isNotEmpty ? _selected!.nameAr : _selected!.name;

    // TTS plays while dialog is shown — no await
    _tts.speak(
      'هل تريد التصويت للمرشح $name؟ '
      'اضغط الزر الأخضر للتأكيد أو الأحمر للإلغاء',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _buildConfirmDialog(ctx, name),
      ),
    );

    if (confirmed != true) {
      _tts.stop();
      return;
    }

    await _submitVote();
  }

  Widget _buildConfirmDialog(BuildContext ctx, String name) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Candidate thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: SizedBox(
                width: 88,
                height: 88,
                child: _selected!.image.isNotEmpty
                    ? Image.network(
                        _selected!.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarFallback(size: 88),
                      )
                    : _avatarFallback(size: 88),
              ),
            ),
            const SizedBox(height: 14),

            // Candidate name
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل تريد التصويت لهذا المرشح؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4),
            ),
            const SizedBox(height: 28),

            // Two large accessible icon-only buttons
            Row(
              children: [
                // ── RED cancel ──────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded,
                            color: Colors.white, size: 66),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // ── GREEN confirm ───────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded,
                            color: Colors.white, size: 66),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        final tokenSnap = await tx.get(tokenRef);
        if (tokenSnap.data()?['used'] == true) {
          throw Exception('token_already_used');
        }

        // Anonymous vote — no personal data stored
        tx.set(db.collection('votes').doc(), {
          'candidate_id': _selected!.candidateId,
          'token': _tokenValue!,
        });
        tx.update(tokenRef, {'used': true});
        tx.update(
          db.collection('voters').doc(_currentVoterId),
          {'has_voted': true},
        );
      });

      if (!mounted) return;
      await _tts.speak('شكراً لك، تم تسجيل صوتك بنجاح');
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _resetBooth() async {
    try {
      await FirebaseFirestore.instance
          .collection('booth_status')
          .doc('booth_001')
          .update({'status': 'available', 'current_voter': ''});
    } catch (_) {
      if (mounted) setState(() => _state = _KioskState.welcome);
    }
  }

  // ── Root build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // kiosk: no back
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildForState(),
      ),
    );
  }

  Widget _buildForState() => switch (_state) {
        _KioskState.welcome => _buildWelcome(),
        _KioskState.voterCheck => _buildDark(
            icon: Icons.fingerprint_rounded,
            iconColor: Colors.blueAccent,
            message: 'جارٍ التحقق من هوية الناخب...',
          ),
        _KioskState.alreadyVoted => _buildAlreadyVoted(),
        _KioskState.noTokens => _buildNoTokens(),
        _KioskState.voting => _buildVoting(),
        _KioskState.submitting => _buildDark(
            icon: Icons.how_to_vote_rounded,
            iconColor: Colors.white60,
            message: 'جارٍ تسجيل تصويتك...',
            showSpinner: true,
          ),
        _KioskState.success => _buildSuccess(),
      };

  // =========================================================================
  // WELCOME SCREEN
  // =========================================================================

  Widget _buildWelcome() {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
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

              // Pulsing fingerprint
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
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                    color: Colors.white24, strokeWidth: 2.5),
              ),
              const SizedBox(height: 16),
              const Text('جارٍ مراقبة المنصة...',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DARK STATUS SCREENS (checking / submitting)
  // =========================================================================

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
              if (showSpinner) ...[
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      color: Colors.white38, strokeWidth: 2.5),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ALREADY VOTED
  // =========================================================================

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

  // =========================================================================
  // NO TOKENS
  // =========================================================================

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

  // =========================================================================
  // SUCCESS
  // =========================================================================

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

  // =========================================================================
  // VOTING SCREEN — horizontal cards + accessible UI
  // =========================================================================

  Widget _buildVoting() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Instruction header ───────────────────────────────────────
          _buildVotingHeader(),

          // ── Horizontal candidate cards ───────────────────────────────
          Expanded(
            child: _candidates.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF001F3F)))
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _candidates.length,
                      itemBuilder: (_, i) => _buildCandidateCard(
                        _candidates[i],
                        i,
                        _selected?.id == _candidates[i].id,
                        _highlightedIndex == i,
                      ),
                    ),
                  ),
          ),

          // ── Confirm button ───────────────────────────────────────────
          _buildConfirmBar(),
        ],
      ),
    );
  }

  Widget _buildVotingHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          const Icon(Icons.touch_app_rounded, color: Colors.white60, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'اضغط على صورة المرشح الذي تريد التصويت له',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          // Volume replay button
          IconButton(
            onPressed: () {
              _tts.stop();
              _guideActive = false;
              Future.delayed(
                const Duration(milliseconds: 200),
                _runAudioGuide,
              );
            },
            icon: const Icon(Icons.replay_rounded,
                color: Colors.white54, size: 24),
            tooltip: 'إعادة الشرح الصوتي',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar() {
    final name = _selected != null
        ? (_selected!.nameAr.isNotEmpty ? _selected!.nameAr : _selected!.name)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selection indicator
          if (name != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(
                  'اخترت: $name',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selected != null ? _onConfirmPressed : null,
              icon: const Icon(Icons.how_to_vote_rounded, size: 26),
              label: const Text(
                'تأكيد التصويت',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 19),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Candidate card ──────────────────────────────────────────────────────

  Widget _buildCandidateCard(
    Candidate c,
    int index,
    bool isSelected,
    bool isHighlighted,
  ) {
    final name = c.nameAr.isNotEmpty ? c.nameAr : c.name;

    // Border and background based on state
    final Color borderColor;
    final double borderWidth;
    final Color bgColor;
    final List<BoxShadow> shadows;

    if (isSelected) {
      borderColor = const Color(0xFF22C55E); // green
      borderWidth = 4.0;
      bgColor = const Color(0xFFF0FFF4); // green tint
      shadows = [
        BoxShadow(
          color: Colors.green.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (isHighlighted) {
      borderColor = const Color(0xFF3B82F6); // blue
      borderWidth = 4.0;
      bgColor = const Color(0xFFEFF6FF); // blue tint
      shadows = [
        BoxShadow(
          color: Colors.blue.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      borderColor = const Color(0xFFCBD5E1); // grey
      borderWidth = 1.5;
      bgColor = Colors.white;
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return GestureDetector(
      onTap: () => _onCandidateSelected(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image section (top ~62% of card) ──────────────────────
            Expanded(
              flex: 62,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo
                    c.image.isNotEmpty
                        ? Image.network(
                            c.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _cardImageFallback(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _cardImageFallback(),
                          )
                        : _cardImageFallback(),

                    // Green checkmark badge (selected)
                    if (isSelected)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),

                    // Blue TTS speaker badge (being read)
                    if (isHighlighted && !isSelected)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info section (bottom ~38%) ─────────────────────────────
            Expanded(
              flex: 38,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Candidate number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF22C55E).withOpacity(0.15)
                            : isHighlighted
                                ? const Color(0xFF3B82F6).withOpacity(0.12)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'مرشح رقم ${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF16A34A)
                              : isHighlighted
                                  ? const Color(0xFF1D4ED8)
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Candidate name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _cardImageFallback() {
    return Container(
      color: const Color(0xFFE8EDF2),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 80),
        ],
      ),
    );
  }

  Widget _avatarFallback({double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EDF2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded,
          color: Color(0xFF94A3B8), size: 36),
    );
  }
}
