import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthController extends ChangeNotifier {
  final AuthService _service;
  AuthController(this._service);

  AuthStatus status = AuthStatus.unknown;
  User? user;

  bool get loggedIn => status == AuthStatus.loggedIn && user != null;
  bool get emailVerified => user?.emailVerified ?? false;
  bool get profileCompleted => user?.profileCompleted ?? false;
  String get kycStatus => user?.kycStatus ?? 'none';

  Future<void> bootstrap() async {
    try {
      final u = await _service.me();
      user = u;
      status = u == null ? AuthStatus.loggedOut : AuthStatus.loggedIn;
    } catch (e) {
      debugPrint('[AUTH] bootstrap failed: $e');
      user = null;
      status = AuthStatus.loggedOut;
    } finally {
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    user = await _service.login(email, password);
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<void> register(String email, String password, String role) async {
    await _service.register(email, password, role);
  }

  Future<void> verifyEmail(String email, String code) async {
    await _service.verifyEmail(email, code);
  }

  Future<void> refreshMe() async {
    try {
      final u = await _service.me();
      user = u;
      status = u == null ? AuthStatus.loggedOut : AuthStatus.loggedIn;
    } catch (e) {
      debugPrint('[AUTH] refreshMe failed: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}