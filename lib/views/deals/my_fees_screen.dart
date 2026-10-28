import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
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
  List<FeeClaim> _claims = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<TransactionService>();
      final data = await svc.myFees();
      final claims = await svc.myFeeClaims();
      if (!mounted) return;
      setState(() {
        _data = data;
        _claims = claims;
      });
    } catch (e) {
      debugPrint('[FEES] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openClaimSheet(FeesData d) async {
    final amountCtrl = TextEditingController(
      text: d.unpaidTotal > 0 ? d.unpaidTotal.toStringAsFixed(2) : '',
    );
    final refCtrl = TextEditingController();
    final senderCtrl = TextEditingController();
    File? proofImage;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Report payment',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin will verify against GCash before confirming.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount sent (₱)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: refCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'GCash reference number',
                      helperText: 'From your GCash receipt (13-digit number)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: senderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your GCash account name',
                      helperText: 'Exactly as it appears in GCash',
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxWidth: 1600,
                      );
                      if (picked != null) {
                        setModalState(() => proofImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.borderSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        image: proofImage != null
                            ? DecorationImage(
                                image: FileImage(proofImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: proofImage == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Attach GCash receipt screenshot',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid amount'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      if (refCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('GCash reference number is required'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      if (senderCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('GCash sender name is required'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit for verification'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) return;

    try {
      await context.read<TransactionService>().submitFeeClaim(
            amount: double.parse(amountCtrl.text.trim()),
            gcashReference: refCtrl.text.trim(),
            gcashSenderName: senderCtrl.text.trim(),
            proofImage: proofImage,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim submitted! Admin will verify within 24 hours.'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
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
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
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

  // ===================================================================
  // Main content — everything is now correctly at the ListView level
  // ===================================================================

  Widget _buildContent(FeesData d) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _statusCard(d),

        // I already paid button — directly below the "How to pay" instructions
        if (d.unpaidTotal > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openClaimSheet(d),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                'I already paid ₱${d.unpaidTotal.toStringAsFixed(2)}',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap above after sending. Admin will verify and confirm within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],

        // Unpaid fees breakdown
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
          ...d.items.map(_unpaidFeeTile),
        ],

        // Payment claims history
        if (_claims.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'MY PAYMENT CLAIMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._claims.map(_claimTile),
        ],

        // Confirmed payment history
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
          ...d.history.map(_paidFeeTile),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // ===================================================================
  // Status card
  // ===================================================================
  Widget _statusCard(FeesData d) {
    return Container(
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
                    : (d.unpaidTotal > 0
                        ? AppColors.warning
                        : AppColors.success),
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
                        : (d.unpaidTotal > 0
                            ? AppColors.warning
                            : AppColors.success),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (d.isBlocked && d.blockReason != null) ...[
            const SizedBox(height: 10),
            Text(
              d.blockReason!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
              ),
            ),
          ],

          // How to pay box
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text(
                        'Copy GCash number',
                        style: TextStyle(fontSize: 12),
                      ),
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
                  const SizedBox(height: 6),
                  const Text(
                    'After sending, tap "I already paid" below and enter your GCash reference number.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================================================================
  // Unpaid fee tile
  // ===================================================================
  Widget _unpaidFeeTile(UnpaidFee u) {
    return Padding(
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
    );
  }

  // ===================================================================
  // Claim tile
  // ===================================================================
  Widget _claimTile(FeeClaim c) {
    final color = c.status == 'approved'
        ? AppColors.success
        : c.status == 'rejected'
            ? AppColors.danger
            : AppColors.warning;
    final icon = c.status == 'approved'
        ? Icons.check_circle_rounded
        : c.status == 'rejected'
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;
    final label = c.status == 'approved'
        ? 'APPROVED'
        : c.status == 'rejected'
            ? 'REJECTED'
            : 'PENDING REVIEW';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${c.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ref ${c.gcashReference ?? '—'} · ${_fmtDate(c.createdAt)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
            if (c.status == 'approved' && c.appliedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${c.appliedCount} fee(s) settled · ₱${c.appliedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.success,
                ),
              ),
              if (c.leftoverAmount > 0)
                Text(
                  '₱${c.leftoverAmount.toStringAsFixed(2)} leftover — will apply to next fees',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                  ),
                ),
            ],
            if (c.status == 'rejected' && c.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                c.rejectionReason!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // Confirmed payment history tile
  // ===================================================================
  Widget _paidFeeTile(PaidFee p) {
    return Padding(
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
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Deal #${p.transactionId} · ${_fmtDate(p.paidAt)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
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
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}