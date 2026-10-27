class PostItem {
  final int id;
  final String title;
  final String description;
  final int? slots;
  final int slotsTaken;
  final List<String> images;

  PostItem({
    required this.id,
    required this.title,
    required this.description,
    this.slots,
    this.slotsTaken = 0,
    this.images = const [],
  });

  bool get isFull => slots != null && slotsTaken >= slots!;
  int? get slotsLeft => slots == null ? null : (slots! - slotsTaken);

  factory PostItem.fromJson(Map<String, dynamic> j) => PostItem(
        id: (j['id'] ?? 0) as int,
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        slots: j['slots'] is int ? j['slots'] as int : null,
        slotsTaken: (j['slots_taken'] ?? 0) as int,
        images: (j['images'] as List?)?.cast<String>() ?? const [],
      );
}