import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/conversations_controller.dart';
import '../controllers/feed_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/profile_controller.dart';
import '../core/theme.dart';
import '../core/translations.dart';
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
    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => _onTab(1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: T.of(context, 'transactions'),
                  active: _index == 2,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
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
            Icon(active ? activeIcon : icon, size: 24, color: color),
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