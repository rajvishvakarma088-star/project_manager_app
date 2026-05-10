import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/task_model.dart';
import '../navigation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/top_bar_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'User';

    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<List<TaskModel>>(
            stream: context.read<FirestoreService>().getTasksStream(user.uid),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? const <TaskModel>[];
              final completed = tasks
                  .where((task) => task.status == 'completed')
                  .length;
              final active = tasks.length - completed;
              final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
              final upcoming =
                  tasks.where((task) => task.status != 'completed').toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                children: [
                  Row(
                    children: [
                      TopBarButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => goBackOrHome(context),
                      ),
                      Expanded(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TopBarButton(
                        icon: Icons.edit_rounded,
                        onTap: () => showEditProfileSheet(context, user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _ProfilePhoto(user: user, name: name),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'Signed in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            _Metric(
                              label: 'Tasks',
                              value: tasks.length.toString(),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _Metric(
                              label: 'Done',
                              value: completed.toString(),
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _Metric(
                              label: 'Active',
                              value: active.toString(),
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LoadingShimmer(count: 2)
                  else ...[
                    _ProgressPanel(progress: progress),
                    const SizedBox(height: 16),
                    _FocusPanel(
                      task: upcoming.isEmpty ? null : upcoming.first,
                      progress: progress,
                    ),
                    const SizedBox(height: 16),
                    _SettingsPanel(onLogout: () => _signOut(context)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const LiquidBottomNavBar(activeIndex: 3),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await context.read<AuthService>().signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, try again')),
      );
    }
  }
}

Future<void> showEditProfileSheet(BuildContext context, User user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _photoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName ?? '');
    _photoUrl = TextEditingController(text: widget.user.photoURL ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.user.updateDisplayName(_name.text.trim());
      await widget.user.updatePhotoURL(
        _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim(),
      );
      await widget.user.reload();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, try again')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: context.appBorder.withOpacity(0.9)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appTextMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TopBarButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TopBarButton(
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _photoUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Photo URL'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.user, required this.name});

  final User user;
  final String name;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipOval(
            child: photoUrl == null || photoUrl.isEmpty
                ? DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.success, AppColors.primary],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Image.network(photoUrl, fit: BoxFit.cover),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: context.appSurface, width: 3),
          ),
          child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: context.appSurfaceSoft,
              color: AppColors.success,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percent% Done',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completion score across your current task list.',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.task, required this.progress});

  final TaskModel? task;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final message = progress >= 0.75
        ? 'Strong pace today'
        : progress >= 0.35
        ? 'Keep the flow steady'
        : 'Start with one focused task';

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  task == null
                      ? 'No active task is waiting.'
                      : 'Next: ${task!.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w600,
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Consumer<ThemeModeNotifier>(
            builder: (context, theme, _) {
              return _ProfileRow(
                icon: theme.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                label: 'Dark theme',
                trailing: Switch.adaptive(
                  value: theme.isDark,
                  activeColor: AppColors.primary,
                  onChanged: theme.setDark,
                ),
                onTap: () => theme.setDark(!theme.isDark),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.28)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 21),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: context.appTextPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}
