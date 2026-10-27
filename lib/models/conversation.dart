class Conversation {
  final int id;
  final int postId;
  final int? itemId;
  final String postTitle;
  final String itemTitle;
  final String postType;
  final String otherPartyEmail;
  final String otherPartyName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;
  final bool pinned;
  final DateTime? pinnedAt;

  Conversation({
    required this.id,
    required this.postId,
    this.itemId,
    required this.postTitle,
    this.itemTitle = '',
    required this.postType,
    required this.otherPartyEmail,
    this.otherPartyName = '',
    this.lastMessage,
    this.lastMessageAt,
    this.unread = 0,
    this.pinned = false,
    this.pinnedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] ?? 0) as int,
        postId: (j['post_id'] ?? 0) as int,
        itemId: j['item_id'] is int ? j['item_id'] as int : null,
        postTitle: (j['post_title'] ?? '').toString(),
        itemTitle: (j['item_title'] ?? '').toString(),
        postType: (j['post_type'] ?? 'offer').toString(),
        otherPartyEmail: (j['other_party_email'] ?? '').toString(),
        otherPartyName: (j['other_party_name'] ?? '').toString(),
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.tryParse(j['last_message_at'].toString())
            : null,
        unread: (j['unread'] ?? 0) as int,
        pinned: j['pinned'] == true,
        pinnedAt: j['pinned_at'] != null
            ? DateTime.tryParse(j['pinned_at'].toString())
            : null,
      );
}