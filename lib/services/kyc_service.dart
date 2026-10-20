import 'package:dio/dio.dart';
import '../core/api_client.dart';

class KycService {
  final ApiClient _api;
  KycService(this._api);

  Future<void> submit({
    required String idType,
    required String idNumber,
    required DateTime dateIssued,
    required String frontPath,
    String? backPath,
  }) async {
    final form = FormData.fromMap({
      'id_type': idType,
      'id_number': idNumber,
      'date_issued':
          '${dateIssued.year}-${dateIssued.month.toString().padLeft(2, '0')}-${dateIssued.day.toString().padLeft(2, '0')}',
      'front': await MultipartFile.fromFile(frontPath),
      if (backPath != null) 'back': await MultipartFile.fromFile(backPath),
    });
    await _api.dio.post('/me/kyc', data: form);
  }
}