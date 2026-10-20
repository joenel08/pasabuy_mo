class Conversation {
  final int id;
  final int postId;
  final String postTitle;
  final String postType;
  final String otherPartyEmail;
  final String otherPartyName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;

  Conversation({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.postType,
    required this.otherPartyEmail,
    this.otherPartyName = '',
    this.lastMessage,
    this.lastMessageAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] ?? 0) as int,
        postId: (j['post_id'] ?? 0) as int,
        postTitle: (j['post_title'] ?? '').toString(),
        postType: (j['post_type'] ?? 'offer').toString(),
        otherPartyEmail: (j['other_party_email'] ?? '').toString(),
        otherPartyName: (j['other_party_name'] ?? '').toString(),
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.tryParse(j['last_message_at'].toString())
            : null,
        unread: (j['unread'] ?? 0) as int,
      );
}