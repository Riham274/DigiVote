import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Internal data model ──────────────────────────────────────────────────────

class _Center {
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final double distance; // km
  final int driveMinutes;
  final int walkMinutes;
  final String imageUrl;

  const _Center({
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.distance,
    required this.driveMinutes,
    required this.walkMinutes,
    required this.imageUrl,
  });
}

enum _LocState { loading, denied, disabled, ready }

// ─── Screen ───────────────────────────────────────────────────────────────────

class NearestCenterScreen extends StatefulWidget {
  const NearestCenterScreen({super.key});

  @override
  State<NearestCenterScreen> createState() => _NearestCenterScreenState();
}

class _NearestCenterScreenState extends State<NearestCenterScreen> {
  _LocState _state = _LocState.loading;
  List<_Center> _centers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Haversine ─────────────────────────────────────────────────────────────

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // ── Load flow ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _state = _LocState.loading);

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      if (mounted) setState(() => _state = _LocState.disabled);
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _state = _LocState.denied);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final snap =
        await FirebaseFirestore.instance.collection('voting_center').get();

    final list = snap.docs.map((doc) {
      final d = doc.data();
      final lat = _toDouble(d['latitude']);
      final lon = _toDouble(d['longitude']);
      final dist = _haversine(pos.latitude, pos.longitude, lat, lon);
      return _Center(
        name: d['center_name'] as String? ?? '',
        city: d['city'] as String? ?? '',
        address: d['address'] as String? ?? '',
        latitude: lat,
        longitude: lon,
        status: d['status'] as String? ?? '',
        distance: dist,
        driveMinutes: (dist * 2).round(),   // 30 km/h → 2 min/km
        walkMinutes: (dist * 12).round(),   // 5  km/h → 12 min/km
        imageUrl: d['image_url'] as String? ?? d['image'] as String? ?? '',
      );
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (mounted) setState(() { _centers = list; _state = _LocState.ready; });
  }

  Future<void> _openMaps(double lat, double lon) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'أقرب مركز اقتراع',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF001F3F)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF001F3F)),
              onPressed: _load,
              tooltip: 'تحديث الموقع',
            ),
          ],
        ),
        body: switch (_state) {
          _LocState.loading  => _buildLoading(),
          _LocState.denied   => _buildError(
              icon: Icons.location_off_rounded,
              message:
                  'يرجى السماح بالوصول إلى الموقع لمعرفة أقرب مركز اقتراع',
              showSettings: true,
            ),
          _LocState.disabled => _buildError(
              icon: Icons.gps_off_rounded,
              message: 'يرجى تفعيل خدمة الموقع للمتابعة',
            ),
          _LocState.ready    => _buildList(),
        },
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF001F3F)),
            SizedBox(height: 20),
            Text('جارٍ تحديد موقعك...',
                style: TextStyle(color: Color(0xFF001F3F), fontSize: 15)),
          ],
        ),
      );

  Widget _buildError({
    required IconData icon,
    required String message,
    bool showSettings = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF001F3F), fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 32),
            if (showSettings) ...[
              ElevatedButton.icon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('فتح الإعدادات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF001F3F),
                side: const BorderSide(color: Color(0xFF001F3F)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_centers.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مراكز اقتراع مسجلة حتى الآن',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _centers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _CenterCard(
        center: _centers[i],
        isNearest: i == 0,
        onNavigate: () =>
            _openMaps(_centers[i].latitude, _centers[i].longitude),
      ),
    );
  }
}

// ─── Card widget ──────────────────────────────────────────────────────────────

class _CenterCard extends StatelessWidget {
  final _Center center;
  final bool isNearest;
  final VoidCallback onNavigate;

  const _CenterCard({
    required this.center,
    required this.isNearest,
    required this.onNavigate,
  });

  bool get _isOpen {
    final s = center.status.toLowerCase();
    return s == 'open' || s == 'مفتوح';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isNearest
            ? Border.all(color: const Color(0xFF001F3F), width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isNearest
                ? const Color(0xFF001F3F).withOpacity(0.14)
                : Colors.black.withOpacity(0.05),
            blurRadius: isNearest ? 28 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image header ───────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: isNearest ? 160 : 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Center image or placeholder gradient
                  center.imageUrl.isNotEmpty
                      ? Image.network(
                          center.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _headerPlaceholder(),
                          loadingBuilder: (_, child, prog) =>
                              prog == null ? child : _headerPlaceholder(),
                        )
                      : _headerPlaceholder(),

                  // Bottom gradient overlay so text is readable
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Distance badge — top right
                  Positioned(
                    top: 12,
                    right: 14,
                    child: _Badge(
                      icon: Icons.my_location_rounded,
                      label: '${center.distance.toStringAsFixed(1)} كم',
                      bgColor: Colors.white.withOpacity(0.15),
                      textColor: Colors.white,
                      iconColor: Colors.white70,
                    ),
                  ),

                  // 'الأقرب إليك' badge — top left, nearest only
                  if (isNearest)
                    Positioned(
                      top: 12,
                      left: 14,
                      child: _Badge(
                        icon: Icons.star_rounded,
                        label: 'الأقرب إليك',
                        bgColor: Colors.amber,
                        textColor: const Color(0xFF001F3F),
                        iconColor: const Color(0xFF001F3F),
                      ),
                    ),

                  // Center name at bottom
                  Positioned(
                    bottom: 12,
                    right: 14,
                    left: 14,
                    child: Text(
                      center.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                if (center.address.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          center.address,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Status chip
                Row(
                  children: [
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
                  ],
                ),
                const SizedBox(height: 12),

                // Travel time chips
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _TimeChip(
                      emoji: '🚗',
                      label: '${center.driveMinutes} دقيقة بالسيارة',
                      color: const Color(0xFF001F3F),
                    ),
                    _TimeChip(
                      emoji: '🚶',
                      label: '${center.walkMinutes} دقيقة مشياً',
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Navigate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'الذهاب إلى المركز',
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

  Widget _headerPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000613), Color(0xFF001F3F)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: const Center(
          child: Icon(Icons.how_to_vote_rounded,
              color: Colors.white24, size: 40),
        ),
      );
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color iconColor;

  const _Badge({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _TimeChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification card (embeddable in any screen) ─────────────────────────────

class NearestCenterNotifCard extends StatefulWidget {
  const NearestCenterNotifCard({super.key});

  @override
  State<NearestCenterNotifCard> createState() => _NearestCenterNotifCardState();
}

class _NearestCenterNotifCardState extends State<NearestCenterNotifCard> {
  _LocState _state = _LocState.loading;
  String _centerName = '';
  double _distanceKm = 0;
  int _driveMinutes = 0;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchNearest();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _fetchNearest() async {
    setState(() => _state = _LocState.loading);

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      if (mounted) setState(() => _state = _LocState.disabled);
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _state = _LocState.denied);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    final snap =
        await FirebaseFirestore.instance.collection('voting_center').get();

    if (snap.docs.isEmpty) {
      if (mounted) setState(() => _state = _LocState.ready);
      return;
    }

    _Center? nearest;
    for (final doc in snap.docs) {
      final d = doc.data();
      final lat = _toDouble(d['latitude']);
      final lon = _toDouble(d['longitude']);
      final dist = _haversine(pos.latitude, pos.longitude, lat, lon);
      final c = _Center(
        name: d['center_name'] as String? ?? '',
        city: d['city'] as String? ?? '',
        address: d['address'] as String? ?? '',
        latitude: lat,
        longitude: lon,
        status: d['status'] as String? ?? '',
        distance: dist,
        driveMinutes: (dist * 2).round(),
        walkMinutes: (dist * 12).round(),
        imageUrl: d['image_url'] as String? ?? d['image'] as String? ?? '',
      );
      if (nearest == null || dist < nearest.distance) nearest = c;
    }

    if (mounted && nearest != null) {
      setState(() {
        _centerName = nearest!.name;
        _distanceKm = nearest.distance;
        _driveMinutes = nearest.driveMinutes;
        _imageUrl = nearest.imageUrl;
        _state = _LocState.ready;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _LocState.denied || _state == _LocState.disabled) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NearestCenterScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: _state == _LocState.loading
            ? const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white60, strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'جارٍ تحديد أقرب مركز اقتراع...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              )
            : Row(
                children: [
                  // Image thumbnail or location icon
                  _imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _iconCircle(),
                          ),
                        )
                      : _iconCircle(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أقرب مركز اقتراع لك',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _centerName.isEmpty
                              ? 'لا توجد مراكز مسجلة'
                              : _centerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_centerName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'يبعد ${_distanceKm.toStringAsFixed(1)} كم · 🚗 $_driveMinutes دقيقة',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded,
                      color: Colors.white38, size: 22),
                ],
              ),
      ),
    );
  }

  Widget _iconCircle() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.location_on_rounded,
            color: Colors.white, size: 22),
      );
}
