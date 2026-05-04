import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_state.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UniVoteApp());
}

class UniVoteApp extends StatefulWidget {
  const UniVoteApp({super.key});

  @override
  State<UniVoteApp> createState() => _UniVoteAppState();
}

class _UniVoteAppState extends State<UniVoteApp> {
  // AuthNotifier lives here — above ALL navigators, so it can be found from
  // any widget in the tree via AuthStateWidget.of(context).
  final AuthNotifier _authNotifier = AuthNotifier();

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthStateWidget(
      notifier: _authNotifier,
      child: MaterialApp(
        title: 'UniVote',
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
        home: const MainNavigationScreen(),
      ),
    );
  }
}
