class Transaction {
  final int id;
  final int conversationId;
  final int? postId;
  final int? itemId;
  final String postTitle;
  final String itemTitle;
  final String postType;
  final String role;
  final String otherPartyEmail;
  final String itemDescription;
  final double? agreedPrice;
  final double? adminFee;
  final double? netPayout;
  final double? feeRate;
  final String currency;
  final String status;
  final bool buyerDone;
  final bool pasabuyerDone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? proposedByUserId;
  final String? proofImageUrl;
  final bool feePaid;
final DateTime? feePaidAt;

  Transaction({
    required this.id,
    required this.conversationId,
    this.postId,
    this.itemId,
    required this.postTitle,
    this.itemTitle = '',
    required this.postType,
    required this.role,
    required this.otherPartyEmail,
    required this.itemDescription,
    this.agreedPrice,
    this.adminFee,
    this.netPayout,
    this.feeRate,
    required this.currency,
    required this.status,
    required this.buyerDone,
    required this.pasabuyerDone,
    required this.createdAt,
    this.completedAt,
    this.proposedByUserId,
    this.proofImageUrl,
    this.feePaid = false,
this.feePaidAt,
  });

  bool get isActive => const [
        'pending',
        'in_progress',
        'buyer_done',
        'pasabuyer_done',
      ].contains(status);

  bool get isCompleted => status == 'completed';
  bool get iHaveDone => role == 'buyer' ? buyerDone : pasabuyerDone;

  bool iProposedDeal(int? myUserId) =>
      myUserId != null && proposedByUserId == myUserId;

  bool iMustAccept(int? myUserId) =>
      status == 'pending' && !iProposedDeal(myUserId);

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as int? ?? 0,
        postId: j['post_id'] is int ? j['post_id'] as int : null,
        itemId: j['item_id'] is int ? j['item_id'] as int : null,
        postTitle: (j['post_title'] ?? '').toString(),
        itemTitle: (j['item_title'] ?? '').toString(),
        postType: (j['post_type'] ?? 'offer').toString(),
        role: (j['role'] ?? 'buyer').toString(),
        otherPartyEmail: (j['other_party_email'] ?? '').toString(),
        itemDescription: (j['item_description'] ?? '').toString(),
        agreedPrice: _toDouble(j['agreed_price']),
        adminFee: _toDouble(j['admin_fee']),
        netPayout: _toDouble(j['net_payout']),
        feeRate: _toDouble(j['fee_rate']),
        currency: (j['currency'] ?? 'PHP').toString(),
        status: (j['status'] ?? 'pending').toString(),
        buyerDone: j['buyer_done'] == true,
        pasabuyerDone: j['pasabuyer_done'] == true,
        proofImageUrl: j['proof_image_url'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'].toString())
            : null,
        proposedByUserId: j['proposed_by_user_id'] is int
            ? j['proposed_by_user_id'] as int
            : int.tryParse(j['proposed_by_user_id']?.toString() ?? ''),
            feePaid: j['fee_paid'] == true,
feePaidAt: j['fee_paid_at'] != null
    ? DateTime.tryParse(j['fee_paid_at'].toString())
    : null,
      );
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}