import 'package:flutter/material.dart';
import '../../../core/models/candidate_model.dart';

class CandidateDetailsScreen extends StatelessWidget {
  final Candidate candidate;
  const CandidateDetailsScreen({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF001F3F)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'ملف المرشح',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero header ─────────────────────────────────────────────
              _buildHeroHeader(),

              // ── Body sections ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age + Qualification row
                    _buildInfoRow(),
                    const SizedBox(height: 24),

                    if (candidate.bio.isNotEmpty) ...[
                      _sectionHeader('النبذة الشخصية',
                          Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _textCard(candidate.bio),
                      const SizedBox(height: 24),
                    ],

                    if (candidate.experience.isNotEmpty) ...[
                      _sectionHeader(
                          'الخبرة', Icons.workspace_premium_outlined),
                      const SizedBox(height: 12),
                      _textCard(candidate.experience),
                      const SizedBox(height: 24),
                    ],

                    if (candidate.achievements.isNotEmpty) ...[
                      _sectionHeader('الإنجازات السابقة',
                          Icons.emoji_events_outlined),
                      const SizedBox(height: 12),
                      _textCard(candidate.achievements),
                      const SizedBox(height: 24),
                    ],

                    if (candidate.goals.isNotEmpty) ...[
                      _sectionHeader('البرنامج الانتخابي',
                          Icons.checklist_rounded),
                      const SizedBox(height: 12),
                      _buildGoals(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero: circular image + name + slogan ─────────────────────────────────

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000613), Color(0xFF001F3F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        children: [
          // Circular photo
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
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
          const SizedBox(height: 20),

          // Name
          Text(
            candidate.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),

          // Slogan
          if (candidate.slogan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${candidate.slogan}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Age + Qualification chips ─────────────────────────────────────────────

  Widget _buildInfoRow() {
    return Row(
      children: [
        if (candidate.age > 0)
          Expanded(
            child: _infoChip(
              icon: Icons.cake_outlined,
              label: 'العمر',
              value: '${candidate.age} سنة',
            ),
          ),
        if (candidate.age > 0 && candidate.qualification.isNotEmpty)
          const SizedBox(width: 12),
        if (candidate.qualification.isNotEmpty)
          Expanded(
            child: _infoChip(
              icon: Icons.school_outlined,
              label: 'المؤهل',
              value: candidate.qualification,
            ),
          ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF001F3F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF001F3F), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F3F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: const Color(0xFF001F3F), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F3F),
          ),
        ),
      ],
    );
  }

  // ── Text content card ──────────────────────────────────────────────────────

  Widget _textCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
          height: 1.8,
        ),
      ),
    );
  }

  // ── Goals list ─────────────────────────────────────────────────────────────

  Widget _buildGoals() {
    return Column(
      children: candidate.goals.asMap().entries.map((entry) {
        final num = entry.key + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF001F3F),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$num',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF22C55E), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFF1E3A5F),
        child: const Icon(Icons.person_rounded,
            color: Colors.white54, size: 60),
      );
}
