import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<void> register(String email, String password, String role) async {
    await _api.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<void> verifyEmail(String email, String code) async {
    await _api.dio.post('/auth/verify-email', data: {
      'email': email,
      'code': code,
    });
  }

  Future<User> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final envelope = res.data;
    if (envelope is! Map) {
      throw Exception('Login: unexpected response type ${envelope.runtimeType}');
    }
    final payload = envelope['data'];
    if (payload is! Map) {
      throw Exception('Login: missing data envelope');
    }

    final token = payload['token'];
    if (token is! String) {
      throw Exception('Login: missing token');
    }
    await _api.saveToken(token);

    final userJson = payload['user'];
    if (userJson is! Map) {
      throw Exception('Login: missing user');
    }
    return User.fromJson(Map<String, dynamic>.from(userJson));
  }

  Future<User?> me() async {
    try {
      final res = await _api.dio.get('/me');
      final envelope = res.data;
      if (envelope is! Map) return null;
      final payload = envelope['data'];
      if (payload is! Map) return null;
      return User.fromJson(Map<String, dynamic>.from(payload));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
  }
}