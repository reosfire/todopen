import 'package:todopen/utils/uuid128.dart';

import 'recurrence.dart';

class Task {
  Uuid128 id;
  Set<Uuid128> tagIds;

  String title;
  String notes;
  bool isCompleted;
  DateTime createdAt;
  DateTime? scheduledDate;
  RecurrenceRule? recurrence;

  /// For recurring tasks: dates on which the task was explicitly completed.
  Set<DateTime> completedDates;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.isCompleted = false,
    required this.createdAt,
    this.scheduledDate,
    this.recurrence,
    Set<Uuid128>? tagIds,
    Set<DateTime>? completedDates,
  }) : tagIds = tagIds ?? {},
       completedDates = completedDates ?? {};

  bool isCompletedOn(DateTime date) {
    if (recurrence == null) return isCompleted;
    final d = DateTime(date.year, date.month, date.day);
    return completedDates.any(
      (c) => c.year == d.year && c.month == d.month && c.day == d.day,
    );
  }

  bool occursOn(DateTime date) {
    if (recurrence != null && scheduledDate != null) {
      return recurrence!.occursOn(date, scheduledDate!);
    }
    if (scheduledDate != null) {
      final d = DateTime(date.year, date.month, date.day);
      final s = DateTime(
        scheduledDate!.year,
        scheduledDate!.month,
        scheduledDate!.day,
      );
      return d == s;
    }
    return false;
  }
}
