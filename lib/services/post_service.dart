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
    required List<({
      String title,
      String description,
      int? slots,
      List<File> images,
    })> items,
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('title', title));
    form.fields.add(MapEntry('description', description));
    form.fields.add(MapEntry('type', type));
    if (originLocation != null && originLocation.isNotEmpty) {
      form.fields.add(MapEntry('origin_location', originLocation));
    }
    if (destinationLocation != null && destinationLocation.isNotEmpty) {
      form.fields.add(MapEntry('destination_location', destinationLocation));
    }
    if (travelDate != null) {
      form.fields.add(MapEntry(
        'travel_date',
        '${travelDate.year}-'
            '${travelDate.month.toString().padLeft(2, '0')}-'
            '${travelDate.day.toString().padLeft(2, '0')}',
      ));
    }

    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      form.fields.add(MapEntry('items[$i][title]', it.title));
      form.fields.add(MapEntry('items[$i][description]', it.description));
      if (it.slots != null) {
        form.fields.add(MapEntry('items[$i][slots]', '${it.slots}'));
      }
      for (final f in it.images) {
        form.files.add(MapEntry(
          'item_images[$i][]',
          await MultipartFile.fromFile(f.path),
        ));
      }
    }

    final res = await _api.dio.post('/posts', data: form);
    return res.data['data']['id'] as int;
  }
Future<void> updateFull({
  required int postId,
  required String title,
  required String description,
  required String type,
  String? originLocation,
  String? destinationLocation,
  DateTime? travelDate,
  required List<({
    int? id,                    // null = new item
    String title,
    String description,
    int? slots,
    List<File> newImages,       // only files picked NOW (empty = keep existing)
  })> items,
}) async {
  final form = FormData();
  form.fields.add(MapEntry('title', title));
  form.fields.add(MapEntry('description', description));
  form.fields.add(MapEntry('type', type));
  if (originLocation != null && originLocation.isNotEmpty) {
    form.fields.add(MapEntry('origin_location', originLocation));
  }
  if (destinationLocation != null && destinationLocation.isNotEmpty) {
    form.fields.add(MapEntry('destination_location', destinationLocation));
  }
  if (travelDate != null) {
    form.fields.add(MapEntry(
      'travel_date',
      '${travelDate.year}-'
          '${travelDate.month.toString().padLeft(2, '0')}-'
          '${travelDate.day.toString().padLeft(2, '0')}',
    ));
  }

  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    if (it.id != null) {
      form.fields.add(MapEntry('items[$i][id]', '${it.id}'));
    }
    form.fields.add(MapEntry('items[$i][title]', it.title));
    form.fields.add(MapEntry('items[$i][description]', it.description));
    if (it.slots != null) {
      form.fields.add(MapEntry('items[$i][slots]', '${it.slots}'));
    }
    for (final f in it.newImages) {
      form.files.add(MapEntry(
        'item_images[$i][]',
        await MultipartFile.fromFile(f.path),
      ));
    }
  }

 await _api.dio.post('/posts/$postId/full', data: form);
}
  Future<void> close(int postId) async {
    await _api.dio.post('/posts/$postId/close');
  }

  Future<void> destroy(int postId) async {
    await _api.dio.delete('/posts/$postId');
  }
}