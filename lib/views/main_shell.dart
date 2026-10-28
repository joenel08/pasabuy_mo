import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/conversations_controller.dart';
import '../controllers/feed_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/profile_controller.dart';
import '../core/theme.dart';
import '../core/translations.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'feed/feed_screen.dart';
import 'messages/messages_list_screen.dart';
import 'deals/my_deals_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _dealsNeedingAction = 0;
  Timer? _badgeTimer;
  bool _pollingStarted = false;

  static const _screens = [
    FeedScreen(),
    MessagesListScreen(),
    MyDealsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsController>().startPolling();
      _startBadgePolling();
    });
  }

  void _startBadgePolling() {
    if (_pollingStarted) return;
    _pollingStarted = true;

    _refreshBadges();
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshBadges(),
    );
  }

  Future<void> _refreshBadges() async {
    if (!mounted) return;

    // Refresh conversations (feeds Messages badge via ConversationsController)
    try {
      await context.read<ConversationsController>().load();
    } catch (_) {}

    // Refresh deals (feeds Transactions badge)
    try {
      final deals = await context.read<TransactionService>().myDeals();
      final me = context.read<AuthController>().user?.id;

      final count = deals.where((Transaction d) {
        // Pending deals where the OTHER party proposed — I must accept/decline
        if (d.status == 'pending') return d.iMustAccept(me);
        // Buyer confirmed but I'm the pasabuyer — I must confirm delivery
        if (d.status == 'buyer_done' && d.role == 'pasabuyer') return true;
        // Pasabuyer confirmed but I'm the buyer — I must confirm receipt
        if (d.status == 'pasabuyer_done' && d.role == 'buyer') return true;
        return false;
      }).length;

      if (mounted && count != _dealsNeedingAction) {
        setState(() => _dealsNeedingAction = count);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _onTab(int i) {
    setState(() => _index = i);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (i == 0) {
        context.read<FeedController>().resetFilters();
        context.read<FeedController>().load();
        context.read<ProfileController>().load();
      } else if (i == 1) {
        context.read<ConversationsController>().load();
      } else if (i == 3) {
        context.read<ProfileController>().load();
        context.read<AuthController>().refreshMe();
      }
      // Always refresh the badge sources when switching tabs
      _refreshBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationsCtrl = context.watch<ConversationsController>();
    final unreadMessages = conversationsCtrl.items
        .fold<int>(0, (sum, c) => sum + c.unread);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: T.of(context, 'home'),
                  active: _index == 0,
                  onTap: () => _onTab(0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: T.of(context, 'messages'),
                  active: _index == 1,
                  badge: unreadMessages,
                  onTap: () => _onTab(1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: T.of(context, 'transactions'),
                  active: _index == 2,
                  badge: _dealsNeedingAction,
                  onTap: () => _onTab(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: T.of(context, 'profile'),
                  active: _index == 3,
                  onTap: () => _onTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with badge overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}