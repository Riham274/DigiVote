import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';
import '../admin/add_voting_center_screen.dart';
import 'nearest_center_screen.dart';

class PollingStationsScreen extends StatelessWidget {
  const PollingStationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthStateWidget.of(context);
    final bool isAdmin = auth.isLoggedIn && auth.currentUser?.role == 'admin';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'مراكز الاقتراع',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddVotingCenterScreen()),
                ),
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('إضافة مركز',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            // ── Dark blue banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF000613), Color(0xFF001F3F)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF001F3F).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'خريطة مراكز الاقتراع الوطنية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ابحث عن أقرب مركز اقتراع لك وتوجه إليه في يوم الانتخابات للمشاركة',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NearestCenterScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me_rounded,
                                    color: Colors.white, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'أقرب مركز إليك',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Admin banner ─────────────────────────────────────────────
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: AppColors.primaryContainer, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'وضع المشرف — يمكنك إضافة مراكز اقتراع جديدة عبر زر الإضافة.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Section title ─────────────────────────────────────────────
            const Text(
              'المراكز المتاحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 16),

            // ── Firestore list ────────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('voting_center')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.cloud_off_rounded,
                    text: 'تعذّر تحميل البيانات، تحقق من الاتصال وأعد المحاولة.',
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildMessage(
                    icon: Icons.location_off_outlined,
                    text: 'لا توجد مراكز اقتراع مسجّلة حتى الآن.',
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _VotingCenterCard(
                        centerName: d['center_name'] as String? ?? '',
                        city: d['city'] as String? ?? '',
                        address: d['address'] as String? ?? '',
                        latitude: _toDouble(d['latitude']),
                        longitude: _toDouble(d['longitude']),
                        status: d['status'] as String? ?? '',
                        waitingTime: d['waiting_time'] as String? ?? '',
                        openingHours: d['opening_hours'] as String? ?? '',
                        image: d['image'] as String? ?? '',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildMessage({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VotingCenterCard extends StatelessWidget {
  final String centerName;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final String waitingTime;
  final String openingHours;
  final String image;

  const _VotingCenterCard({
    required this.centerName,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.waitingTime,
    required this.openingHours,
    required this.image,
  });

  bool get _isOpen {
    final s = status.toLowerCase();
    return s == 'open' || s == 'مفتوح';
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image header ────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder: (_, child, prog) =>
                              prog == null ? child : _placeholder(),
                        )
                      : _placeholder(),

                  // Dark gradient overlay (bottom)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Distance / GPS badge — top left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: _openMaps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 14, color: Color(0xFF001F3F)),
                            const SizedBox(width: 4),
                            const Text(
                              'الموقع',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F3F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // City badge — bottom right
                  if (city.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_city,
                                size: 12, color: Color(0xFF001F3F)),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F3F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Card body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Center name
                Text(
                  centerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status row
                Row(
                  children: [
                    // Green/red dot + status text
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOpen ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOpen ? 'مفتوح' : 'مغلق',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isOpen ? Colors.green : Colors.redAccent,
                      ),
                    ),

                    // Waiting time (only when open)
                    if (_isOpen && waitingTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'وقت الانتظار: $waitingTime',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],

                    // Opening hours (when closed)
                    if (!_isOpen && openingHours.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_rounded,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'يفتح: $openingHours',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // GPS button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'افتح في الخريطة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F3F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000613), Color(0xFF001F3F)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_vote,
                color: Colors.white, size: 36),
          ),
        ),
      );
}
