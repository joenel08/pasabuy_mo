import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().load();
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );

    // Bail out before touching `context` again.
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await context.read<ProfileController>().uploadAvatar(File(picked.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<ProfileController>();
    final auth = context.watch<AuthController>();
    final profile = pc.profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<ProfileController>().load();
          await context.read<AuthController>().refreshMe();
        },
        child: pc.loading && profile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                // Keeps pull-to-refresh working even when content is short.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: profile?.avatarUrl == null
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                      )
                                    : null,
                                image: profile?.avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          profile!.avatarUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: profile?.avatarUrl == null
                                  ? Center(
                                      child: Text(
                                        profile?.initials ?? '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (_uploading)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _uploading ? null : _pickAvatar,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          profile?.fullName ?? auth.user?.email ?? '—',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _KycBadge(status: auth.kycStatus),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick links
                  Row(
                    children: [
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.favorite_outline_rounded,
                          label: 'Favorites',
                          onTap: () => context.push('/favorites'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.edit_outlined,
                          label: 'Edit profile',
                          onTap: () => context.push('/profile/edit'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.star_outline_rounded,
                          label: 'My reviews',
                          onTap: () {
                            final id = auth.user?.id;
                            if (id != null) context.push('/users/$id');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  if (profile != null) _InfoCard(profile: profile),
                  const SizedBox(height: 16),
                  _MyPosts(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(T.of(context, 'sign_out')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  // Read the controller *before* the await so we never touch a stale context.
  final auth = context.read<AuthController>();

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(T.of(dialogContext, 'logout_title')),
      content: Text(T.of(dialogContext, 'logout_body')),
      actions: [
        TextButton(
          // Pop with the dialog's own context, otherwise go_router shells can
          // pop the whole profile route instead of the dialog.
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(T.of(dialogContext, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(T.of(dialogContext, 'logout_action')),
        ),
      ],
    ),
  );

  if (ok == true) {
    await auth.logout();
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
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

class _KycBadge extends StatelessWidget {
  final String status;

  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'accepted': (AppColors.success, 'Verified'),
      'pending': (AppColors.warning, 'Pending review'),
      'declined': (AppColors.danger, 'Declined'),
      'none': (AppColors.textMuted, 'Not submitted'),
    };

    final (color, label) = map[status] ?? map['none']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'accepted'
                ? Icons.verified_rounded
                : status == 'pending'
                    ? Icons.schedule_rounded
                    : status == 'declined'
                        ? Icons.cancel_rounded
                        : Icons.info_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final dynamic profile;

  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Name', profile.fullName),
      ('Street / Purok', profile.streetPurok),
      ('Barangay', profile.barangay),
      ('City / Municipality', profile.cityMunicipality),
      ('Province', profile.province),
      ('Country', profile.country),
      ('Zip code', profile.zipCode),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2.trim().isEmpty ? '—' : r.$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _MyPosts extends StatefulWidget {
  @override
  State<_MyPosts> createState() => _MyPostsState();
}

class _MyPostsState extends State<_MyPosts> {
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Direct service call — no shared controller involved
      final svc = context.read<PostService>();
      final list = await svc.fetch(mine: true, status: 'any');
      if (!mounted) return;
      setState(() => _posts = list);
    } catch (e) {
      debugPrint('[MY POSTS] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('My posts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const Spacer(),
              Text('${_posts.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No posts yet.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            ..._posts.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.isClosed
                              ? AppColors.textMuted
                              : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        p.status,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}