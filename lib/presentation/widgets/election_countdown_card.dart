import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Drop-in countdown widget. Subscribes to Firestore on its own —
/// just place `ElectionCountdownCard()` wherever you need it.
class ElectionCountdownCard extends StatelessWidget {
  const ElectionCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('elections_info')
          .doc('current_election')
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFF070F1A),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }
        final data = (snap.data?.exists ?? false)
            ? snap.data!.data() as Map<String, dynamic>?
            : null;
        if (data == null) return const SizedBox.shrink();
        return _CountdownContent(data: data);
      },
    );
  }
}

// ─── Internal stateful countdown ─────────────────────────────────────────────

class _CountdownContent extends StatefulWidget {
  final Map<String, dynamic> data;
  const _CountdownContent({required this.data});

  @override
  State<_CountdownContent> createState() => _CountdownContentState();
}

class _CountdownContentState extends State<_CountdownContent> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  static const _arabicMonths = [
    '',
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
  ];

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(_CountdownContent old) {
    super.didUpdateWidget(old);
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime? _parseDateTime(String dateField, String timeField) {
    final dateStr = widget.data[dateField] as String? ?? '';
    final timeStr = widget.data[timeField] as String? ?? '';
    if (dateStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      final parts = timeStr.split(':');
      final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return DateTime(date.year, date.month, date.day, h, m);
    } catch (_) {
      return null;
    }
  }

  void _tick() {
    final start = _parseDateTime('election_date', 'start_time');
    if (start == null) return;
    final diff = start.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  String _toArabicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  String _formatArabicDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${_toArabicNumerals(d.day)} ${_arabicMonths[d.month]} ${_toArabicNumerals(d.year)}';
    } catch (_) {
      return dateStr;
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final electionName =
        widget.data['election_name'] as String? ?? 'الانتخابات الوطنية';
    final dateStr = widget.data['election_date'] as String? ?? '';
    final arabicDate =
        dateStr.isNotEmpty ? _formatArabicDate(dateStr) : '';

    final start = _parseDateTime('election_date', 'start_time');
    final end = _parseDateTime('election_date', 'end_time');
    final now = DateTime.now();

    final isFuture = start != null && now.isBefore(start);
    final isDuring = start != null &&
        end != null &&
        !now.isBefore(start) &&
        now.isBefore(end);
    final isPast = end != null && !now.isBefore(end);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070F1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            electionName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (arabicDate.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'موعد الانتخابات: $arabicDate',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
          const SizedBox(height: 20),
          if (isDuring)
            _statusBanner('التصويت جارٍ الآن! 🗳️', Colors.green)
          else if (isPast)
            _statusBanner('انتهت فترة التصويت', Colors.red)
          else if (isFuture)
            _countdownBoxes()
          else
            _statusBanner('موعد الانتخابات قيد التحديد', Colors.grey),
        ],
      ),
    );
  }

  Widget _statusBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _countdownBoxes() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      children: [
        Expanded(child: _timeUnit(days.toString(), 'أيام')),
        _colon(),
        Expanded(child: _timeUnit(_pad(hours), 'ساعات')),
        _colon(),
        Expanded(child: _timeUnit(_pad(minutes), 'دقائق')),
        _colon(),
        Expanded(child: _timeUnit(_pad(seconds), 'ثوانٍ')),
      ],
    );
  }

  Widget _timeUnit(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _colon() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white24,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
