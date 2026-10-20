import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../core/router.dart';
import 'api_client.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _token;

  static const _channelId = 'pasabuy_high';
  static const _channelName = 'PasaBuy notifications';

  String? get token => _token;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Ask permission (no-op on Android < 13)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // 2. Local notifications channel (for foreground display)
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _local.initialize(
      init,
      onDidReceiveNotificationResponse: (r) {
        final payload = r.payload;
        if (payload != null && payload.isNotEmpty) {
          AppRouter.router.push(payload);
        }
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          description: 'PasaBuy push notifications',
        ));

    // 3. Get token and subscribe to refresh
    await _refreshToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      _uploadToken(t);
    });

    // 4. Foreground messages → show locally
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM FG] ${msg.messageId} ${msg.data}');
      _showLocal(msg);
    });

    // 5. User tapped a notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // 6. App was killed and opened from a notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      _routeFromMessage(initial);
    }
  }

  Future<void> _refreshToken() async {
    try {
      _token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] token: $_token');
      if (_token != null) await _uploadToken(_token!);
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      final api = ApiClient();
      await api.dio.post('/me/fcm-token', data: {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
      debugPrint('[FCM] token registered');
    } catch (e) {
      debugPrint('[FCM] token upload failed: $e');
    }
  }

  Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _payloadFromData(msg.data),
    );
  }

  void _routeFromMessage(RemoteMessage msg) {
    final route = _payloadFromData(msg.data);
    if (route.isNotEmpty) AppRouter.router.push(route);
  }

  String _payloadFromData(Map<String, dynamic> data) {
    final convId = data['conversation_id'];
    if (convId != null) return '/messages/$convId';
    final txId = data['transaction_id'];
    if (txId != null) return '/deals';
    if (data['route'] is String) return data['route'] as String;
    return '';
  }
}