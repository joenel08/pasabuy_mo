import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/post.dart';

class PostService {
  final ApiClient _api;
  PostService(this._api);

  Future<List<Post>> fetch({
    String? search,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? location,
    String? status,
    bool mine = false,
    int page = 1,
  }) async {
    final res = await _api.dio.get('/posts', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
      if (location != null && location.isNotEmpty) 'location': location,
      if (status != null) 'status': status,
      if (mine) 'mine': '1',
      'page': page,
    });
    final envelope = res.data;
    if (envelope is! Map) return const [];
    final payload = envelope['data'];
    if (payload is! Map) return const [];
    final list = payload['data'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => Post.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> create({
    required String title,
    required String description,
    required String type,
    String? originLocation,
    String? destinationLocation,
    DateTime? travelDate,
    int? slots,
    List<File> images = const [],
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'description': description,
      'type': type,
      if (originLocation != null) 'origin_location': originLocation,
      if (destinationLocation != null)
        'destination_location': destinationLocation,
      if (travelDate != null)
        'travel_date':
            '${travelDate.year}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}',
      if (slots != null) 'slots': slots,
      if (images.isNotEmpty)
        'images': await Future.wait(
            images.map((f) => MultipartFile.fromFile(f.path))),
    });
    final res = await _api.dio.post('/posts', data: form);
    return res.data['data']['id'] as int;
  }

  Future<void> close(int postId) async {
    await _api.dio.post('/posts/$postId/close');
  }

  Future<void> destroy(int postId) async {
    await _api.dio.delete('/posts/$postId');
  }

  Future<void> updateFull({
    required int postId,
    required String title,
    required String description,
    required String type,
    String? originLocation,
    String? destinationLocation,
    DateTime? travelDate,
    int? slots,
    List<File> newImages = const [],
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'description': description,
      'type': type,
      if (originLocation != null) 'origin_location': originLocation,
      if (destinationLocation != null)
        'destination_location': destinationLocation,
      if (travelDate != null)
        'travel_date':
            '${travelDate.year}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}',
      if (slots != null) 'slots': slots,
      if (newImages.isNotEmpty)
        'images': await Future.wait(
            newImages.map((f) => MultipartFile.fromFile(f.path))),
    });
    await _api.dio.put('/posts/$postId/full', data: form);
  }
}