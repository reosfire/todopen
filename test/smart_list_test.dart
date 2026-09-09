import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/models/recurrence.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/utils/uuid128.dart';

Task _task({
  DateTime? scheduledDate,
  RecurrenceRule? recurrence,
  bool isCompleted = false,
  Set<DateTime>? completedDates,
}) {
  return Task(
    id: Uuid128.generateV4(),
    title: 'task',
    createdAt: DateTime(2026, 1, 1),
    listId: Uuid128.generateV4(),
    scheduledDate: scheduledDate,
    recurrence: recurrence,
    isCompleted: isCompleted,
    completedDates: completedDates,
  );
}

int _sectionTotal(List<TaskSection> sections) =>
    sections.fold(0, (sum, s) => sum + s.tasks.length);

void main() {
  group('UpcomingFilter', () {
    test('badge count matches the number of tasks actually displayed', () {
      final tasks = [
        // Recurring daily task — appears in several day sections.
        _task(
          scheduledDate: DateTime(2026, 1, 1),
          recurrence: const DailyRecurrence(),
        ),
        // Far-future dated task — lands in "Later".
        _task(scheduledDate: DateTime(2030, 1, 1)),
        // Undated task — never shown by this filter.
        _task(),
      ];

      const filter = UpcomingFilter();
      expect(filter.countTasks(tasks), _sectionTotal(filter.organize(tasks)));
    });

    test('undated tasks are neither shown nor counted', () {
      final tasks = [_task(), _task()];
      const filter = UpcomingFilter();
      expect(filter.organize(tasks), isEmpty);
      expect(filter.countTasks(tasks), 0);
    });
  });

  group('CompletedFilter', () {
    test('includes a recurring task that has a recorded completion', () {
      final recurring = _task(
        scheduledDate: DateTime(2026, 1, 1),
        recurrence: const DailyRecurrence(),
        completedDates: {DateTime(2026, 9, 10)},
      );

      const filter = CompletedFilter();
      expect(filter.countTasks([recurring]), 1);
      expect(_sectionTotal(filter.organize([recurring])), 1);
    });

    test('excludes a recurring task with no completions', () {
      final recurring = _task(
        scheduledDate: DateTime(2026, 1, 1),
        recurrence: const DailyRecurrence(),
      );

      const filter = CompletedFilter();
      expect(filter.countTasks([recurring]), 0);
      expect(_sectionTotal(filter.organize([recurring])), 0);
    });

    test('still uses isCompleted for non-recurring tasks', () {
      final done = _task(isCompleted: true);
      final pending = _task();

      const filter = CompletedFilter();
      expect(filter.countTasks([done, pending]), 1);
    });
  });
}
