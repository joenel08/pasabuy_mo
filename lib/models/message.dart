class Message {
  final int id;
  final int senderId;
  final String senderEmail;
  final String? body;
  final String? attachmentUrl;
  final bool mine;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    this.body,
    this.attachmentUrl,
    required this.mine,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'],
        senderId: j['sender_id'],
        senderEmail: j['sender_email'] ?? '',
        body: j['body'],
        attachmentUrl: j['attachment_url'],
        mine: j['mine'] == true,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}