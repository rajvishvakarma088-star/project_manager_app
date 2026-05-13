import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/custom_text_field.dart';
import '../services/notification_service.dart';

Future<void> showAddEditTaskSheet(
  BuildContext context,
  String uid, {
  TaskModel? task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEditTaskScreen(uid: uid, task: task),
  );
}

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, required this.uid, this.task});

  final String uid;
  final TaskModel? task;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _priority = 'medium';
  String _status = 'pending';
  bool _loading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _title.text = task.title;
      _description.text = task.description;
      _date = task.date;
      _time = TimeOfDay.fromDateTime(task.date);
      _priority = task.priority;
      _status = task.status;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String? get _titleError {
    if (!_submitted) return null;
    final value = _title.text.trim();
    if (value.isEmpty) return 'Title is required';
    if (value.length > 80) return 'Title must be 80 characters or less';
    return null;
  }

  String? get _descriptionError {
    if (!_submitted) return null;
    if (_description.text.trim().length > 300) {
      return 'Description must be 300 characters or less';
    }
    return null;
  }

  String? get _dateError {
    if (!_submitted) return null;
    if (_date == null) return 'Due date is required';
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    if (_date!.isBefore(start)) return 'Due date cannot be in the past';
    return null;
  }

  String? get _timeError {
    if (!_submitted) return null;
    if (_time == null) return 'Time is required';
    if (_date != null) {
      final now = DateTime.now();
      final combined = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      );
      if (combined.isBefore(now)) return 'Time cannot be in the past';
    }
    return null;
  }

  bool get _valid =>
      _titleError == null &&
      _descriptionError == null &&
      _dateError == null &&
      _timeError == null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_valid) return;
    setState(() => _loading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? widget.uid;
      final now = DateTime.now();
      final combinedDate = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      );
      final task = TaskModel(
        id: widget.task?.id ?? '',
        userId: userId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        date: combinedDate,
        status: _status,
        priority: _priority,
        createdAt: widget.task?.createdAt ?? now,
      );
      final service = context.read<FirestoreService>();
      if (widget.task == null) {
        // Schedule notifications FIRST so they work even if Firebase is offline
        
        // Show immediate feedback
        context.read<NotificationService>().showLocalNotification(
          'Task Created Successfully! 🎉',
          '${task.title} has been added to your pending tasks.',
        );
        
        // Schedule reminder 30 minutes before the task
        final scheduledTime = combinedDate.subtract(const Duration(minutes: 30));
        context.read<NotificationService>().scheduleTaskReminder(
          'Upcoming Task: ${task.title}',
          'Your task is due in 30 minutes!',
          scheduledTime,
        );

        // Schedule reminder for 9:00 AM on the day of the task IF task is after 9 AM
        final scheduledTimeMorning = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          9, // 9 AM
          0,
        );
        if (combinedDate.isAfter(scheduledTimeMorning)) {
          context.read<NotificationService>().scheduleTaskReminder(
            'Morning Reminder: ${task.title}',
            'Don\'t forget to complete your task today!',
            scheduledTimeMorning,
          );
        }

        // Schedule reminder for 2:00 PM on the day of the task IF task is after 2 PM
        final scheduledTimeAfternoon = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          14, // 2 PM
          0,
        );
        if (combinedDate.isAfter(scheduledTimeAfternoon)) {
          context.read<NotificationService>().scheduleTaskReminder(
            'Afternoon Reminder: ${task.title}',
            'Just checking in! Make sure to finish your task.',
            scheduledTimeAfternoon,
          );
        }

        // Now attempt to save to Firebase
        await service.addTask(task);
      } else {
        await service.updateTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, try again')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: context.appBorder.withOpacity(0.9),
              width: 1.5,
            ),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              MediaQuery.of(context).viewInsets.bottom + 26,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.appTextMuted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ),
                  Expanded(
                    child: Text(
                      widget.task == null ? 'New Task' : 'Edit Task',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Task Title *',
                controller: _title,
                hintText: 'Implement auth flow',
                errorText: _titleError,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _description,
                hintText: 'Add a description...',
                maxLines: 3,
                errorText: _descriptionError,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date *',
                          style: TextStyle(
                            color: context.appTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            decoration: _fieldDecoration(_dateError != null),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _date == null
                                      ? 'Pick date'
                                      : DateFormat(
                                          'MMM d, yyyy',
                                        ).format(_date!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time *',
                          style: TextStyle(
                            color: context.appTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            decoration: _fieldDecoration(_timeError != null),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _time == null
                                      ? 'Pick time'
                                      : _time!.format(context),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_dateError != null || _timeError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _dateError ?? _timeError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Selector(
                      label: 'Priority',
                      value: _priority,
                      values: const ['low', 'medium', 'high'],
                      onChanged: (v) => setState(() => _priority = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Selector(
                      label: 'Status',
                      value: _status,
                      values: const ['pending', 'in_progress', 'completed'],
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.task == null ? 'Create Task' : 'Update Task',
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _fieldDecoration(bool error) {
    return BoxDecoration(
      color: context.appSurface.withOpacity(0.72),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: error
            ? AppColors.error.withOpacity(0.5)
            : context.appBorder.withOpacity(0.8),
        width: 1.5,
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.appTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((item) {
            final active = item == value;
            return ChoiceChip(
              label: Text(_label(item)),
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onChanged(item),
              labelStyle: TextStyle(
                color: active ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              selectedColor: AppColors.primary.withOpacity(0.12),
              backgroundColor: context.appSurface.withOpacity(0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: active
                      ? AppColors.primary.withOpacity(0.35)
                      : context.appBorder,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _label(String item) {
    return item
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
