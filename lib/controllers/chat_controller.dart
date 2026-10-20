import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/conversation_service.dart';

class ChatController extends ChangeNotifier {
  final ConversationService _service;
  final int conversationId;
  ChatController(this._service, this.conversationId);

  // ---- Exposed state ----
  List<Message> messages = [];
  String postTitle = '';
  String postType = 'offer';
  String otherEmail = '';
  String otherName = '';
  String? otherAvatar;
  int? otherPartyId;

  bool loading = false;
  bool sending = false;
  Timer? _poll;

  void startPolling() {
    _load();
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final r = await _service.messages(conversationId);

      final changed = r.messages.length != messages.length ||
          postTitle != r.postTitle ||
          otherEmail != r.otherEmail ||
          otherName != r.otherName ||
          otherAvatar != r.otherAvatar ||
          otherPartyId != r.otherId;

      messages = r.messages;
      postTitle = r.postTitle;
      postType = r.postType;
      otherEmail = r.otherEmail;
      otherName = r.otherName;
      otherAvatar = r.otherAvatar;
      otherPartyId = r.otherId;

      if (changed || !silent) notifyListeners();
    } catch (e) {
      debugPrint('[CHAT] load error: $e');
    }
    if (!silent) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> send(String body) async {
    if (body.trim().isEmpty) return;
    sending = true;
    notifyListeners();
    try {
      final m = await _service.send(conversationId, body.trim());
      messages = [...messages, m];
    } catch (e) {
      debugPrint('[CHAT] send error: $e');
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> sendImage(File file) async {
    sending = true;
    notifyListeners();
    try {
      final m = await _service.sendWithImage(conversationId, file);
      messages = [...messages, m];
    } catch (e) {
      debugPrint('[CHAT] sendImage error: $e');
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}