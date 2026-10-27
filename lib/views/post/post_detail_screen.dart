import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../models/post_item.dart';
import '../../services/conversation_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  int? _openingItemId;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final res = await context.read<ApiClient>().dio.get('/posts/${_post.id}');
      final data = res.data['data'];
      if (data is Map && mounted) {
        setState(() => _post = Post.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {}
  }

  Future<void> _messageItem(PostItem item) async {
    if (item.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is already full')),
      );
      return;
    }
    setState(() => _openingItemId = item.id);
    try {
      final id = await context.read<ConversationService>().start(item.id);
      if (!mounted) return;
      context.push('/messages/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : 'Could not open chat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _openingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isOwner = auth.user?.id == _post.ownerId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(T.of(context, 'view'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _post.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (_post.originLocation != null ||
                    _post.destinationLocation != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_post.originLocation ?? '—'} → ${_post.destinationLocation ?? '—'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_post.travelDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        D.short(context, _post.travelDate!),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_post.items.length} item${_post.items.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._post.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ItemCard(
                  item: item,
                  isOwner: isOwner,
                  isPostClosed: _post.isClosed,
                  isLoading: _openingItemId == item.id,
                  onMessage: () => _messageItem(item),
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  final PostItem item;
  final bool isOwner;
  final bool isPostClosed;
  final bool isLoading;
  final VoidCallback onMessage;

  const _ItemCard({
    required this.item,
    required this.isOwner,
    required this.isPostClosed,
    required this.isLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isPostClosed || item.isFull || isOwner;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.images.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  item.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.borderSoft,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 32, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (item.slots != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isFull
                              ? AppColors.danger.withOpacity(0.12)
                              : AppColors.info.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.isFull ? 'FULL' : '${item.slotsLeft} left',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.isFull
                                ? AppColors.danger
                                : AppColors.info,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (!isOwner)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                      label: Text(
                          disabled ? 'Item unavailable' : 'Message seller'),
                      onPressed: disabled || isLoading ? null : onMessage,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}