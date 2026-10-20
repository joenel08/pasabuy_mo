import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/language_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/report_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(T.of(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(T.of(context, 'preferences')),
          _Card(children: [
            _Tile(
              icon: Icons.language_outlined,
              title: T.of(context, 'language'),
              trailing: DropdownButton<String>(
                value: lang.code,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'fil', child: Text('Filipino')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  context.read<LanguageController>().set(v);
                },
              ),
            ),
          ]),

          _SectionTitle(T.of(context, 'support')),
          _Card(children: [
            _Tile(
              icon: Icons.help_outline_rounded,
              title: T.of(context, 'help_centre'),
              onTap: () => context.push('/help'),
            ),
            _Tile(
              icon: Icons.description_outlined,
              title: T.of(context, 'terms'),
              onTap: () => context.push('/terms'),
            ),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: T.of(context, 'about'),
              onTap: () => context.push('/about'),
            ),
          ]),

          _SectionTitle(T.of(context, 'account')),
          _Card(children: [
            _Tile(
              icon: Icons.logout_rounded,
              title: T.of(context, 'sign_out'),
              onTap: () => _confirmLogout(context),
            ),
            _Tile(
              icon: Icons.delete_forever_outlined,
              title: T.of(context, 'delete_account'),
              danger: true,
              onTap: () => _requestDeletion(context),
            ),
          ]),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'PasaBuy Mo, Pasaya Mo · v0.1.0',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(T.of(context, 'logout_title')),
        content: Text(T.of(context, 'logout_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.of(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(T.of(context, 'logout_action')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthController>().logout();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _requestDeletion(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request account deletion?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'An admin will review your request and contact you before '
              'the account is removed.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Request deletion'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<ReportService>().submit(
            targetType: 'user',
            targetId: context.read<AuthController>().user!.id,
            reason: 'other',
            description: 'Account deletion request: ${ctrl.text.trim()}',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request received.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit. Try again.')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            )),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  const _Tile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: color),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted)
              : null),
    );
  }
}