import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/conversations_controller.dart';
import '../../core/api_client.dart';
import '../../core/language_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/conversation.dart';
import '../../services/conversation_service.dart';
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
                      return _ConversationTile(
                        key: ValueKey('conv_${conv.id}'),
                        conv: conv,
                      );
                    },
                  ),
      ),
    );
  }
}

// ===================================================================
// Conversation tile — swipeable, with pin + delete
// ===================================================================

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  const _ConversationTile({super.key, required this.conv});

  // ---- Pin / Unpin ----
  Future<void> _togglePin(BuildContext context) async {
    final wasPinned = conv.pinned;
    try {
      final svc = context.read<ConversationService>();
      if (wasPinned) {
        await svc.unpin(conv.id);
      } else {
        await svc.pin(conv.id);
      }
      if (!context.mounted) return;
      await context.read<ConversationsController>().load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              T.read(context, wasPinned ? 'unpinned' : 'pinned_to_top')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_pin');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  // ---- Confirm + delete ----
  Future<bool> _confirmAndDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(T.read(context, 'delete_conversation_title')),
        content: Text(T.read(context, 'delete_conversation_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.read(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(T.read(context, 'delete')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return false;

    try {
      await context.read<ConversationService>().delete(conv.id);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_delete_conversation');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = conv.otherPartyName.isNotEmpty
        ? conv.otherPartyName
        : conv.otherPartyEmail;
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Dismissible(
      key: ValueKey('dismiss_conv_${conv.id}'),
      direction: DismissDirection.horizontal,
      // Swipe right → pin
      background: _PinBackground(pinned: conv.pinned),
      // Swipe left → delete
      secondaryBackground: const _DeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _togglePin(context);
          return false; // never actually dismiss on pin
        }
        return await _confirmAndDelete(context);
      },
      onDismissed: (_) {
        context.read<ConversationsController>().removeLocal(conv.id);
      },
      child: Container(
        color: conv.pinned ? AppColors.primaryGhost : Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
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
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (conv.pinned)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.push_pin,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conv.itemTitle.isNotEmpty
                ? conv.itemTitle
                : (conv.postTitle.isEmpty ? displayName : conv.postTitle),
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
                      T.of(context,
                          conv.postType == 'offer' ? 'offer' : 'request'),
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
                conv.lastMessage ?? T.of(context, 'no_messages_yet'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

// ===================================================================
// Swipe backgrounds
// ===================================================================

class _PinBackground extends StatelessWidget {
  final bool pinned;
  const _PinBackground({required this.pinned});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            pinned ? 'Unpin' : 'Pin',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
        ],
      ),
    );
  }
}