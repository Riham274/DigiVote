import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// A [ChangeNotifier] that holds the current authentication state.
/// Placed above all Navigators so it can be found from any widget in the tree.
class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserModel? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;

  void login(String role) {
    _isLoggedIn = true;
    _currentUser =
        role == 'admin' ? UserModel.mockAdmin() : UserModel.mockUser();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}

/// An [InheritedNotifier] that exposes [AuthNotifier] to the whole tree,
/// crossing Navigator boundaries (unlike [findAncestorStateOfType]).
class AuthStateWidget extends InheritedNotifier<AuthNotifier> {
  const AuthStateWidget({
    super.key,
    required AuthNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AuthNotifier of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AuthStateWidget>();
    assert(widget != null, 'No AuthStateWidget found in the widget tree.');
    return widget!.notifier!;
  }
}
