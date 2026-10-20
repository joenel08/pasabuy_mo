import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/notifications_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import 'widgets/composer_card.dart';
import 'widgets/post_card.dart';
import 'widgets/quick_actions.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();
  bool _searchOpen = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FeedController>().resetFilters();
      context.read<FeedController>().load();
      context.read<NotificationsController>().startPolling();
    });

    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      context.read<FeedController>().resetFilters();
      context.read<FeedController>().load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<FeedController>().resetFilters();
      context.read<FeedController>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FeedController>();
    final unread = context.watch<NotificationsController>().unread;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _appBar(unread),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<FeedController>().resetFilters();
          await context.read<FeedController>().load();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _searchBar()),
            const SliverToBoxAdapter(child: QuickActions()),
            const SliverToBoxAdapter(child: ComposerCard()),
            if (c.loading && c.posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (c.posts.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _empty(context))
            else
              SliverList.separated(
                itemCount: c.posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PostCard(post: c.posts[i]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(int unread) {
    final auth = context.watch<AuthController>();
    final profile = context.watch<ProfileController>().profile;

    final String initial;
    if (profile != null && profile.firstname.isNotEmpty) {
      initial = profile.firstname[0].toUpperCase();
    } else if (auth.user?.email.isNotEmpty == true) {
      initial = auth.user!.email[0].toUpperCase();
    } else {
      initial = '?';
    }

    final avatarUrl = profile?.avatarUrl;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'PasaBuy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
      actions: [
        _CircleIcon(
          icon: Icons.search_rounded,
          onTap: () => setState(() => _searchOpen = !_searchOpen),
        ),
        _CircleIcon(
          icon: Icons.notifications_none_rounded,
          badge: unread,
          onTap: () => context.push('/notifications'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 6),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: avatarUrl == null
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark])
                    : null,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }

  Widget _searchBar() {
    if (!_searchOpen) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: _search,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (v) =>
            context.read<FeedController>().applyFilters(search: v),
        decoration: InputDecoration(
          hintText: T.of(context, 'search_pasabuy'),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGhost,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_outlined,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                T.of(context, 'no_pasabuys'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                T.of(context, 'no_pasabuys_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  const _CircleIcon({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.borderSoft,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(icon, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16),
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}