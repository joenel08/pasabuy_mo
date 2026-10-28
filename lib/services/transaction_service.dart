import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction.dart';
import '../models/fees_summary.dart';

class TransactionService {
  final ApiClient _api;
  TransactionService(this._api);

  /// Propose a deal. `proofImage` is optional.
  Future<int> propose({
    required int conversationId,
    required String itemDescription,
    double? agreedPrice,
    String? notes,
    File? proofImage,
  }) async {
    final data = <String, dynamic>{
      'item_description': itemDescription,
      if (agreedPrice != null) 'agreed_price': agreedPrice,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (proofImage != null)
        'proof_image': await MultipartFile.fromFile(proofImage.path),
    };

    final res = await _api.dio.post(
      '/conversations/$conversationId/deals',
      data: FormData.fromMap(data),
    );

    final envelope = res.data;
    if (envelope is! Map) {
      throw Exception('Unexpected response format');
    }
    final inner = envelope['data'];
    if (inner is! Map) {
      throw Exception(
          envelope['message']?.toString() ?? 'Could not propose deal');
    }
    final id = inner['id'];
    if (id is! int) throw Exception('Missing deal id in response');
    return id;
  }

  Future<void> accept(int id) => _api.dio.post('/deals/$id/accept');

  Future<void> decline(int id, {String? reason}) =>
      _api.dio.post('/deals/$id/decline', data: {'reason': reason ?? ''});

  Future<void> done(int id) => _api.dio.post('/deals/$id/done');

  Future<void> dispute(int id, String reason) =>
      _api.dio.post('/deals/$id/dispute', data: {'reason': reason});

  Future<List<Transaction>> myDeals() async {
    final res = await _api.dio.get('/me/deals');
    final envelope = res.data;
    if (envelope is! Map) return const [];
    final inner = envelope['data'];
    if (inner is! Map) return const [];
    final list = inner['data'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => Transaction.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Map<String, dynamic>> myStats() async {
    final res = await _api.dio.get('/me/stats');
    final envelope = res.data;
    if (envelope is! Map) return const {};
    final inner = envelope['data'];
    if (inner is! Map) return const {};
    return Map<String, dynamic>.from(inner);
  }

  Future<Map<String, dynamic>> myTrend({String range = '30d'}) async {
    final res = await _api.dio.get(
      '/me/stats/trend',
      queryParameters: {'range': range},
    );
    final envelope = res.data;
    if (envelope is! Map) return const {};
    final inner = envelope['data'];
    if (inner is! Map) return const {};
    return Map<String, dynamic>.from(inner);
  }

  Future<List<Map<String, dynamic>>> myItemsBreakdown(
      {String range = 'all'}) async {
    final res = await _api.dio.get(
      '/me/stats/by-item',
      queryParameters: {'range': range},
    );
    final envelope = res.data;
    if (envelope is! Map) return const [];
    final inner = envelope['data'];
    if (inner is! Map) return const [];
    final list = inner['data'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<FeesData> myFees() async {
    final res = await _api.dio.get('/me/fees');
    final envelope = res.data;
    if (envelope is! Map) throw Exception('Unexpected response');
    final inner = envelope['data'];
    if (inner is! Map) throw Exception('Unexpected response');
    return FeesData.fromJson(Map<String, dynamic>.from(inner));
  }


  Future<int> submitFeeClaim({
  required double amount,
  required String gcashReference,
  required String gcashSenderName,
  File? proofImage,
}) async {
  final data = <String, dynamic>{
    'amount': amount,
    'gcash_reference': gcashReference,
    'gcash_sender_name': gcashSenderName,
    if (proofImage != null)
      'proof_image': await MultipartFile.fromFile(proofImage.path),
  };
  final res = await _api.dio.post(
    '/me/fees/claim',
    data: FormData.fromMap(data),
  );
  return res.data['data']['claim_id'] as int;
}

Future<List<FeeClaim>> myFeeClaims() async {
  final res = await _api.dio.get('/me/fees/claims');
  final envelope = res.data;
  if (envelope is! Map) return const [];
  final inner = envelope['data'];
  if (inner is! Map) return const [];
  final list = inner['data'];
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((m) => FeeClaim.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}
}
