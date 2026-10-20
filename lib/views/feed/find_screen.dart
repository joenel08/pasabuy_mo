import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/feed_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import 'widgets/post_card.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});
  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final _search = TextEditingController();
  final _location = TextEditingController();
  String? _type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedController>().clearFilters();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _location.dispose();
    super.dispose();
  }

  void _apply() {
    context.read<FeedController>().applyFilters(
      search: _search.text.trim(),
      location: _location.text.trim(),
      type: _type,
      status: 'open',
      mine: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FeedController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(T.of(context, 'find_pasabuy_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _apply(),
                  decoration: InputDecoration(
                    hintText: T.of(context, 'search_items_hint'),
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _location,
                        onSubmitted: (_) => _apply(),
                        decoration: InputDecoration(
                          hintText: T.of(context, 'location_hint'),
                          prefixIcon: const Icon(Icons.place_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: T.of(context, 'offers'),
                      active: _type == 'offer',
                      onTap: () {
                        setState(
                            () => _type = _type == 'offer' ? null : 'offer');
                        _apply();
                      },
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: T.of(context, 'requests'),
                      active: _type == 'request',
                      onTap: () {
                        setState(() =>
                            _type = _type == 'request' ? null : 'request');
                        _apply();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: c.loading && c.posts.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : c.posts.isEmpty
                    ? Center(
                        child: Text(
                          T.of(context, 'no_results'),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: c.posts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => PostCard(post: c.posts[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}