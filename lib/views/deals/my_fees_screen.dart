import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/fees_summary.dart';
import '../../services/transaction_service.dart';
import '../common/empty_state.dart';

class MyFeesScreen extends StatefulWidget {
  const MyFeesScreen({super.key});
  @override
  State<MyFeesScreen> createState() => _MyFeesScreenState();
}

class _MyFeesScreenState extends State<MyFeesScreen> {
  FeesData? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<TransactionService>().myFees();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      debugPrint('[FEES] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My fees')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading && _data == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _data == null
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No data',
                    subtitle: 'Could not load your fees.',
                  )
                : _buildContent(_data!),
      ),
    );
  }

  Widget _buildContent(FeesData d) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: d.isBlocked
                ? AppColors.danger.withOpacity(0.06)
                : (d.unpaidTotal > 0
                    ? AppColors.warning.withOpacity(0.06)
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: d.isBlocked
                  ? AppColors.danger.withOpacity(0.3)
                  : (d.unpaidTotal > 0
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    d.isBlocked
                        ? Icons.block_rounded
                        : (d.unpaidTotal > 0
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded),
                    color: d.isBlocked
                        ? AppColors.danger
                        : (d.unpaidTotal > 0 ? AppColors.warning : AppColors.success),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.isBlocked
                          ? 'Posting is blocked'
                          : (d.unpaidTotal > 0
                              ? 'Outstanding fees'
                              : 'All settled'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: d.isBlocked
                            ? AppColors.danger
                            : (d.unpaidTotal > 0 ? AppColors.warning : AppColors.success),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₱${d.unpaidTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.unpaidCount} unpaid fee${d.unpaidCount == 1 ? '' : 's'}'
                '${d.daysOldest > 0 ? ' · oldest ${d.daysOldest} days' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (d.isBlocked && d.blockReason != null) ...[
                const SizedBox(height: 10),
                Text(
                  d.blockReason!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
                ),
              ],
              if (d.unpaidTotal > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to pay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Send to GCash:\n${d.gcashNumber} (${d.gcashName})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Copy GCash number',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: d.gcashNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'After sending, admin will confirm receipt in the app — usually within 24 hours.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Unpaid breakdown
        if (d.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'UNPAID FEES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...d.items.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: u.daysOld >= 30
                          ? AppColors.danger.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.itemTitle.isNotEmpty ? u.itemTitle : u.itemDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${u.postTitle} · ${u.daysOld}d ago',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: u.daysOld >= 30
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₱${u.adminFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],

        // Payment history
        if (d.history.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PAYMENT HISTORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...d.history.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Deal #${p.transactionId} · ${_fmtDate(p.paidAt)}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '₱${p.adminFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}