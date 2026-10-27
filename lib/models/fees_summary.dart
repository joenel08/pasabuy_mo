class UnpaidFee {
  final int transactionId;
  final String itemTitle;
  final String itemDescription;
  final String postTitle;
  final double agreedPrice;
  final double adminFee;
  final DateTime completedAt;
  final int daysOld;

  UnpaidFee({
    required this.transactionId,
    required this.itemTitle,
    required this.itemDescription,
    required this.postTitle,
    required this.agreedPrice,
    required this.adminFee,
    required this.completedAt,
    required this.daysOld,
  });

  factory UnpaidFee.fromJson(Map<String, dynamic> j) => UnpaidFee(
        transactionId: (j['transaction_id'] ?? 0) as int,
        itemTitle: (j['item_title'] ?? '').toString(),
        itemDescription: (j['item_description'] ?? '').toString(),
        postTitle: (j['post_title'] ?? '').toString(),
        agreedPrice: _d(j['agreed_price']),
        adminFee: _d(j['admin_fee']),
        completedAt:
            DateTime.tryParse(j['completed_at']?.toString() ?? '') ??
                DateTime.now(),
        daysOld: (j['days_old'] ?? 0) as int,
      );
}

class PaidFee {
  final int transactionId;
  final double adminFee;
  final DateTime paidAt;
  final String notes;

  PaidFee({
    required this.transactionId,
    required this.adminFee,
    required this.paidAt,
    required this.notes,
  });

  factory PaidFee.fromJson(Map<String, dynamic> j) => PaidFee(
        transactionId: (j['transaction_id'] ?? 0) as int,
        adminFee: _d(j['admin_fee']),
        paidAt: DateTime.tryParse(j['paid_at']?.toString() ?? '') ??
            DateTime.now(),
        notes: (j['notes'] ?? '').toString(),
      );
}

class FeesData {
  final int unpaidCount;
  final double unpaidTotal;
  final String? oldestUnpaidAt;
  final int daysOldest;
  final bool isBlocked;
  final String? blockReason;
  final bool isWarning;
  final List<UnpaidFee> items;
  final List<PaidFee> history;
  final String gcashNumber;
  final String gcashName;

  FeesData({
    required this.unpaidCount,
    required this.unpaidTotal,
    this.oldestUnpaidAt,
    required this.daysOldest,
    required this.isBlocked,
    this.blockReason,
    required this.isWarning,
    required this.items,
    required this.history,
    required this.gcashNumber,
    required this.gcashName,
  });

  factory FeesData.fromJson(Map<String, dynamic> j) {
    final summary = (j['summary'] ?? {}) as Map;
    final payment = (j['payment'] ?? {}) as Map;
    return FeesData(
      unpaidCount: (summary['unpaid_count'] ?? 0) as int,
      unpaidTotal: _d(summary['unpaid_total']),
      oldestUnpaidAt: summary['oldest_unpaid_at'] as String?,
      daysOldest: (summary['days_oldest'] ?? 0) as int,
      isBlocked: summary['is_blocked'] == true,
      blockReason: summary['block_reason'] as String?,
      isWarning: summary['is_warning'] == true,
      items: ((j['items'] ?? []) as List)
          .whereType<Map>()
          .map((m) => UnpaidFee.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      history: ((j['history'] ?? []) as List)
          .whereType<Map>()
          .map((m) => PaidFee.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      gcashNumber: (payment['gcash_number'] ?? '').toString(),
      gcashName: (payment['gcash_name'] ?? '').toString(),
    );
  }
}

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}