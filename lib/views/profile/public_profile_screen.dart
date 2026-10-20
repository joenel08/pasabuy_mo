import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../models/review.dart';
import '../../services/profile_service.dart';
import '../../services/report_service.dart';
import '../../services/review_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  Map<String, dynamic>? _data;
  List<Review> _reviews = [];
  double? _avgRating;
  int _totalReviews = 0;
  bool _loading = true;
  bool _canReview = false;
  int? _reviewTransactionId;
  String _reviewMessage = '';
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p =
          await context.read<ProfileService>().publicProfile(widget.userId);
      final r = await context.read<ReviewService>().forUser(widget.userId);

      // Eligibility for leaving a review
      bool canReview = false;
      int? txId;
      try {
        final e =
            await context.read<ReviewService>().eligibility(widget.userId);
        canReview = e.canReview;
        txId = e.transactionId;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _data = p;
        _reviews = r.items;
        _avgRating = r.average;
        _totalReviews = r.total;
        _ratingDistribution = r.distribution;
        _canReview = canReview;
        _reviewTransactionId = txId;
      });
    } catch (e, st) {
      debugPrint('[PROFILE] $e');
      debugPrint('[PROFILE] $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reportUser() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(),
    );
    if (reason == null || !mounted) return;
    try {
      await context.read<ReportService>().submit(
            targetType: 'user',
            targetId: widget.userId,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Admin will review.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _openReviewDialog() async {
    final result = await showDialog<({int rating, String? text})>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (result == null || _reviewTransactionId == null || !mounted) return;

    try {
      await context.read<ReviewService>().submit(
            transactionId: _reviewTransactionId!,
            rating: result.rating,
            description: result.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not submit: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meId = context.watch<AuthController>().user?.id;
    final isSelf = meId == widget.userId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isSelf ? 'My profile' : 'Profile'),
        actions: [
          if (!isSelf)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Report',
              onPressed: _reportUser,
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: 'About'),
            Tab(
              text: 'Posts (${(_data?['recent_posts'] as List?)?.length ?? 0})',
            ),
            Tab(text: 'Reviews ($_totalReviews)'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _data == null
              ? const Center(child: Text('Could not load profile'))
              : TabBarView(
                  controller: _tab,
                  children: [
                    _buildAbout(),
                    _buildPosts(),
                    _buildReviews(),
                  ],
                ),
    );
  }

  // ---------------- About tab ----------------
  Widget _buildAbout() {
    final d = _data!;
    final name = (d['full_name'] as String?)?.trim();
    final display =
        (name == null || name.isEmpty) ? d['email'] as String : name;
    final email = d['email'] as String? ?? '';
    final location = d['location'] as String? ?? '';
    final avatarUrl = d['avatar_url'] as String?;
    final kyc = d['kyc_status'] as String? ?? 'none';
    final kycType = d['kyc_type'] as String?;
    final reviewed = d['kyc_reviewed_at'] as String?;
    final completed = d['completed_deals'] as int? ?? 0;
    final cancelled = d['cancelled_deals'] as int? ?? 0;
    final totalDeals = d['total_deals'] as int? ?? 0;
    final since = d['member_since'] as String?;
    final isVerified = kyc == 'accepted';

    final initials = display
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? const LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ])
                          : null,
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: avatarUrl == null
                        ? Center(
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (isVerified)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                display,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              _KycBadge(status: kyc, idType: kycType, reviewedAt: reviewed),
            ],
          ),
        ),

        // Rating summary
        // if (_avgRating != null) ...[
        //   const SizedBox(height: 12),
        //   _RatingSummary(avg: _avgRating!, total: _totalReviews),
        // ],

        // Stats
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.handshake_outlined,
                label: 'Completed',
                value: '$completed',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.cancel_outlined,
                label: 'Cancelled',
                value: '$cancelled',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Total',
                value: '$totalDeals',
                color: AppColors.info,
              ),
            ),
          ],
        ),

        // Location
        if (location.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(location,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ],

        // Member since
        if (since != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Member since ${DateFormat.yMMMM().format(DateTime.tryParse(since) ?? DateTime.now())}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],

        // Safety note
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryGhost,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primarySoft),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Safety first. ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: isVerified
                            ? 'This user submitted a government-issued $kycType and was verified by our admin team.'
                            : 'This user has not completed ID verification yet. Trade with caution.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Posts tab ----------------
  Widget _buildPosts() {
    final posts = (_data!['recent_posts'] as List?) ?? [];
    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No posts yet',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final p = posts[i] as Map;
        final img = p['image'] as String?;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              color: AppColors.surface,
              image: img != null
                  ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
                  : null,
            ),
            child: img == null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (p['title'] ?? '').toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          (p['status'] ?? '').toString(),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ---------------- Reviews tab ----------------
  Widget _buildReviews() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        // ---------- Big 5-star summary card ----------
        _StarSummaryCard(
          average: _avgRating,
          total: _totalReviews,
          distribution: _ratingDistribution,
          canReview: _canReview,
          onLeaveReview: _openReviewDialog,
        ),

        const SizedBox(height: 16),

        // ---------- Divider ----------
        if (_reviews.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ALL REVIEWS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: r),
              )),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 44, color: AppColors.textMuted.withOpacity(0.6)),
                const SizedBox(height: 12),
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Be the first to leave a review after a completed deal.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== Helpers ====================

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('How was this deal?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber[600],
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(hintText: 'Optional comment…'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            rating: _rating,
            text: _text.text.trim().isEmpty ? null : _text.text.trim(),
          )),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _ReportSheet extends StatefulWidget {
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    ('spam', 'Spam or unwanted content'),
    ('harassment', 'Harassment or bullying'),
    ('fake_id', 'Fake or stolen identity'),
    ('scam', 'Scam or fraudulent behaviour'),
    ('inappropriate', 'Inappropriate content'),
    ('off_platform', 'Asking to transact off-platform'),
    ('other', 'Something else'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Report this user',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Why are you reporting them?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ..._reasons.map(
                (r) => ListTile(
                  dense: true,
                  title: Text(r.$2, style: const TextStyle(fontSize: 13.5)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () => Navigator.pop(context, r.$1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final String status;
  final String? idType;
  final String? reviewedAt;
  const _KycBadge({required this.status, this.idType, this.reviewedAt});

  @override
  Widget build(BuildContext context) {
    final map = {
      'accepted': (
        AppColors.success,
        'Verified by admin',
        Icons.verified_rounded
      ),
      'pending': (AppColors.warning, 'Pending review', Icons.schedule_rounded),
      'declined': (
        AppColors.danger,
        'Verification declined',
        Icons.cancel_rounded
      ),
      'none': (AppColors.textMuted, 'Not verified', Icons.info_outline_rounded),
    };
    final (color, label, icon) = map[status] ?? map['none']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
        if (status == 'accepted' && idType != null) ...[
          const SizedBox(height: 8),
          Text(
            'Submitted a ${_pretty(idType!)}'
            '${reviewedAt != null ? ' · ' + DateFormat.yMMMd().format(DateTime.tryParse(reviewedAt!) ?? DateTime.now()) : ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  String _pretty(String t) {
    switch (t) {
      case 'philsys':
        return 'PhilSys National ID';
      case 'passport':
        return 'Passport';
      case 'drivers_license':
        return "Driver's License";
      case 'umid':
        return 'UMID';
      case 'sss':
        return 'SSS ID';
      case 'prc':
        return 'PRC ID';
      case 'voters':
        return "Voter's ID";
      case 'postal':
        return 'Postal ID';
      case 'senior':
        return 'Senior Citizen ID';
      default:
        return 'government-issued ID';
    }
  }
}

// ==================== Star Summary Card ====================

class _StarSummaryCard extends StatelessWidget {
  final double? average;
  final int total;
  final Map<int, int> distribution;
  final bool canReview;
  final VoidCallback onLeaveReview;

  const _StarSummaryCard({
    required this.average,
    required this.total,
    required this.distribution,
    required this.canReview,
    required this.onLeaveReview,
  });

  @override
  Widget build(BuildContext context) {
    final avg = average ?? 0.0;
    final hasReviews = total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big average number
              Column(
                children: [
                  Text(
                    hasReviews ? avg.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stars
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < avg.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 18,
                        color: filled ? Colors.amber[600] : AppColors.textMuted,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasReviews
                        ? '$total review${total == 1 ? '' : 's'}'
                        : 'No reviews yet',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Distribution bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = distribution[star] ?? 0;
                    final ratio = total > 0 ? count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            child: Text(
                              '$star',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.star_rounded,
                              size: 12, color: Colors.amber[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: AppColors.borderSoft,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ratio > 0
                                      ? Colors.amber[600]!
                                      : AppColors.borderSoft,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          // Leave a review button (only if eligible)
          if (canReview) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text('Rate this user'),
                onPressed: onLeaveReview,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can review because you completed a deal together',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== Review Card ====================

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final initial = review.reviewerEmail.isNotEmpty
        ? review.reviewerEmail[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 13,
                          color: Colors.amber[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat.yMMMd().format(review.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (review.description != null && review.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.description!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// class _RatingSummary extends StatelessWidget {
//   final double avg;
//   final int total;
//   const _RatingSummary({required this.avg, required this.total});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Row(
//         children: [
//           Text(
//             avg.toStringAsFixed(1),
//             style: const TextStyle(
//               fontSize: 38,
//               fontWeight: FontWeight.w800,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _Stars(rating: avg.round(), size: 20),
//               const SizedBox(height: 4),
//               Text(
//                 '$total review${total == 1 ? '' : 's'}',
//                 style: const TextStyle(
//                     fontSize: 12, color: AppColors.textSecondary),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Stars extends StatelessWidget {
//   final int rating;
//   final double size;
//   const _Stars({required this.rating, this.size = 16});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(
//         5,
//         (i) => Icon(
//           i < rating ? Icons.star_rounded : Icons.star_border_rounded,
//           size: size,
//           color: Colors.amber[600],
//         ),
//       ),
//     );
//   }
// }

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
