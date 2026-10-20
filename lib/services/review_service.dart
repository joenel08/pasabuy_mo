import '../core/api_client.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _api;
  ReviewService(this._api);

  Future<({
    List<Review> items,
    double? average,
    int total,
    Map<int, int> distribution,
  })> forUser(int userId) async {
    final res = await _api.dio.get('/users/$userId/reviews');
    final inner = res.data['data'];

    final list = (inner is Map) ? inner['data'] : null;
    final items = (list is List)
        ? list
            .whereType<Map>()
            .map((m) => Review.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <Review>[];

    double? average;
    if (inner is Map && inner['average'] != null) {
      average = (inner['average'] as num).toDouble();
    }

    final total = (inner is Map) ? (inner['total'] ?? 0) as int : 0;

    final distRaw = (inner is Map) ? inner['distribution'] : null;
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    if (distRaw is Map) {
      distRaw.forEach((k, v) {
        final key = int.tryParse(k.toString());
        if (key != null && key >= 1 && key <= 5) {
          distribution[key] = (v as num).toInt();
        }
      });
    }

    return (
      items: items,
      average: average,
      total: total,
      distribution: distribution,
    );
  }

  Future<({bool canReview, int? transactionId})> eligibility(int userId) async {
    final res = await _api.dio.get('/users/$userId/review-eligibility');
    final data = res.data['data'];
    return (
      canReview: data?['can_review'] == true,
      transactionId: data?['transaction_id'] as int?,
    );
  }

  Future<List<PendingReview>> pending() async {
    final res = await _api.dio.get('/me/reviews/pending');
    final inner = res.data['data'];
    final list = (inner is Map) ? inner['data'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => PendingReview.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> submit({
    required int transactionId,
    required int rating,
    String? description,
  }) async {
    await _api.dio.post('/transactions/$transactionId/review', data: {
      'rating': rating,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}