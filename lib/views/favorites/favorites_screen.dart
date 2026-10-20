import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../services/favorite_service.dart';
import '../common/empty_state.dart';
import '../feed/widgets/post_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Post> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<FavoriteService>().list();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      debugPrint('[FAVORITES] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(T.of(context, 'saved_posts'))),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: T.of(context, 'no_saved_posts'),
                      subtitle: T.of(context, 'no_saved_posts_sub'),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => PostCard(post: _items[i]),
                  ),
      ),
    );
  }
}