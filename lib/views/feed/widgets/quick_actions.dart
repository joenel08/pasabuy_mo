import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/translations.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(
        label: T.of(context, 'post_pasabuy'),
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.primary,
        onTap: () => context.push('/post/new'),
      ),
      _Item(
        label: T.of(context, 'find_pasabuy'),
        icon: Icons.search_rounded,
        color: AppColors.accent,
        onTap: () => context.push('/find'),
      ),
      _Item(
        label: T.of(context, 'my_deals'),
        icon: Icons.receipt_long_outlined,
        color: AppColors.info,
        onTap: () => context.push('/deals'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: items.map((it) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: it == items.last ? 0 : 8),
              child: _QuickCard(item: it),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Item({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickCard extends StatelessWidget {
  final _Item item;
  const _QuickCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 17, color: item.color),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}