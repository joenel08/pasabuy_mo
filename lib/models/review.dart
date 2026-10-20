class Review {
  final int id;
  final int rating;
  final String? description;
  final String reviewerEmail;
  final DateTime createdAt;
  Review({
    required this.id,
    required this.rating,
    this.description,
    required this.reviewerEmail,
    required this.createdAt,
  });
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'],
        rating: j['rating'] ?? 0,
        description: j['description'],
        reviewerEmail: j['reviewer_email'] ?? '',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class PendingReview {
  final int transactionId;
  final String itemDescription;
  final String otherParty;
  final DateTime? completedAt;
  PendingReview({
    required this.transactionId,
    required this.itemDescription,
    required this.otherParty,
    this.completedAt,
  });
  factory PendingReview.fromJson(Map<String, dynamic> j) => PendingReview(
        transactionId: j['transaction_id'],
        itemDescription: j['item_description'] ?? '',
        otherParty: j['other_party'] ?? '',
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'])
            : null,
      );
}