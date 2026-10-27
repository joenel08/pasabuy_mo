import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../models/post_item.dart';
import '../../services/conversation_service.dart';

class ImageViewerScreen extends StatefulWidget {
  final Post post;
  final PostItem? item; // null = use post.images (fallback)
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.post,
    this.item,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageCtrl;
  late int _current;
  bool _startingChat = false;

  List<String> get _images {
    final src = widget.item?.images ?? widget.post.images;
    return src.isNotEmpty ? src : widget.post.images;
  }

  /// The item this viewer is scoped to. Falls back to the post's only item
  /// if there is exactly one (common case for single-item posts).
  PostItem? get _scopedItem {
    if (widget.item != null) return widget.item;
    if (widget.post.items.length == 1) return widget.post.items.first;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, (_images.length - 1).clamp(0, 999));
    _pageCtrl = PageController(initialPage: _current);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  void _goToDetail() {
    final post = widget.post;
    Navigator.of(context).maybePop();
    context.push('/post/detail', extra: post);
  }

  /// Starts (or opens) the conversation for the scoped item.
  Future<void> _startChat() async {
    final item = _scopedItem;
    if (item == null) {
      // No specific item — can't pick one. Fall back to detail page.
      _goToDetail();
      return;
    }

    setState(() => _startingChat = true);
    try {
      final convId =
          await context.read<ConversationService>().start(item.id);
      if (!mounted) return;
      Navigator.of(context).maybePop(); // close viewer
      context.push('/messages/$convId'); // open the chat for THIS item
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : 'Could not open chat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final total = images.length;
    final auth = context.watch<AuthController>();
    final isOwner = auth.user?.id == widget.post.ownerId;
    final scopedItem = _scopedItem;

    // Is chatting possible right now?
    final canChat = scopedItem != null &&
        !isOwner &&
        !widget.post.isClosed &&
        !scopedItem.isFull;

    if (images.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No images', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final headline =
        scopedItem?.title.isNotEmpty == true ? scopedItem!.title : widget.post.title;
    final subline = (scopedItem != null && widget.post.title.isNotEmpty)
        ? widget.post.title
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Swipeable gallery ----
            PageView.builder(
              controller: _pageCtrl,
              itemCount: total,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        images[i],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ---- Top bar ----
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    if (total > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_current + 1} / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),

            // ---- Bottom info + actions ----
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name (or post title if no item)
                    Text(
                      headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'from: $subline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (scopedItem != null && scopedItem.images.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${scopedItem.images.length} '
                              'photo${scopedItem.images.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (scopedItem != null && scopedItem.images.length > 1)
                          const SizedBox(width: 8),
                        // Status hint when the item can't be chatted
                        if (scopedItem != null && !isOwner && !canChat)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              scopedItem.isFull
                                  ? 'FULL'
                                  : (widget.post.isClosed ? 'CLOSED' : ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (scopedItem != null && !isOwner && !canChat)
                          const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.post.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Thumbnail strip
                    if (total > 1) ...[
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: total,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final isActive = i == _current;
                            return GestureDetector(
                              onTap: () {
                                _pageCtrl.animateToPage(
                                  i,
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    images[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ---- Buttons ----
                    Row(
                      children: [
                        // View — always shown
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToDetail,
                            icon: const Icon(Icons.visibility_outlined,
                                size: 16),
                            label: Text(T.of(context, 'view')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        // Message — only shown to non-owners, and only
                        // when chatting is actually possible
                        if (!isOwner && scopedItem != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  (canChat && !_startingChat) ? _startChat : null,
                              icon: _startingChat
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16),
                              label: Text(T.of(context, 'message')),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}