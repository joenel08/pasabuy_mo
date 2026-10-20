import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/transaction.dart';
import '../../services/review_service.dart';
import '../../services/transaction_service.dart';
import '../common/empty_state.dart';
import '../../core/translations.dart';

class MyDealsScreen extends StatefulWidget {
  const MyDealsScreen({super.key});
  @override
  State<MyDealsScreen> createState() => MyDealsScreenState();
}

class MyDealsScreenState extends State<MyDealsScreen> {
  List<Transaction> _items = [];
  Map<String, dynamic>? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<TransactionService>();
      _items = await svc.myDeals();
      _stats = await svc.myStats();
    } catch (e, st) {
      debugPrint('[DEALS] $e');
      debugPrint('[DEALS] $st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meId = context.watch<AuthController>().user?.id;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(T.of(context, 'my_deals')),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: T.of(context, 'analytics'),
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: reload,
        child: _loading && _items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (_stats != null) _StatsRow(stats: _stats!),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/analytics'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGhost,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primarySoft),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.insights_rounded,
                                size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  T.of(context, 'view_analytics'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  T.of(context, 'analytics_subtitle'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: T.of(context, 'no_deals_yet'),
                        subtitle: T.of(context, 'no_deals_sub'),
                      ),
                    )
                  else
                    ..._items.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DealCard(
                            tx: t,
                            meId: meId,
                            onChanged: reload,
                          ),
                        )),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final buyer = stats['as_buyer'] ?? {};
    final seller = stats['as_pasabuyer'] ?? {};
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: T.of(context, 'as_buyer'),
            value: '${buyer['completed'] ?? 0}',
            sub: '${buyer['active'] ?? 0} ${T.of(context, 'active')}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: T.of(context, 'as_pasabuyer'),
            value: '${seller['completed'] ?? 0}',
            sub: '${seller['active'] ?? 0} ${T.of(context, 'active')}',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}

class _DealCard extends StatefulWidget {
  final Transaction tx;
  final int? meId;
  final VoidCallback onChanged;

  const _DealCard({
    required this.tx,
    required this.meId,
    required this.onChanged,
  });

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _busy = false;
  Transaction get tx => widget.tx;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() => _run(() async {
        await context.read<TransactionService>().accept(tx.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(T.of(context, 'deal_accepted')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      });

  Future<void> _decline() async {
    final reason = await _askReason(T.of(context, 'cancel_deal_title'));
    if (reason == null) return;
    await _run(() async {
      await context.read<TransactionService>().decline(tx.id, reason: reason);
    });
  }

  Future<void> _done() async {
    final isBuyer = tx.role == 'buyer';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          T.of(context, isBuyer ? 'confirm_received_q' : 'confirm_delivered_q'),
        ),
        content: Text(T.of(context, 'confirm_both_sides')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.of(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(T.of(context, 'confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() => context.read<TransactionService>().done(tx.id));
  }

  Future<void> _review() async {
    final result = await showDialog<({int rating, String? text})>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await context.read<ReviewService>().submit(
            transactionId: tx.id,
            rating: result.rating,
            description: result.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.of(context, 'thanks_feedback')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${T.of(context, 'could_not_submit')}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: T.of(context, 'reason_optional'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.of(context, 'keep_deal')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(T.of(context, 'cancel_deal')),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    return ctrl.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle(context, tx.status);
    final iMustAccept = tx.iMustAccept(widget.meId);
    final iProposed = tx.iProposedDeal(widget.meId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: s.fg,
                      )),
                ),
                const SizedBox(width: 8),
                Text(
                  T.of(
                      context,
                      tx.role == 'buyer'
                          ? 'you_are_buying'
                          : 'you_are_pasabuyer'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(tx.itemDescription,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(
              '${tx.postTitle} · ${T.of(context, 'with_user')} ${tx.otherPartyEmail}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (tx.agreedPrice != null) ...[
              const SizedBox(height: 8),
              _MoneyRow(
                label: tx.role == 'buyer'
                    ? T.of(context, 'you_pay')
                    : T.of(context, 'you_earn'),
                value: '₱ ${tx.agreedPrice!.toStringAsFixed(2)}',
                bold: true,
              ),
              if (tx.isCompleted &&
                  tx.adminFee != null &&
                  tx.adminFee! > 0) ...[
                const SizedBox(height: 4),
                _MoneyRow(
                  label: T.of(context, 'admin_fee') + ' (2%)',
                  value: '- ₱ ${tx.adminFee!.toStringAsFixed(2)}',
                  color: AppColors.danger,
                ),
                if (tx.role == 'pasabuyer' && tx.netPayout != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _MoneyRow(
                      label: T.of(context, 'net_payout'),
                      value: '₱ ${tx.netPayout!.toStringAsFixed(2)}',
                      color: AppColors.success,
                      bold: true,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    T.of(context, 'fee_disclaimer'),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(T.of(context, 'chat')),
                    onPressed: () =>
                        context.push('/messages/${tx.conversationId}'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: _buildPrimaryAction(iMustAccept, iProposed)),
              ],
            ),
            if (tx.status == 'completed') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _review,
                icon: const Icon(Icons.star_outline_rounded, size: 16),
                label: Text(T.of(context, 'leave_review')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(bool iMustAccept, bool iProposed) {
    if (tx.status == 'pending') {
      if (iMustAccept) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: Text(T.of(context, 'decline')),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _accept,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(T.of(context, 'accept')),
              ),
            ),
          ],
        );
      }
      return OutlinedButton(
        onPressed: null,
        child: Text(
          T.of(context, iProposed ? 'waiting_for_accept' : 'waiting'),
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    if (tx.proofImageUrl != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(tx.proofImageUrl!, fit: BoxFit.cover),
          ),
        ),
      );
    if (tx.status == 'in_progress') {
      return FilledButton(
        onPressed: _busy ? null : _done,
        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        child: Text(T.of(
            context, tx.role == 'buyer' ? 'mark_received' : 'mark_delivered')),
      );
    }

    if (tx.status == 'buyer_done' && tx.role == 'pasabuyer') {
      return FilledButton(
        onPressed: _busy ? null : _done,
        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        child: Text(T.of(context, 'mark_delivered')),
      );
    }

    if (tx.status == 'pasabuyer_done' && tx.role == 'buyer') {
      return FilledButton(
        onPressed: _busy ? null : _done,
        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        child: Text(T.of(context, 'mark_received')),
      );
    }

    if (tx.status == 'buyer_done' || tx.status == 'pasabuyer_done') {
      return OutlinedButton(
        onPressed: null,
        child: Text(
          T.of(context, tx.iHaveDone ? 'waiting_for_them' : 'waiting_for_you'),
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  ({String label, Color bg, Color fg}) _statusStyle(
      BuildContext context, String s) {
    switch (s) {
      case 'pending':
        return (
          label: T.of(context, 'awaiting_accept'),
          bg: AppColors.warning.withOpacity(0.12),
          fg: AppColors.warning
        );
      case 'in_progress':
        return (
          label: T.of(context, 'in_progress'),
          bg: AppColors.info.withOpacity(0.12),
          fg: AppColors.info
        );
      case 'buyer_done':
        return (
          label: T.of(context, 'buyer_confirmed'),
          bg: AppColors.info.withOpacity(0.12),
          fg: AppColors.info
        );
      case 'pasabuyer_done':
        return (
          label: T.of(context, 'pasabuyer_confirmed'),
          bg: AppColors.info.withOpacity(0.12),
          fg: AppColors.info
        );
      case 'completed':
        return (
          label: T.of(context, 'completed'),
          bg: AppColors.success.withOpacity(0.12),
          fg: AppColors.success
        );
      case 'disputed':
        return (
          label: T.of(context, 'disputed'),
          bg: AppColors.danger.withOpacity(0.12),
          fg: AppColors.danger
        );
      case 'cancelled':
        return (
          label: T.of(context, 'cancelled'),
          bg: AppColors.textMuted.withOpacity(0.12),
          fg: AppColors.textMuted
        );
      default:
        return (label: s, bg: AppColors.borderSoft, fg: AppColors.textMuted);
    }
  }
}

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
      title: Text(T.of(context, 'how_was_deal')),
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
            decoration: InputDecoration(
              hintText: T.of(context, 'optional_comment'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(T.of(context, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            rating: _rating,
            text: _text.text.trim().isEmpty ? null : _text.text.trim(),
          )),
          child: Text(T.of(context, 'submit')),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            color: color ?? AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}