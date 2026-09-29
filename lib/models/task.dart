import '../utils/uuid128.dart';
import 'recurrence.dart';

class Task {
  Uuid128 id;
  String title;
  String notes;
  bool isCompleted;
  DateTime createdAt;
  DateTime? scheduledDate;
  RecurrenceRule? recurrence;
  Set<Uuid128> tagIds;
  Uuid128 listId;

  // Intrusive linked list pointers for ordering tasks within a list.
  Uuid128? previousTaskId;
  Uuid128? nextTaskId;

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
    required this.listId,
    this.previousTaskId,
    this.nextTaskId,
    Set<DateTime>? completedDates,
  }) : tagIds = tagIds ?? {},
       completedDates = completedDates ?? {};

  // Both checks compare calendar fields rather than building midnight
  // DateTimes to compare: smart lists run them over every task on each
  // change, and constructing a DateTime is the expensive part.

  bool isCompletedOn(DateTime date) {
    if (recurrence == null) return isCompleted;
    return completedDates.any((c) => _sameDay(c, date));
  }

  bool occursOn(DateTime date) {
    final scheduled = scheduledDate;
    if (scheduled == null) return false;
    if (recurrence != null) return recurrence!.occursOn(date, scheduled);
    return _sameDay(scheduled, date);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;
}
