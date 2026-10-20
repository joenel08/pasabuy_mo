class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'],
        type: j['type'] ?? '',
        title: j['title'] ?? '',
        body: j['body'],
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? {},
        read: j['read'] == true,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}