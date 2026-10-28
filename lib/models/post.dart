import 'post_item.dart';

class Post {
  final int id;
  final int ownerId;
  final String type;
  final String title;
  final String description;
  final String? originLocation;
  final String? destinationLocation;
  final DateTime? travelDate;
  final String status;
  final List<PostItem> items;
  final String ownerName;
  final String? ownerAvatar;
  final bool isFavorite;

  Post({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.description,
    this.originLocation,
    this.destinationLocation,
    this.travelDate,
    required this.status,
    this.items = const [],
    this.ownerName = '',
    this.ownerAvatar,
    this.isFavorite = false,
  });

  bool get isClosed =>
      status == 'closed' || status == 'cancelled' || status == 'completed';
  bool get isOffer => type == 'offer';

  bool get isExpired {
    if (travelDate == null) return false;
    final today = DateTime.now();
    final travel =
        DateTime(travelDate!.year, travelDate!.month, travelDate!.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    // Expired when travel date has arrived (today or past)
    return !travel.isAfter(todayDate);
  }

  /// Aggregate first image across items (for feed thumbnail)
  List<String> get images => items.expand((i) => i.images).toList();

  /// Total items still accepting buyers
  int get openItemCount => isClosed ? 0 : items.where((i) => !i.isFull).length;

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: (j['id'] ?? 0) as int,
        ownerId: (j['owner_id'] ?? 0) as int,
        type: (j['type'] ?? 'offer').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        originLocation: j['origin_location'] as String?,
        destinationLocation: j['destination_location'] as String?,
        travelDate: j['travel_date'] != null
            ? DateTime.tryParse(j['travel_date'].toString())
            : null,
        status: (j['status'] ?? 'open').toString(),
        items: (j['items'] as List?)
                ?.whereType<Map>()
                .map((m) => PostItem.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        ownerName: (j['owner_name'] ?? '').toString(),
        ownerAvatar: j['owner_avatar'] as String?,
        isFavorite: j['is_favorite'] == true,
      );
}
