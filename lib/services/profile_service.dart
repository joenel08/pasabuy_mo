import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/profile.dart';

class ProfileService {
  final ApiClient _api;
  ProfileService(this._api);

  Future<Profile?> get() async {
    final res = await _api.dio.get('/me/profile');
    final data = res.data['data'];
    if (data == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveProfile({
    required String lastname,
    required String firstname,
    String? middlename,
    String? extname,
    required String streetPurok,
    required String barangay,
    required String cityMunicipality,
    required String province,
    required String country,
    required String zipCode,
  }) async {
    await _api.dio.put('/me/profile', data: {
      'lastname': lastname,
      'firstname': firstname,
      'middlename': middlename,
      'extname': extname,
      'street_purok': streetPurok,
      'barangay': barangay,
      'city_municipality': cityMunicipality,
      'province': province,
      'country': country,
      'zip_code': zipCode,
    });
  }

  Future<String> uploadAvatar(File file) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });
    final res = await _api.dio.post('/me/avatar', data: form);
    return res.data['data']['avatar_path'] as String;
  }

  Future<Map<String, dynamic>> publicProfile(int userId) async {
    final res = await _api.dio.get('/users/$userId');
    final envelope = res.data;
    if (envelope is! Map) return const {};
    final inner = envelope['data'];
    if (inner is! Map) return const {};
    return Map<String, dynamic>.from(inner);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _api.dio.post('/me/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }
}
