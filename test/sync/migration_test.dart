import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/domain_mapper.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/models/recurrence.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/utils/uuid128.dart';

import 'replica_test.dart' show uid;

/// Reimplementation of the migration's linked-list walk, so the algorithm
/// that rebuilds ordering from v1 data is tested without needing a live
/// Dropbox account.
///
/// Mirrors `tool/migrate_v2.dart::_walkChain`.
({List<Uuid128> ids, bool broken}) walkChain(
  List<({Uuid128 id, Uuid128? prev, Uuid128? next, int createdMs})> tasks,
) {
  final byId = {for (final t in tasks) t.id: t};
  final hasPrev = <Uuid128>{};
  for (final t in tasks) {
    if (t.prev != null && byId.containsKey(t.prev)) hasPrev.add(t.id);
  }

  Uuid128? head;
  for (final t in tasks) {
    if (!hasPrev.contains(t.id)) {
      head = t.id;
      break;
    }
  }

  final out = <Uuid128>[];
  final seen = <Uuid128>{};
  var cursor = head;
  while (cursor != null && seen.add(cursor)) {
    out.add(cursor);
    final t = byId[cursor];
    if (t == null || t.next == null) break;
    cursor = byId.containsKey(t.next) ? t.next : null;
  }

  final orphans = byId.keys.where((id) => !seen.contains(id)).toList()
    ..sort((a, b) => byId[b]!.createdMs.compareTo(byId[a]!.createdMs));
  out.addAll(orphans);
  return (ids: out, broken: orphans.isNotEmpty);
}

void main() {
  group('linked list → dense array', () {
    ({Uuid128 id, Uuid128? prev, Uuid128? next, int createdMs}) t(
      int n, {
      int? prev,
      int? next,
      int created = 0,
    }) => (
      id: uid(n),
      prev: prev == null ? null : uid(prev),
      next: next == null ? null : uid(next),
      createdMs: created,
    );

    test('walks a well-formed chain', () {
      final result = walkChain([
        t(2, prev: 1, next: 3),
        t(1, next: 2),
        t(3, prev: 2),
      ]);
      expect(result.ids, [uid(1), uid(2), uid(3)]);
      expect(result.broken, isFalse);
    });

    test('single task', () {
      final result = walkChain([t(1)]);
      expect(result.ids, [uid(1)]);
      expect(result.broken, isFalse);
    });

    test('recovers orphans rather than dropping them', () {
      // uid(9) is in no chain at all — the v1 format allowed this and the
      // old UI silently appended such tasks.
      final result = walkChain([
        t(1, next: 2),
        t(2, prev: 1),
        t(9, created: 500),
      ]);
      expect(result.ids.toSet(), {uid(1), uid(2), uid(9)});
      expect(result.ids.last, uid(9));
      expect(result.broken, isTrue);
    });

    test('survives a cycle without hanging', () {
      // A ↔ B pointing at each other, which the old code guarded against.
      final result = walkChain([
        t(1, prev: 2, next: 2),
        t(2, prev: 1, next: 1),
      ]);
      expect(result.ids.toSet(), {uid(1), uid(2)});
      expect(result.ids.length, 2, reason: 'no duplicates from the cycle');
    });

    test('dangling next pointer stops the walk cleanly', () {
      final result = walkChain([t(1, next: 404), t(2, created: 1)]);
      expect(result.ids.toSet(), {uid(1), uid(2)});
    });

    test('orphans are ordered newest-first, matching the old UI', () {
      final result = walkChain([
        t(1, next: 2),
        t(2, prev: 1),
        t(7, created: 100),
        t(8, created: 300),
        t(9, created: 200),
      ]);
      expect(result.ids.sublist(0, 2), [uid(1), uid(2)]);
      expect(result.ids.sublist(2), [uid(8), uid(9), uid(7)]);
    });

    test('empty input', () {
      expect(walkChain([]).ids, isEmpty);
    });
  });

  group('recurrence blob round-trip', () {
    test('covers every rule type', () {
      final rules = <RecurrenceRule>[
        const DailyRecurrence(),
        const EveryNDaysRecurrence(3),
        const EveryNDaysRecurrence(365),
        WeeklyRecurrence.fromDays([1, 3, 5]),
        const MonthlyRecurrence(15),
        const YearlyRecurrence(12, 25),
      ];
      for (final r in rules) {
        final blob = DomainMapper.recurrenceToBlob(r);
        final back = DomainMapper.recurrenceFromBlob(blob);
        expect(back.runtimeType, r.runtimeType);
        expect(back!.describe(), r.describe(), reason: r.describe());
      }
    });

    test('null blob yields null', () {
      expect(DomainMapper.recurrenceFromBlob(null), isNull);
      expect(DomainMapper.recurrenceFromBlob(Uint8List(0)), isNull);
    });

    test('is compact', () {
      expect(DomainMapper.recurrenceToBlob(const DailyRecurrence()).length, 1);
      expect(
        DomainMapper.recurrenceToBlob(const YearlyRecurrence(12, 25)).length,
        3,
      );
    });
  });

  group('smart list filter blob round-trip', () {
    test('covers every filter type', () {
      final filters = <SmartListFilter>[
        const TodayFilter(),
        const TomorrowFilter(),
        const UpcomingFilter(),
        const OverdueFilter(),
        const CompletedFilter(),
        const AllTasksFilter(),
        DateRangeFilter(
          dateFrom: DateTime(2024, 1, 15),
          dateTo: DateTime(2024, 6, 30),
        ),
        const DateRangeFilter(),
        DateRangeFilter(dateFrom: DateTime(2025, 3, 1)),
        TagsFilter(tagIds: {uid(1), uid(2)}),
        const TagsFilter(tagIds: {}),
      ];
      for (final f in filters) {
        final back = DomainMapper.filterFromBlob(
          DomainMapper.filterToBlob(f),
        );
        expect(back.runtimeType, f.runtimeType, reason: '$f');
        switch ((f, back)) {
          case (DateRangeFilter a, DateRangeFilter b):
            expect(b.dateFrom, a.dateFrom);
            expect(b.dateTo, a.dateTo);
          case (TagsFilter a, TagsFilter b):
            expect(b.tagIds, a.tagIds);
          default:
            break;
        }
      }
    });
  });

  group('date conversion', () {
    test('round-trips day-resolution dates', () {
      for (final d in [
        DateTime(1970, 1, 1),
        DateTime(2024, 2, 29),
        DateTime(2025, 12, 31),
        DateTime(2100, 6, 15),
      ]) {
        expect(DomainMapper.fromDays(DomainMapper.toDays(d)), d);
      }
    });

    test('ignores the time component', () {
      final morning = DateTime(2025, 5, 10, 8, 30);
      final evening = DateTime(2025, 5, 10, 23, 59);
      expect(DomainMapper.toDays(morning), DomainMapper.toDays(evening));
    });
  });

  group('domain mapper task round-trip', () {
    test('a fully populated task survives ops → replica → task', () {
      final clock = HlcClock(deviceId: 1);
      final original = Task(
        id: uid(1),
        title: 'Buy oat milk',
        notes: 'the barista kind',
        isCompleted: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        scheduledDate: DateTime(2025, 7, 4),
        recurrence: WeeklyRecurrence.fromDays([2, 4]),
        tagIds: {uid(10), uid(11)},
        listId: uid(99),
        completedDates: {DateTime(2025, 7, 4), DateTime(2025, 7, 11)},
      );

      final replica = Replica()
        ..applyAll(DomainMapper.createTask(original, clock));
      final back = DomainMapper.taskFrom(
        replica.get(EntityKind.task, uid(1))!,
      )!;

      expect(back.id, original.id);
      expect(back.title, original.title);
      expect(back.notes, original.notes);
      expect(back.isCompleted, original.isCompleted);
      expect(back.createdAt, original.createdAt);
      expect(back.scheduledDate, original.scheduledDate);
      expect(back.listId, original.listId);
      expect(back.tagIds, original.tagIds);
      expect(back.completedDates, original.completedDates);
      expect(back.recurrence?.describe(), original.recurrence?.describe());
    });

    test('an update emits ops only for changed fields', () {
      final clock = HlcClock(deviceId: 1);
      final before = Task(
        id: uid(1),
        title: 'old',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        listId: uid(99),
      );
      final after = Task(
        id: uid(1),
        title: 'new',
        createdAt: before.createdAt,
        listId: uid(99),
      );

      final ops = DomainMapper.updateTask(after, before, clock);
      expect(ops.length, 1, reason: 'only the title changed');
      expect((ops.first as SetFieldOp).field, TaskField.title);
    });

    test('an unchanged task emits nothing', () {
      final clock = HlcClock(deviceId: 1);
      final t = Task(
        id: uid(1),
        title: 'same',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        listId: uid(99),
      );
      expect(DomainMapper.updateTask(t, t, clock), isEmpty);
    });

    test('clearing an optional field emits an explicit null', () {
      final clock = HlcClock(deviceId: 1);
      final before = Task(
        id: uid(1),
        title: 't',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        listId: uid(99),
        scheduledDate: DateTime(2025, 1, 1),
      );
      final after = Task(
        id: uid(1),
        title: 't',
        createdAt: before.createdAt,
        listId: uid(99),
      );
      // Create first, so the update's timestamps are genuinely later.
      final replica = Replica()
        ..applyAll(DomainMapper.createTask(before, clock));

      final ops = DomainMapper.updateTask(after, before, clock);
      expect(ops.length, 1);
      expect((ops.first as SetFieldOp).value, isA<NullValue>());

      // And the cleared value must actually read back as null.
      replica.applyAll(ops);
      expect(
        DomainMapper.taskFrom(replica.get(EntityKind.task, uid(1))!)!
            .scheduledDate,
        isNull,
      );
    });
  });

  group('domain mapper list round-trip', () {
    test('preserves colour and folder', () {
      final clock = HlcClock(deviceId: 1);
      final list = TaskList(
        id: uid(1),
        name: 'Work',
        colorValue: 0xFF26C6DA,
        folderId: uid(50),
      );
      final replica = Replica()
        ..applyAll(DomainMapper.createList(list, clock));
      final back = DomainMapper.listFrom(
        replica.get(EntityKind.list, uid(1))!,
      )!;
      expect(back.name, 'Work');
      expect(back.colorValue, 0xFF26C6DA);
      expect(back.folderId, uid(50));
    });

    test('a list with no colour or folder reads back as null', () {
      final clock = HlcClock(deviceId: 1);
      final list = TaskList(id: uid(1), name: 'Inbox');
      final replica = Replica()
        ..applyAll(DomainMapper.createList(list, clock));
      final back = DomainMapper.listFrom(
        replica.get(EntityKind.list, uid(1))!,
      )!;
      expect(back.colorValue, isNull);
      expect(back.folderId, isNull);
    });
  });
}
