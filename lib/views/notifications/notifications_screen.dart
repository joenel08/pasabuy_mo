import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/notifications_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../common/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<NotificationsController>().load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationsController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(T.of(context, 'notifications')),
        actions: [
          if (c.unread > 0)
            TextButton(
              onPressed: c.markAllRead,
              child: Text(T.of(context, 'mark_all')),
            ),
        ],
      ),
      body: c.loading && c.items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : c.items.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: T.of(context, 'no_notifications'),
                  subtitle: T.of(context, 'no_notifications_sub'),
                )
              : ListView.separated(
                  itemCount: c.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 64),
                  itemBuilder: (_, i) {
                    final n = c.items[i];
                    return InkWell(
                      onTap: () async {
                        if (!n.read) await c.markRead(n.id);
                        if (!mounted) return;
                        final convId = n.data['conversation_id'];
                        if (convId is int) context.push('/messages/$convId');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color:
                            n.read ? AppColors.surface : AppColors.primaryGhost,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _iconBg(n.type),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_icon(n.type),
                                  color: _iconColor(n.type), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (n.body != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      n.body!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    _ago(context, n.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!n.read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _icon(String t) {
    switch (t) {
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'new_inquiry':
        return Icons.person_add_alt_1_rounded;
      case 'post_closed':
        return Icons.check_circle_rounded;
      case 'kyc_approved':
        return Icons.verified_rounded;
      case 'kyc_declined':
        return Icons.cancel_rounded;
      case 'report_resolved':
        return Icons.gavel_rounded;
      case 'report_dismissed':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String t) {
    switch (t) {
      case 'new_message':
        return AppColors.primary;
      case 'new_inquiry':
        return AppColors.info;
      case 'post_closed':
        return AppColors.success;
      case 'kyc_approved':
        return AppColors.success;
      case 'kyc_declined':
        return AppColors.danger;
      case 'report_resolved':
        return AppColors.success;
      case 'report_dismissed':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _iconBg(String t) => _iconColor(t).withOpacity(0.12);

  String _ago(BuildContext context, DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return T.of(context, 'just_now');
    if (diff.inMinutes < 60) {
      return T.ofNum(context, 'minutes_ago', diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return T.ofNum(context, 'hours_ago', diff.inHours);
    }
    if (diff.inDays < 7) {
      return T.ofNum(context, 'days_ago', diff.inDays);
    }
    return D.short(context, d);
  }
}
