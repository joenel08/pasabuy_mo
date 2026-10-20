import 'package:flutter/foundation.dart';
import '../services/kyc_service.dart';

class KycController extends ChangeNotifier {
  final KycService _service;
  KycController(this._service);

  bool submitting = false;
  String? error;

  Future<bool> submit({
    required String idType,
    required String idNumber,
    required DateTime dateIssued,
    required String frontPath,
    String? backPath,
  }) async {
    submitting = true;
    error = null;
    notifyListeners();
    try {
      await _service.submit(
        idType: idType,
        idNumber: idNumber,
        dateIssued: dateIssued,
        frontPath: frontPath,
        backPath: backPath,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}