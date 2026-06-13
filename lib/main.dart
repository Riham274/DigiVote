import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_state.dart';
import 'core/services/fcm_service.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/kiosk/kiosk_screen.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FcmService.initialize();
  runApp(const DigiVoteApp());
}

class DigiVoteApp extends StatefulWidget {
  const DigiVoteApp({super.key});

  @override
  State<DigiVoteApp> createState() => _DigiVoteAppState();
}

class _DigiVoteAppState extends State<DigiVoteApp> {
  final AuthNotifier _authNotifier = AuthNotifier();

  // null  = still checking
  // true  = authorized kiosk device → KioskScreen only
  // false = regular user device → normal app
  bool? _isKiosk;

  @override
  void initState() {
    super.initState();
    FcmService.setKeys(navKey: appNavKey, messengerKey: appMessengerKey);
    _checkKiosk(); // determines routing; also defers FCM permission for non-kiosk
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  // ── Device ID helper (same logic as VotingScreen) ─────────────────────────

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

  Future<void> _checkKiosk() async {
    try {
      final deviceId = await _getDeviceId();
      debugPrint('>>> DEVICE ID: $deviceId <<<');

      // ── DEBUG: show device ID on screen so it can be added to Firebase ──
      // Remove this block once the device is authorized.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Device ID: $deviceId',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            duration: const Duration(seconds: 60),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'نسخ',
              textColor: Colors.greenAccent,
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: deviceId)),
            ),
          ),
        );
      });
      // ────────────────────────────────────────────────────────────────────

      final query = await FirebaseFirestore.instance
          .collection('authorized_devices')
          .where('device_id', isEqualTo: deviceId)
          .limit(1)
          .get();

      final isKiosk = query.docs.isNotEmpty &&
          (query.docs.first.data()['is_active'] as bool? ?? false);

      if (!mounted) return;
      setState(() => _isKiosk = isKiosk);

      // FCM notification permission only for regular (non-kiosk) devices
      if (!isKiosk) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ctx = appNavKey.currentContext;
          if (ctx != null && ctx.mounted) {
            await FcmService.requestPermission(ctx);
          }
        });
      }
    } catch (e) {
      debugPrint('Kiosk check error: $e');
      // Default to normal app on any error
      if (mounted) setState(() => _isKiosk = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AuthStateWidget(
      notifier: _authNotifier,
      child: MaterialApp(
        navigatorKey: appNavKey,
        scaffoldMessengerKey: appMessengerKey,
        title: 'DigiVote',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (_isKiosk == null) return const _AppSplash();   // device check in progress
    if (_isKiosk!)        return const KioskScreen();  // voting booth device
    return const MainNavigationScreen();               // regular user device
  }
}

// ─── Splash shown while device authorization is checked (<1 s) ───────────────

class _AppSplash extends StatelessWidget {
  const _AppSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000613),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 16),
            const Text(
              'DigiVote',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  color: Colors.white24, strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
