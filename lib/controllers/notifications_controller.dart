import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsController extends ChangeNotifier {
  final NotificationService _service;
  NotificationsController(this._service);

  List<NotificationItem> items = [];
  int unread = 0;
  bool loading = false;
  Timer? _poll;

  void startPolling() {
    _poll?.cancel();
    _refreshUnread();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final c = await _service.unreadCount();
      if (c != unread) { unread = c; notifyListeners(); }
    } catch (_) {}
  }

  Future<void> load() async {
    loading = true; notifyListeners();
    try {
      final r = await _service.list();
      items = r.items;
      unread = r.unread;
    } catch (_) {}
    loading = false; notifyListeners();
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
    final i = items.indexWhere((x) => x.id == id);
    if (i != -1) {
      items[i] = NotificationItem(
        id: items[i].id, type: items[i].type, title: items[i].title,
        body: items[i].body, data: items[i].data, read: true,
        createdAt: items[i].createdAt,
      );
    }
    if (unread > 0) unread--;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    items = items.map((x) => NotificationItem(
      id: x.id, type: x.type, title: x.title, body: x.body,
      data: x.data, read: true, createdAt: x.createdAt,
    )).toList();
    unread = 0;
    notifyListeners();
  }
}