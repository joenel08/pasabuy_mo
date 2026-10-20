import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/conversations_controller.dart';
import '../../core/language_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../common/empty_state.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});
  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConversationsController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(T.of(context, 'messages'))),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: c.load,
        child: c.loading && c.items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : c.items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: T.of(context, 'no_messages_yet'),
                        subtitle: T.of(context, 'start_conversation_hint'),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: c.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final conv = c.items[i];
                      final displayName = conv.otherPartyName.isNotEmpty
                          ? conv.otherPartyName
                          : conv.otherPartyEmail;
                      final initial = displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          conv.postTitle.isEmpty
                              ? displayName
                              : conv.postTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: conv.postType == 'offer'
                                        ? AppColors.primarySoft
                                        : AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    T.of(
                                      context,
                                      conv.postType == 'offer'
                                          ? 'offer'
                                          : 'request',
                                    ),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: conv.postType == 'offer'
                                          ? AppColors.primary
                                          : AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conv.lastMessage ??
                                  T.of(context, 'no_messages_yet'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (conv.lastMessageAt != null)
                              Text(
                                _fmt(context, conv.lastMessageAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (conv.unread > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conv.unread}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () => context.push('/messages/${conv.id}'),
                      );
                    },
                  ),
      ),
    );
  }

  String _fmt(BuildContext context, DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final code = context.read<LanguageController>().code;
    final locale = code == 'fil' ? 'fil_PH' : 'en_PH';
    return DateFormat.MMMd(locale).format(d);
  }
}