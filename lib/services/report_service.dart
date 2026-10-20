import '../core/api_client.dart';

class ReportService {
  final ApiClient _api;
  ReportService(this._api);

  Future<void> submit({
    required String targetType, // user|post|message|transaction
    required int targetId,
    required String reason,
    String? description,
  }) async {
    await _api.dio.post('/reports', data: {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}