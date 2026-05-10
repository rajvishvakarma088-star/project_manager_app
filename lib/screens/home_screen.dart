import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/quote_widget.dart';
import '../widgets/task_card.dart';
import '../widgets/top_bar_button.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Friend';
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<List<TaskModel>>(
            stream: context.read<FirestoreService>().getTasksStream(user.uid),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? const <TaskModel>[];
              final done = tasks
                  .where((task) => task.status == 'completed')
                  .length;
              final pending = tasks
                  .where((task) => task.status != 'completed')
                  .length;
              final today = DateTime.now();
              final todayTasks = tasks
                  .where((task) {
                    return task.date.year == today.year &&
                        task.date.month == today.month &&
                        task.date.day == today.day;
                  })
                  .take(3)
                  .toList();
              final preview = todayTasks.isEmpty
                  ? tasks.take(3).toList()
                  : todayTasks;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TopBarButton(
                        icon: Icons.add_rounded,
                        onTap: () => showAddEditTaskSheet(context, user.uid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const QuoteWidget(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: tasks.length.toString(),
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Done',
                        value: done.toString(),
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Pending',
                        value: pending.toString(),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "TODAY'S TASKS",
                          style: TextStyle(
                            color: context.appTextMuted,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/tasks'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LoadingShimmer(count: 3)
                  else if (preview.isEmpty)
                    const _EmptyPreview()
                  else
                    ...preview.map(
                      (task) => TaskCard(task: task, compact: true),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const LiquidBottomNavBar(activeIndex: 0),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: AppColors.primary.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            'No tasks yet',
            style: TextStyle(
              color: context.appTextSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
