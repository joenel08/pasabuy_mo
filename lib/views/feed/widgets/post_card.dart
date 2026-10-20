import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/feed_controller.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../../models/post.dart';
import '../../../services/conversation_service.dart';
import '../../../services/favorite_service.dart';
import '../../../services/post_service.dart';
import '../../common/report_sheet.dart';

import '../../../core/constants.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isOffer = post.type == 'offer';
    final ownerInitial =
        post.ownerName.isNotEmpty ? post.ownerName[0].toUpperCase() : '?';
    final closed = post.isClosed;
    final auth = context.watch<AuthController>();
    final isOwner = auth.user?.id == post.ownerId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openProfile(context, isOwner: isOwner),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: post.ownerAvatar == null
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                    )
                                  : null,
                              image: post.ownerAvatar != null
                                  ? DecorationImage(
                                      image: NetworkImage(post.ownerAvatar!),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                            ),
                            child: post.ownerAvatar == null
                                ? Center(
                                    child: Text(
                                      ownerInitial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        post.ownerName.isNotEmpty
                                            ? post.ownerName
                                            : T.of(context, 'pasa_buy_user'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          T.of(context, 'you'),
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    _TypePill(isOffer: isOffer),
                                    if (post.slots != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: post.isFull
                                              ? AppColors.danger
                                                  .withOpacity(0.12)
                                              : AppColors.info
                                                  .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          post.isFull
                                              ? T.of(context, 'full')
                                              : '${post.slotsLeft} ${T.of(context, 'left')}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: post.isFull
                                                ? AppColors.danger
                                                : AppColors.info,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      post.travelDate != null
                                          ? D.short(context, post.travelDate!)
                                          : T.of(context, 'recently'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (closed)
                                      _StatusPill(status: post.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => _openMoreMenu(context, isOwner: isOwner),
                  splashRadius: 20,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // ---------- Body ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ---------- Image ----------
          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    post.images.first,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.borderSoft,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, err, __) {
                      debugPrint(
                          '[POST IMG] failed: ${post.images.first} → $err');
                      return Container(
                        color: AppColors.borderSoft,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ---------- Route pill ----------
          if (post.originLocation != null || post.destinationLocation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post.originLocation ?? '—',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppColors.textMuted),
                    ),
                    Expanded(
                      child: Text(
                        post.destinationLocation ?? '—',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ---------- Actions ----------
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _buildActions(context, isOwner: isOwner, closed: closed),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context, {required bool isOwner}) {
    if (isOwner) {
      context.push('/profile');
    } else {
      context.push('/users/${post.ownerId}');
    }
  }

  Widget _buildActions(BuildContext context,
      {required bool isOwner, required bool closed}) {
    // NOTE: this runs during build(), so `T.of` (watch) is safe here.
    if (isOwner) {
      return Row(
        children: [
          _PostAction(
            icon: Icons.edit_outlined,
            label: T.of(context, 'edit'),
            color: closed ? AppColors.textMuted : AppColors.textPrimary,
            onTap: closed
                ? () => _toast(context, T.read(context, 'post_closed_toast'))
                : () => context.push('/post/edit', extra: post),
          ),
          _PostAction(
            icon: Icons.visibility_outlined,
            label: T.of(context, 'view'),
            color: AppColors.textSecondary,
            onTap: () => _showDetails(context),
          ),
          if (!closed)
            _PostAction(
              icon: Icons.check_circle_outline_rounded,
              label: T.of(context, 'mark_done_action'),
              color: AppColors.success,
              onTap: () => _confirmClose(context),
            )
          else
            _PostAction(
              icon: Icons.share_outlined,
              label: T.of(context, 'share'),
              color: AppColors.textSecondary,
              onTap: () => _share(context),
            ),
        ],
      );
    }

    return Row(
      children: [
        _PostAction(
          icon: Icons.chat_bubble_outline_rounded,
          label: T.of(context, 'message'),
          color: closed ? AppColors.textMuted : AppColors.primary,
          onTap: closed
              ? () => _toast(context, T.read(context, 'already_closed_toast'))
              : () => _openChat(context),
        ),
        _PostAction(
          icon: Icons.visibility_outlined,
          label: T.of(context, 'view'),
          color: AppColors.textSecondary,
          onTap: () => _showDetails(context),
        ),
        _PostAction(
          icon: post.isFavorite
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: T.of(context, post.isFavorite ? 'saved' : 'save'),
          color: post.isFavorite ? AppColors.primary : AppColors.textSecondary,
          onTap: () => _toggleSave(context),
        ),
      ],
    );
  }

  Future<void> _toggleSave(BuildContext context) async {
    try {
      final saved = await context.read<FavoriteService>().toggle(post.id);
      if (!context.mounted) return;
      _toast(
        context,
        T.read(context,
            saved ? 'saved_to_favorites' : 'removed_from_favorites'),
        success: saved,
      );
      context.read<FeedController>().load();
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, T.read(context, 'could_not_save'), error: true);
    }
  }

  void _openMoreMenu(BuildContext context, {required bool isOwner}) {
    final closed = post.isClosed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
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
              if (!isOwner)
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  label: T.read(context, 'view_profile'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/users/${post.ownerId}');
                  },
                ),
              if (!isOwner)
                _MenuTile(
                  icon: Icons.bookmark_border_rounded,
                  label: T.read(context,
                      post.isFavorite ? 'remove_from_saved' : 'save_this_post'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _toggleSave(context);
                  },
                ),
              // The only remaining share-ish action.
              _MenuTile(
                icon: Icons.share_outlined,
                label: T.read(context, 'share'),
                onTap: () {
                  Navigator.pop(context);
                  _share(context);
                },
              ),
              if (isOwner && !closed)
                _MenuTile(
                  icon: Icons.edit_outlined,
                  label: T.read(context, 'edit_post'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/post/edit', extra: post);
                  },
                ),
              if (isOwner && !closed)
                _MenuTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: T.read(context, 'mark_as_done'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmClose(context);
                  },
                ),
              if (!isOwner)
                _MenuTile(
                  icon: Icons.flag_outlined,
                  label: T.read(context, 'report_post'),
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    showReportSheet(context,
                        targetType: 'post', targetId: post.id);
                  },
                ),
              if (isOwner)
                _MenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: T.read(context, 'delete_post'),
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final svc = context.read<ConversationService>();
      final id = await svc.start(post.id);
      if (!context.mounted) return;
      context.push('/messages/$id');
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_open_chat');
      _toast(context, msg, error: true);
    }
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _TypePill(isOffer: post.type == 'offer'),
                const SizedBox(height: 12),
                Text(post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Text(post.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the OS share sheet (WhatsApp, Messenger, SMS, Copy to clipboard…)
  void _share(BuildContext context) {
    final downloadUrl = AppConstants.appDownloadUrl;
    final text = '''
${post.title}

${post.description}

${post.originLocation ?? ''} → ${post.destinationLocation ?? ''}
${post.travelDate != null ? D.readLong(context, post.travelDate!) : ''}
${T.read(context, 'posted_by')} ${post.ownerName}

${T.read(context, 'via_pasabuy')}
${T.read(context, 'download_app')}: $downloadUrl
'''.trim();

    Share.share(text, subject: post.title);
  }

  Future<void> _confirmClose(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(T.read(context, 'mark_done_title')),
        content: Text(T.read(context, 'mark_done_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.read(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(T.read(context, 'mark_done_action')),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await context.read<PostService>().close(post.id);
      if (!context.mounted) return;
      _toast(context, T.read(context, 'post_closed_thanks'), success: true);
      context.read<FeedController>().load();
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_close_post');
      _toast(context, msg, error: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(T.read(context, 'delete_post_title')),
        content: Text(T.read(context, 'delete_post_body')),
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

    if (ok != true || !context.mounted) return;

    try {
      await context.read<PostService>().destroy(post.id);
      if (!context.mounted) return;
      _toast(context, T.read(context, 'post_deleted'), success: true);
      context.read<FeedController>().load();
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_delete_post');
      _toast(context, msg, error: true);
    }
  }

  void _toast(BuildContext context, String msg,
      {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? AppColors.success
            : error
                ? AppColors.danger
                : AppColors.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TypePill extends StatelessWidget {
  final bool isOffer;
  const _TypePill({required this.isOffer});

  @override
  Widget build(BuildContext context) {
    final color = isOffer ? AppColors.primary : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        T.of(context, isOffer ? 'pasabuy_offer' : 'buy_request'),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'closed': (AppColors.textMuted, 'closed'),
      'matched': (AppColors.info, 'matched'),
      'completed': (AppColors.success, 'completed'),
      'cancelled': (AppColors.danger, 'cancelled'),
    };
    final entry = map[status] ?? (AppColors.textMuted, status);
    final color = entry.$1;
    final label = T.of(context, entry.$2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}