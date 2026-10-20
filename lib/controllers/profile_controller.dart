import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _service;
  ProfileController(this._service);

  Profile? profile;
  bool loading = false;
  bool submitting = false;
  String? error;

  Future<void> load() async {
    loading = true; notifyListeners();
    try {
      profile = await _service.get();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<bool> submit(Map<String, String> data) async {
    submitting = true; error = null; notifyListeners();
    try {
      await _service.saveProfile(
        lastname: data['lastname']!,
        firstname: data['firstname']!,
        middlename: data['middlename'],
        extname: data['extname'],
        streetPurok: data['street_purok']!,
        barangay: data['barangay']!,
        cityMunicipality: data['city_municipality']!,
        province: data['province']!,
        country: data['country']!,
        zipCode: data['zip_code']!,
      );
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      submitting = false; notifyListeners();
    }
  }

  Future<void> uploadAvatar(File file) async {
    await _service.uploadAvatar(file);
    await load();
  }
}