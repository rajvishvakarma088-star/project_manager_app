import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'glass_card.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.compact = false});

  final TaskModel task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final completed = task.status == 'completed';
    final accent = _priorityColor(task.priority);
    final titleColor = completed
        ? context.appTextMuted
        : context.appTextPrimary;
    return GlassCard(
      radius: 20,
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      onTap: () =>
          Navigator.pushNamed(context, '/task-detail', arguments: task),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 14 : 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          await context
                              .read<FirestoreService>()
                              .toggleTaskStatus(
                                task.userId,
                                task.id,
                                completed ? 'pending' : 'completed',
                              );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Something went wrong, try again'),
                            ),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: completed
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    AppColors.success,
                                  ],
                                )
                              : null,
                          border: completed
                              ? null
                              : Border.all(
                                  color: AppColors.primary.withOpacity(0.45),
                                  width: 2.4,
                                ),
                        ),
                        child: completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Chip(
                                icon: Icons.calendar_today_rounded,
                                label: DateFormat('MMM d').format(task.date),
                              ),
                              _Chip(
                                label: _label(task.status),
                                color: _statusColor(task.status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Chip(label: _label(task.priority), color: accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return AppColors.success;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primaryDark;
      default:
        return AppColors.warning;
    }
  }

  String _label(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
