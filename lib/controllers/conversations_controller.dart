import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

class ConversationsController extends ChangeNotifier {
  final ConversationService _service;
  ConversationsController(this._service);

  List<Conversation> items = [];
  bool loading = false;
  void removeLocal(int conversationId) {
    items = items.where((c) => c.id != conversationId).toList();
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      items = await _service.list();
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  Future<int> startWith(int postId) => _service.start(postId);
}
