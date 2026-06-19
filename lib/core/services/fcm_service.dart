import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import 'notification_service.dart';

// Must be top-level — called by the system when app is terminated/background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 [BG] FCM message: ${message.notification?.title}');
}

class FcmService {
  FcmService._();

  static final _fcm = FirebaseMessaging.instance;
  static GlobalKey<NavigatorState>? _navKey;
  static GlobalKey<ScaffoldMessengerState>? _messengerKey;

  /// Call once before [initialize] to supply navigation & snackbar keys.
  static void setKeys({
    required GlobalKey<NavigatorState> navKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) {
    _navKey = navKey;
    _messengerKey = messengerKey;
  }

  /// Call once in main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    // Register background handler first
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS foreground presentation options (no-op on Android)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // App was TERMINATED — user tapped notification to open app
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay to let Navigator finish building
      Future.delayed(const Duration(milliseconds: 800), () => _openNotifications());
    }

    // App was in BACKGROUND — user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());

    // App is FOREGROUND — show real system notification via flutter_local_notifications
    FirebaseMessaging.onMessage.listen(_showSystemNotification);
  }

  /// Show a friendly dialog then request system notification permission.
  /// Safe to call multiple times — skips if already granted or denied.
  static Future<void> requestPermission(BuildContext context) async {
    final settings = await _fcm.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) return;
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (!context.mounted) return;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF001F3F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF001F3F),
              size: 40,
            ),
          ),
          title: const Text(
            'تفعيل الإشعارات',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF001F3F)),
          ),
          content: const Text(
            'للحصول على تنبيهات مهمة بخصوص الانتخابات كمواعيد التصويت، '
            'إضافة مرشحين جدد، وآخر المستجدات.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.7, fontSize: 14, color: Color(0xFF43474E)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding:
              const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('لاحقاً'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F3F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'السماح',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (agreed != true) return;

    final result = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('📱 FCM permission: ${result.authorizationStatus}');
  }

  /// Get the FCM token and save it to Firestore under voters/{nationalId}.
  /// Also refreshes the token automatically when it changes.
  static Future<void> saveToken(String nationalId) async {
    if (nationalId.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('📱 FCM token: null (web or permissions not granted)');
        return;
      }
      debugPrint('📱 FCM token saved for $nationalId');
      await FirebaseFirestore.instance
          .collection('voters')
          .doc(nationalId)
          .update({'fcm_token': token});

      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('📱 FCM token refreshed for $nationalId');
        await FirebaseFirestore.instance
            .collection('voters')
            .doc(nationalId)
            .update({'fcm_token': newToken});
      });
    } catch (e) {
      debugPrint('🔴 FCM saveToken error: $e');
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static void _openNotifications() {
    _navKey?.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  static void _showSystemNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    NotificationService.show(
      id: n.hashCode,
      title: n.title ?? 'إشعار جديد',
      body: n.body ?? '',
    );
  }
}
