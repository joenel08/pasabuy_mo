import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';

class ReportTargetScreen extends StatefulWidget {
  final String targetType;   // user | post | message | transaction
  final int targetId;
  const ReportTargetScreen({
    super.key,
    required this.targetType,
    required this.targetId,
  });
  @override
  State<ReportTargetScreen> createState() => _ReportTargetScreenState();
}

class _ReportTargetScreenState extends State<ReportTargetScreen> {
  String _reason = 'spam';
  final _desc = TextEditingController();
  bool _submitting = false;

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
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await context.read<ReportService>().submit(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason,
            description: _desc.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Admin will review it.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : 'Could not submit';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Why are you reporting this?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._reasons.map((r) => RadioListTile<String>(
                value: r.$1,
                groupValue: _reason,
                title: Text(r.$2, style: const TextStyle(fontSize: 13.5)),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                onChanged: (v) => v == null ? null : setState(() => _reason = v),
              )),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}