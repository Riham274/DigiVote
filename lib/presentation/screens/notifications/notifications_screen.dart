import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/auth/auth_state.dart';
import '../polling_stations/nearest_center_screen.dart';

// ─── Internal notification model ──────────────────────────────────────────────

class _Notif {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color accentColor;
  final String title;
  final String message;
  final String? badge;
  final VoidCallback? onTap;

  const _Notif({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.accentColor,
    required this.title,
    required this.message,
    this.badge,
    this.onTap,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notif> _dynamicNotifs = [];
  bool _loadingDynamic = true;

  @override
  void initState() {
    super.initState();
    // Defer to first frame so AuthStateWidget is accessible via context
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDynamic());
  }

  // ── Haversine distance ────────────────────────────────────────────────────

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

  // ── Load all dynamic notifications ────────────────────────────────────────

  Future<void> _loadDynamic() async {
    if (!mounted) return;
    setState(() => _loadingDynamic = true);

    final notifs = <_Notif>[];
    DateTime? electionDate;

    // ── 1. Election countdown ─────────────────────────────────────────────
    try {
      final doc = await FirebaseFirestore.instance
          .collection('elections_info')
          .doc('current_election')
          .get();

      if (doc.exists) {
        final raw = doc.data()?['election_date'];
        if (raw is Timestamp) {
          electionDate = raw.toDate();
        } else if (raw is String && raw.isNotEmpty) {
          electionDate = DateTime.tryParse(raw);
        }

        if (electionDate != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final elDay = DateTime(
              electionDate.year, electionDate.month, electionDate.day);
          final diff = elDay.difference(today).inDays;

          if (diff > 1) {
            notifs.add(_Notif(
              icon: Icons.event_rounded,
              iconBg: Colors.blue.shade50,
              iconColor: Colors.blue,
              accentColor: Colors.blue,
              title: 'موعد الانتخابات',
              message: 'باقي $diff أيام على موعد الانتخابات',
            ));
          } else if (diff == 1) {
            notifs.add(_Notif(
              icon: Icons.event_rounded,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.orange,
              accentColor: Colors.orange,
              title: 'غداً يوم الانتخابات',
              message: 'غداً يوم الانتخابات، تأكد من تجهيز هويتك',
              badge: 'تذكير',
            ));
          } else if (diff == 0) {
            notifs.add(_Notif(
              icon: Icons.how_to_vote_rounded,
              iconBg: Colors.red.shade50,
              iconColor: Colors.red,
              accentColor: Colors.red,
              title: 'اليوم يوم الانتخابات!',
              message: 'اليوم يوم الانتخابات! توجه لأقرب مركز اقتراع الآن',
              badge: 'عاجل',
            ));
          }
          // diff < 0 → past election → don't show
        }
      }
    } catch (_) {}

    // ── 2. Nearest voting center ──────────────────────────────────────────
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (serviceOn) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium),
          );

          final snap = await FirebaseFirestore.instance
              .collection('voting_center')
              .get();

          double minDist = double.infinity;
          String nearestName = '';

          for (final doc in snap.docs) {
            final d = doc.data();
            final lat = _toDouble(d['latitude']);
            final lon = _toDouble(d['longitude']);
            final dist = _haversine(pos.latitude, pos.longitude, lat, lon);
            if (dist < minDist) {
              minDist = dist;
              nearestName = d['center_name'] as String? ?? '';
            }
          }

          if (nearestName.isNotEmpty) {
            notifs.add(_Notif(
              icon: Icons.location_on_rounded,
              iconBg: const Color(0xFFE8EDF5),
              iconColor: const Color(0xFF001F3F),
              accentColor: const Color(0xFF001F3F),
              title: 'أقرب مركز اقتراع',
              message:
                  'أقرب مركز اقتراع لك: $nearestName، يبعد ${minDist.toStringAsFixed(1)} كم',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NearestCenterScreen()),
              ),
            ));
          }
        }
      }
    } catch (_) {}

    // ── 3. Voting status ──────────────────────────────────────────────────
    if (mounted) {
      final user = AuthStateWidget.of(context).currentUser;
      if (user != null && user.role != 'admin') {
        if (user.hasVoted) {
          notifs.add(_Notif(
            icon: Icons.check_circle_rounded,
            iconBg: Colors.green.shade50,
            iconColor: Colors.green,
            accentColor: Colors.green,
            title: 'تم تصويتك بنجاح',
            message:
                'تم تصويتك بنجاح، شكراً لمشاركتك في العملية الديمقراطية',
          ));
        } else if (electionDate != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final elDay = DateTime(
              electionDate.year, electionDate.month, electionDate.day);
          if (elDay == today) {
            notifs.add(_Notif(
              icon: Icons.warning_amber_rounded,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.orange,
              accentColor: Colors.orange,
              title: 'لم تصوّت بعد',
              message: 'لم تصوّت بعد، توجه إلى أقرب مركز اقتراع',
              badge: 'مهم',
            ));
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _dynamicNotifs = notifs;
        _loadingDynamic = false;
      });
    }
  }

  // ── Icon mapping for Firestore notifications ──────────────────────────────

  static IconData _mapIcon(String? name) => switch (name ?? '') {
        'campaign' || 'megaphone'  => Icons.campaign_rounded,
        'announcement'             => Icons.announcement_rounded,
        'event'                    => Icons.event_rounded,
        'person_add'               => Icons.person_add_rounded,
        'warning'                  => Icons.warning_amber_rounded,
        'info'                     => Icons.info_rounded,
        'check' || 'success'       => Icons.check_circle_rounded,
        'location'                 => Icons.location_on_rounded,
        'vote'                     => Icons.how_to_vote_rounded,
        _                          => Icons.notifications_rounded,
      };

  static Color _priorityColor(String? p) => switch (p ?? '') {
        'high'   => Colors.red,
        'medium' => Colors.orange,
        _        => Colors.blue,
      };

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
            'الإشعارات',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF001F3F)),
              onPressed: _loadDynamic,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Page header ──────────────────────────────────────────────
            const Text(
              'إشعاراتك',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'آخر التحديثات والتنبيهات المتعلقة بالانتخابات',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── Dynamic notifications ────────────────────────────────────
            const _SectionLabel(label: 'تنبيهات ذكية', icon: Icons.auto_awesome),
            const SizedBox(height: 12),

            if (_loadingDynamic)
              _LoadingCard()
            else if (_dynamicNotifs.isEmpty)
              _EmptyDynamic()
            else
              ..._dynamicNotifs.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotifCard(notif: n),
                  )),

            const SizedBox(height: 24),

            // ── Static notifications from Firestore ──────────────────────
            const _SectionLabel(label: 'إشعارات عامة', icon: Icons.notifications),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (ctx, snap) {
                // Debug output
                if (snap.hasError) {
                  debugPrint('🔴 Notifications error: ${snap.error}');
                }
                if (snap.hasData) {
                  debugPrint(
                      '📩 Notifications fetched: ${snap.data!.docs.length} docs');
                  for (final d in snap.data!.docs) {
                    debugPrint('  → ${d.id}: ${d.data()}');
                  }
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF001F3F)),
                    ),
                  );
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'تعذّر تحميل الإشعارات: ${snap.error}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد إشعارات عامة حالياً',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final priority = d['priority'] as String?;
                    final color = _priorityColor(priority);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotifCard(
                        notif: _Notif(
                          icon: _mapIcon(d['icon'] as String?),
                          iconBg: color.withValues(alpha: 0.1),
                          iconColor: color,
                          accentColor: color,
                          title: d['title'] as String? ?? '',
                          message: d['message'] as String? ?? '',
                        ),
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
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: const Color(0xFF001F3F)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F3F),
          ),
        ),
      ],
    );
  }
}

// ─── Loading placeholder ──────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: Color(0xFF001F3F), strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'جارٍ تحميل الإشعارات الذكية...',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Empty dynamic state ──────────────────────────────────────────────────────

class _EmptyDynamic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'لا توجد تنبيهات عاجلة، كل شيء على ما يرام',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final _Notif notif;

  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: notif.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent bar on the start side (right in RTL)
                Container(width: 4, color: notif.accentColor),

                const SizedBox(width: 14),

                // Icon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notif.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(notif.icon, color: notif.iconColor, size: 22),
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + badge row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (notif.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: notif.accentColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  notif.badge!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: notif.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Message
                        Text(
                          notif.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),

                        // Tap hint
                        if (notif.onTap != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'اضغط للتفاصيل',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: notif.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.chevron_left_rounded,
                                  size: 14, color: notif.accentColor),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
