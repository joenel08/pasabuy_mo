import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';

/// Shows the report bottom sheet and submits the report.
/// Usage: await showReportSheet(context, targetType: 'post', targetId: 42);
Future<bool> showReportSheet(
  BuildContext context, {
  required String targetType,
  required int targetId,
}) async {
  final result = await showModalBottomSheet<({String reason, String? description})>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(targetType: targetType),
  );

  if (result == null || !context.mounted) return false;

  try {
    await context.read<ReportService>().submit(
          targetType: targetType,
          targetId: targetId,
          reason: result.reason,
          description: result.description,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Our admin team will review it.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      final msg = e is Exception ? 'Could not submit report' : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
    return false;
  }
}

class _ReportSheet extends StatefulWidget {
  final String targetType;
  const _ReportSheet({required this.targetType});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = <(String, String, IconData)>[
    ('spam', 'Spam or misleading content', Icons.campaign_outlined),
    ('harassment', 'Harassment or bullying', Icons.report_gmailerrorred_outlined),
    ('fake_id', 'Fake or stolen identity', Icons.badge_outlined),
    ('scam', 'Scam or fraud', Icons.gavel_rounded),
    ('inappropriate', 'Inappropriate content', Icons.visibility_off_outlined),
    ('off_platform', 'Asks to transact off-platform', Icons.link_off_rounded),
    ('prohibited_item', 'Prohibited or illegal item', Icons.block_rounded),
    ('other', 'Something else', Icons.more_horiz_rounded),
  ];

  String? _selectedReason;
  final _desc = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.targetType) {
      case 'post':
        return 'Report this post';
      case 'user':
        return 'Report this user';
      case 'message':
        return 'Report this message';
      case 'transaction':
        return 'Report this transaction';
      default:
        return 'Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tell us what\'s wrong. Your report is anonymous.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason list
              ..._reasons.map((r) {
                final selected = _selectedReason == r.$1;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = r.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primarySoft
                                : AppColors.borderSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            r.$3,
                            size: 18,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),

              // Optional description
              if (_selectedReason != null) ...[
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _desc,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Add details (optional)',
                      hintText: 'Anything else we should know?',
                    ),
                  ),
                ),
              ],

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedReason == null
                            ? null
                            : () => Navigator.pop(context, (
                                  reason: _selectedReason!,
                                  description: _desc.text.trim().isEmpty
                                      ? null
                                      : _desc.text.trim(),
                                )),
                        child: const Text('Submit report'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}