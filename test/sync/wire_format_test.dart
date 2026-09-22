import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/domain_mapper.dart';
import 'package:todopen/sync/format/byte_io.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/models/recurrence.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/utils/uuid128.dart';

import 'replica_test.dart' show uid;

void main() {
  _formatPinningTests();

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
        final back = DomainMapper.filterFromBlob(DomainMapper.filterToBlob(f));
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
        DomainMapper.taskFrom(
          replica.get(EntityKind.task, uid(1))!,
        )!.scheduledDate,
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
      final replica = Replica()..applyAll(DomainMapper.createList(list, clock));
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
      final replica = Replica()..applyAll(DomainMapper.createList(list, clock));
      final back = DomainMapper.listFrom(
        replica.get(EntityKind.list, uid(1))!,
      )!;
      expect(back.colorValue, isNull);
      expect(back.folderId, isNull);
    });
  });
}

/// These encoders (recurrence blob, filter blob, days-since-epoch) and the
/// order scopes define the on-the-wire layout of a synced store.
///
/// Changing any of them silently reinterprets bytes other devices have
/// already written, so the expected values are spelled out literally here
/// rather than derived from the implementation. If a layout changes, this
/// fails — which is the point.
void _formatPinningTests() {
  group('wire format pinning', () {
    test('recurrence blob layout is byte-identical', () {
      // The layout: one tag byte, then the rule's varint arguments.
      Uint8List expected(int tag, List<int> varints) {
        final w = ByteWriter(8);
        w.u8(tag);
        for (final v in varints) {
          w.varint(v);
        }
        return w.takeBytes();
      }

      final cases = <(RecurrenceRule, int, List<int>)>[
        (const DailyRecurrence(), 0, []),
        (const EveryNDaysRecurrence(3), 1, [3]),
        (
          WeeklyRecurrence.fromDays([1, 3]),
          2,
          [
            WeeklyRecurrence.fromDays([1, 3]).weekdayBits,
          ],
        ),
        (const MonthlyRecurrence(15), 3, [15]),
        (const YearlyRecurrence(12, 25), 4, [12, 25]),
      ];
      for (final (rule, tag, args) in cases) {
        expect(
          DomainMapper.recurrenceToBlob(rule),
          expected(tag, args),
          reason: rule.describe(),
        );
      }
    });

    test('filter blob tag bytes are stable', () {
      // These tag bytes are part of the stored format and must not shift.
      final expected = <SmartListFilter, int>{
        const TodayFilter(): 0,
        const TomorrowFilter(): 1,
        const UpcomingFilter(): 2,
        const OverdueFilter(): 3,
        const CompletedFilter(): 4,
        const AllTasksFilter(): 5,
        const DateRangeFilter(): 6,
        const TagsFilter(tagIds: {}): 7,
      };
      expected.forEach((filter, tag) {
        expect(
          DomainMapper.filterToBlob(filter).first,
          tag,
          reason: '$filter must encode with tag $tag',
        );
      });
    });

    test('days-since-epoch uses the UTC calendar date', () {
      // Days since the Unix epoch, taken from the UTC calendar date.
      int expectedDays(int millis) {
        final d = DateTime.fromMillisecondsSinceEpoch(millis);
        return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
            86400000;
      }

      for (final d in [
        DateTime(2024, 1, 1, 13, 45),
        DateTime(2025, 6, 30),
        DateTime(1999, 12, 31, 23, 59),
      ]) {
        expect(
          DomainMapper.toDays(d),
          expectedDays(d.millisecondsSinceEpoch),
          reason: '$d',
        );
      }
    });

    test('sidebar scope is the zero-uuid list scope', () {
      expect(
        DomainMapper.sidebarScope,
        OrderScope(EntityKind.list, Uuid128.fromBytes(Uint8List(16)), 0),
      );
    });

    test('task scope lanes split pending from completed', () {
      final list = uid(5);
      expect(
        DomainMapper.taskScope(list, completed: false),
        OrderScope(EntityKind.task, list, 0),
      );
      expect(
        DomainMapper.taskScope(list, completed: true),
        OrderScope(EntityKind.task, list, 1),
      );
    });
  });
}
