import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ConversationService {
  final ApiClient _api;
  ConversationService(this._api);

  Future<List<Conversation>> list() async {
    final res = await _api.dio.get('/conversations');
    final inner = res.data['data'];
    final list = inner is Map ? inner['data'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => Conversation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> start(int itemId) async {
    final res =
        await _api.dio.post('/conversations', data: {'item_id': itemId});
    return res.data['data']['conversation_id'] as int;
  }

  Future<
      ({
        List<Message> messages,
        String postTitle,
        String postType,
        String itemTitle,
        String otherEmail,
        String otherName,
        String? otherAvatar,
        int? otherId,
      })> messages(int conversationId) async {
    final res = await _api.dio.get('/conversations/$conversationId/messages');

    final envelope = res.data;
    if (envelope is! Map) {
      return (
        messages: <Message>[],
        postTitle: '',
        postType: 'offer',
        itemTitle: '',
        otherEmail: '',
        otherName: '',
        otherAvatar: null,
        otherId: null,
      );
    }
    final inner = envelope['data'];
    if (inner is! Map) {
      return (
        messages: <Message>[],
        postTitle: '',
        postType: 'offer',
        itemTitle: '',
        otherEmail: '',
        otherName: '',
        otherAvatar: null,
        otherId: null,
      );
    }

    final list = inner['data'];
    final items = (list is List)
        ? list
            .whereType<Map>()
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <Message>[];

    return (
      messages: items,
      postTitle: (inner['post_title'] ?? '').toString(),
      postType: (inner['post_type'] ?? 'offer').toString(),
      itemTitle: (inner['item_title'] ?? '').toString(),
      otherEmail: (inner['other_party_email'] ?? '').toString(),
      otherName: (inner['other_party_name'] ?? '').toString(),
      otherAvatar: inner['other_party_avatar'] as String?,
      otherId: inner['other_party_id'] is int
          ? inner['other_party_id'] as int
          : null,
    );
  }

  Future<Message> send(int conversationId, String body) async {
    final res = await _api.dio.post(
      '/conversations/$conversationId/messages',
      data: {'body': body},
    );
    return Message(
      id: res.data['data']['id'] ?? 0,
      senderId: 0,
      senderEmail: '',
      body: body,
      attachmentUrl: null,
      mine: true,
      createdAt: DateTime.now(),
    );
  }

  Future<Message> sendWithImage(int conversationId, File file) async {
    final form = FormData.fromMap({
      'attachment': await MultipartFile.fromFile(file.path),
    });
    final res = await _api.dio.post(
      '/conversations/$conversationId/messages',
      data: form,
    );
    return Message(
      id: res.data['data']['id'] ?? 0,
      senderId: 0,
      senderEmail: '',
      body: null,
      attachmentUrl: null,
      mine: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> pin(int conversationId) async {
    await _api.dio.post('/conversations/$conversationId/pin');
  }

  Future<void> unpin(int conversationId) async {
    await _api.dio.post('/conversations/$conversationId/unpin');
  }

  Future<void> delete(int conversationId) async {
    await _api.dio.delete('/conversations/$conversationId');
  }
}
