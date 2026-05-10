import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../navigation.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/top_bar_button.dart';
import 'add_edit_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

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
                        DateFormat('MMMM yyyy').format(_selectedDay),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
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
              _DateStrip(
                selectedDay: _selectedDay,
                onSelected: (day) => setState(() => _selectedDay = day),
              ),
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: context.read<FirestoreService>().getTasksStream(
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: LoadingShimmer(count: 4),
                      );
                    }
                    if (snapshot.hasError) {
                      return ErrorRetryWidget(
                        message: 'Something went wrong, try again',
                        onRetry: () => setState(() {}),
                      );
                    }

                    final all = snapshot.data ?? const <TaskModel>[];
                    final dayTasks =
                        all
                            .where((task) => _sameDay(task.date, _selectedDay))
                            .toList()
                          ..sort((a, b) => a.date.compareTo(b.date));

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        _DaySummary(day: _selectedDay, tasks: dayTasks),
                        const SizedBox(height: 16),
                        if (dayTasks.isEmpty)
                          const _EmptyCalendarDay()
                        else
                          ...dayTasks.map(
                            (task) => _CalendarTaskCard(task: task),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const LiquidBottomNavBar(activeIndex: 2),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selectedDay, required this.onSelected});

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final inactiveDayColor = context.appSurface;
    final start = selectedDay.subtract(Duration(days: selectedDay.weekday % 7));
    final days = List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return DateTime(day.year, day.month, day.day);
    });

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = _sameDay(day, selectedDay);
          return GestureDetector(
            onTap: () => onSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : inactiveDayColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appBorder, width: 1.3),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      color: active ? Colors.white : context.appTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      color: active ? Colors.white : context.appTextPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, required this.tasks});

  final DateTime day;
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((task) => task.status == 'completed').length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(day),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  tasks.isEmpty
                      ? 'No tasks scheduled'
                      : '$completed/${tasks.length} tasks done',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: context.appSurfaceSoft,
              color: AppColors.success,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTaskCard extends StatelessWidget {
  const _CalendarTaskCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final completed = task.status == 'completed';
    final accent = _priorityColor(task.priority);

    return GlassCard(
      radius: 18,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      onTap: () =>
          Navigator.pushNamed(context, '/task-detail', arguments: task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(label: _label(task.priority), color: accent),
                    const SizedBox(width: 8),
                    _Pill(label: _label(task.status), color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: context.appTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(task.date),
                      style: TextStyle(
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: completed ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.add_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _label(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyCalendarDay extends StatelessWidget {
  const _EmptyCalendarDay();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: AppColors.primary,
            size: 46,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nothing planned',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the add button to schedule a task for this day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
