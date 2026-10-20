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
  final List<String> images;
  final String ownerName;
  final int? slots;
  final int slotsTaken;
  final bool isFavorite;
  final String? ownerAvatar;

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
    this.images = const [],
    this.ownerName = '',
    this.slots,
    this.slotsTaken = 0,
    this.isFavorite = false,
    this.ownerAvatar,
  });

  bool get isClosed =>
      status == 'closed' || status == 'cancelled' || status == 'completed';
  bool get isOffer => type == 'offer';
  bool get isFull => slots != null && slotsTaken >= slots!;
  int? get slotsLeft => slots == null ? null : (slots! - slotsTaken);

  Post copyWith({bool? isFavorite}) => Post(
        id: id,
        ownerId: ownerId,
        type: type,
        title: title,
        description: description,
        originLocation: originLocation,
        destinationLocation: destinationLocation,
        travelDate: travelDate,
        status: status,
        images: images,
        ownerName: ownerName,
        slots: slots,
        slotsTaken: slotsTaken,
        isFavorite: isFavorite ?? this.isFavorite,
        ownerAvatar: ownerAvatar,
      );

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as int,
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
        images: (j['images'] as List?)?.cast<String>() ?? const [],
        ownerName: (j['owner_name'] ?? '').toString(),
        slots: j['slots'] is int ? j['slots'] as int : null,
        slotsTaken: (j['slots_taken'] ?? 0) as int,
        isFavorite: j['is_favorite'] == true,
        ownerAvatar: j['owner_avatar'] as String?,
      );
}