import '../core/api_client.dart';
import '../models/notification_item.dart';

class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  /// GET /notifications returns:
  ///   {"success":true,"data":{"data":[...],"unread_count":4}}
  Future<({List<NotificationItem> items, int unread})> list() async {
    final res = await _api.dio.get('/notifications');

    final envelope = res.data;
    if (envelope is! Map) return (items: <NotificationItem>[], unread: 0);

    final inner = envelope['data'];
    if (inner is! Map) return (items: <NotificationItem>[], unread: 0);

    final list = inner['data'];
    final items = (list is List)
        ? list
            .whereType<Map>()
            .map((m) => NotificationItem.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <NotificationItem>[];

    final unread = inner['unread_count'] is int
        ? inner['unread_count'] as int
        : 0;

    return (items: items, unread: unread);
  }

  /// GET /notifications/unread-count returns:
  ///   {"success":true,"data":{"count":4}}
  Future<int> unreadCount() async {
    final res = await _api.dio.get('/notifications/unread-count');

    final envelope = res.data;
    if (envelope is! Map) return 0;

    final inner = envelope['data'];
    if (inner is! Map) return 0;

    final c = inner['count'];
    return c is int ? c : 0;
  }

  Future<void> markRead(int id) async {
    await _api.dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.dio.post('/notifications/read-all');
  }
}