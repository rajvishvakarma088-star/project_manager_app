import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/task_model.dart';
import '../navigation.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/task_card.dart';
import '../widgets/top_bar_button.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    TopBarButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => goBackOrHome(context),
                    ),
                    Expanded(
                      child: Text(
                        'Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appTextPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TopBarButton(
                      icon: Icons.add_rounded,
                      onTap: () => showAddEditTaskSheet(context, user.uid),
                    ),
                  ],
                ),
              ),
              const _FilterRow(),
              Expanded(
                child: Consumer<TaskFilterNotifier>(
                  builder: (context, filter, _) {
                    return StreamBuilder<List<TaskModel>>(
                      stream: context.read<FirestoreService>().getTasksStream(
                        user.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: LoadingShimmer(count: 3),
                          );
                        }
                        if (snapshot.hasError) {
                          return ErrorRetryWidget(
                            message: 'Something went wrong, try again',
                            onRetry: () => filter.setFilter(filter.filter),
                          );
                        }
                        final all = snapshot.data ?? const <TaskModel>[];
                        final tasks = filter.filter == 'all'
                            ? all
                            : all
                                  .where((task) => task.status == filter.filter)
                                  .toList();
                        if (tasks.isEmpty) return const _EmptyTasks();
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Slidable(
                              key: ValueKey(task.id),
                              startActionPane: ActionPane(
                                motion: const BehindMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => showAddEditTaskSheet(
                                      context,
                                      user.uid,
                                      task: task,
                                    ),
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _delete(context, user.uid, task.id),
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_rounded,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ],
                              ),
                              child: TaskCard(task: task),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const LiquidBottomNavBar(activeIndex: 1),
    );
  }

  Future<void> _delete(BuildContext context, String uid, String taskId) async {
    try {
      await context.read<FirestoreService>().deleteTask(uid, taskId);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, try again')),
      );
    }
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  static const filters = {
    'all': 'All',
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Consumer<TaskFilterNotifier>(
        builder: (context, notifier, _) {
          return Row(
            children: filters.entries.map((entry) {
              final active = notifier.filter == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => notifier.setFilter(entry.key),
                  borderRadius: BorderRadius.circular(99),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withOpacity(0.14)
                          : context.appSurface.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: active
                            ? AppColors.primary.withOpacity(0.30)
                            : context.appBorder.withOpacity(0.9),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: active
                            ? AppColors.primaryDark
                            : context.appTextMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                color: AppColors.primary,
                size: 46,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the center button to create your first task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
