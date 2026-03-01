import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../models/folder.dart';
import '../models/tag.dart';
import '../models/smart_list.dart';
import '../models/recurrence.dart';
import '../models/sync_index.dart';
import '../proto/models.pb.dart';

/// Converts between domain models and protobuf messages.
///
/// Timestamps are stored as milliseconds since epoch (Int64).
/// A value of 0 means "not set" for optional timestamps.
class ProtoSerializer {
  // ───── Helpers ─────

  static Int64 _toMs(DateTime dt) => Int64(dt.millisecondsSinceEpoch);
  static DateTime _fromMs(Int64 ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms.toInt());

  /// UUID string → 16 raw bytes.
  static Uint8List _uuidToBytes(String uuid) =>
      Uint8List.fromList(Uuid.parse(uuid));

  /// 16 raw bytes → UUID string.
  static String _uuidFromBytes(List<int> bytes) => Uuid.unparse(bytes);

  /// Optional UUID: null → empty bytes, non-null → 16 bytes.
  static List<int> _optUuidToBytes(String? uuid) =>
      uuid == null ? const [] : Uint8List.fromList(Uuid.parse(uuid));

  /// Optional UUID: empty bytes → null, 16 bytes → UUID string.
  static String? _optUuidFromBytes(List<int> bytes) =>
      bytes.isEmpty ? null : Uuid.unparse(bytes);

  // ───── RecurrenceRule ─────

  static ProtoRecurrenceRule recurrenceToProto(RecurrenceRule r) {
    return switch (r) {
      DailyRecurrence() =>
        ProtoRecurrenceRule(daily: ProtoDailyRecurrence()),
      EveryNDaysRecurrence(:final interval) =>
        ProtoRecurrenceRule(
          everyNDays: ProtoEveryNDaysRecurrence(interval: interval),
        ),
      WeeklyRecurrence(:final weekdays) =>
        ProtoRecurrenceRule(
          weekly: ProtoWeeklyRecurrence(weekdays: weekdays.toList()),
        ),
      MonthlyRecurrence(:final dayOfMonth) =>
        ProtoRecurrenceRule(
          monthly: ProtoMonthlyRecurrence(dayOfMonth: dayOfMonth),
        ),
      YearlyRecurrence(:final month, :final dayOfMonth) =>
        ProtoRecurrenceRule(
          yearly: ProtoYearlyRecurrence(month: month, dayOfMonth: dayOfMonth),
        ),
    };
  }

  static RecurrenceRule recurrenceFromProto(ProtoRecurrenceRule p) {
    return switch (p.whichRule()) {
      ProtoRecurrenceRule_Rule.daily => DailyRecurrence(),
      ProtoRecurrenceRule_Rule.everyNDays =>
        EveryNDaysRecurrence(p.everyNDays.interval),
      ProtoRecurrenceRule_Rule.weekly =>
        WeeklyRecurrence(p.weekly.weekdays.toSet()),
      ProtoRecurrenceRule_Rule.monthly =>
        MonthlyRecurrence(p.monthly.dayOfMonth),
      ProtoRecurrenceRule_Rule.yearly =>
        YearlyRecurrence(p.yearly.month, p.yearly.dayOfMonth),
      ProtoRecurrenceRule_Rule.notSet =>
        throw StateError('RecurrenceRule has no variant set'),
    };
  }

  // ───── SmartListFilter ─────

  static ProtoSmartListFilter filterToProto(SmartListFilter f) {
    return switch (f) {
      TodayFilter() =>
        ProtoSmartListFilter(today: ProtoTodayFilter()),
      TomorrowFilter() =>
        ProtoSmartListFilter(tomorrow: ProtoTomorrowFilter()),
      UpcomingFilter() =>
        ProtoSmartListFilter(upcoming: ProtoUpcomingFilter()),
      OverdueFilter() =>
        ProtoSmartListFilter(overdue: ProtoOverdueFilter()),
      CompletedFilter() =>
        ProtoSmartListFilter(completed: ProtoCompletedFilter()),
      AllTasksFilter() =>
        ProtoSmartListFilter(all: ProtoAllTasksFilter()),
      DateRangeFilter(:final dateFrom, :final dateTo) =>
        ProtoSmartListFilter(
          dateRange: ProtoDateRangeFilter(
            hasDateFrom: dateFrom != null,
            dateFromMs: dateFrom != null ? _toMs(dateFrom) : Int64.ZERO,
            hasDateTo: dateTo != null,
            dateToMs: dateTo != null ? _toMs(dateTo) : Int64.ZERO,
          ),
        ),
      TagsFilter(:final tagIds) =>
        ProtoSmartListFilter(
          tags: ProtoTagsFilter(tagIds: tagIds.map(_uuidToBytes)),
        ),
    };
  }

  static SmartListFilter filterFromProto(ProtoSmartListFilter p) {
    return switch (p.whichFilter()) {
      ProtoSmartListFilter_Filter.today => const TodayFilter(),
      ProtoSmartListFilter_Filter.tomorrow => const TomorrowFilter(),
      ProtoSmartListFilter_Filter.upcoming => const UpcomingFilter(),
      ProtoSmartListFilter_Filter.overdue => const OverdueFilter(),
      ProtoSmartListFilter_Filter.completed => const CompletedFilter(),
      ProtoSmartListFilter_Filter.all => const AllTasksFilter(),
      ProtoSmartListFilter_Filter.dateRange => DateRangeFilter(
          dateFrom: p.dateRange.hasDateFrom ? _fromMs(p.dateRange.dateFromMs) : null,
          dateTo: p.dateRange.hasDateTo ? _fromMs(p.dateRange.dateToMs) : null,
        ),
      ProtoSmartListFilter_Filter.tags =>
        TagsFilter(tagIds: p.tags.tagIds.map(_uuidFromBytes).toSet()),
      ProtoSmartListFilter_Filter.notSet => const AllTasksFilter(),
    };
  }

  // ───── Task ─────

  static Uint8List taskToBytes(Task t) {
    final p = ProtoTask(
      id: _uuidToBytes(t.id),
      title: t.title,
      notes: t.notes,
      isCompleted: t.isCompleted,
      createdAtMs: _toMs(t.createdAt),
      scheduledDateMs:
          t.scheduledDate != null ? _toMs(t.scheduledDate!) : Int64.ZERO,
      tagIds: t.tagIds.map(_uuidToBytes),
      listId: _uuidToBytes(t.listId),
      previousTaskId: _optUuidToBytes(t.previousTaskId),
      nextTaskId: _optUuidToBytes(t.nextTaskId),
      completedDatesMs: t.completedDates.map(_toMs),
    );
    if (t.recurrence != null) p.recurrence = recurrenceToProto(t.recurrence!);
    return Uint8List.fromList(p.writeToBuffer());
  }

  static Task taskFromBytes(Uint8List bytes) {
    final p = ProtoTask.fromBuffer(bytes);
    return Task(
      id: _uuidFromBytes(p.id),
      title: p.title,
      notes: p.notes,
      isCompleted: p.isCompleted,
      createdAt: _fromMs(p.createdAtMs),
      scheduledDate: p.scheduledDateMs != Int64.ZERO
          ? _fromMs(p.scheduledDateMs)
          : null,
      recurrence: p.hasRecurrence() ? recurrenceFromProto(p.recurrence) : null,
      tagIds: p.tagIds.map(_uuidFromBytes).toSet(),
      listId: _uuidFromBytes(p.listId),
      previousTaskId: _optUuidFromBytes(p.previousTaskId),
      nextTaskId: _optUuidFromBytes(p.nextTaskId),
      completedDates: p.completedDatesMs.map(_fromMs).toSet(),
    );
  }

  // ───── TaskList ─────

  static Uint8List listToBytes(TaskList l) {
    final p = ProtoTaskList(
      id: _uuidToBytes(l.id),
      name: l.name,
      hasColor: l.colorValue != null,
      colorValue: l.colorValue ?? 0,
      folderId: _optUuidToBytes(l.folderId),
      order: l.order,
    );
    return Uint8List.fromList(p.writeToBuffer());
  }

  static TaskList listFromBytes(Uint8List bytes) {
    final p = ProtoTaskList.fromBuffer(bytes);
    return TaskList(
      id: _uuidFromBytes(p.id),
      name: p.name,
      colorValue: p.hasColor ? p.colorValue : null,
      folderId: _optUuidFromBytes(p.folderId),
      order: p.order,
    );
  }

  // ───── Folder ─────

  static Uint8List folderToBytes(Folder f) {
    return Uint8List.fromList(
      ProtoFolder(id: _uuidToBytes(f.id), name: f.name, order: f.order)
          .writeToBuffer(),
    );
  }

  static Folder folderFromBytes(Uint8List bytes) {
    final p = ProtoFolder.fromBuffer(bytes);
    return Folder(id: _uuidFromBytes(p.id), name: p.name, order: p.order);
  }

  // ───── Tag ─────

  static Uint8List tagToBytes(Tag t) {
    return Uint8List.fromList(
      ProtoTag(id: _uuidToBytes(t.id), name: t.name, colorValue: t.colorValue)
          .writeToBuffer(),
    );
  }

  static Tag tagFromBytes(Uint8List bytes) {
    final p = ProtoTag.fromBuffer(bytes);
    return Tag(id: _uuidFromBytes(p.id), name: p.name, colorValue: p.colorValue);
  }

  // ───── SmartList ─────

  static Uint8List smartListToBytes(SmartList s) {
    return Uint8List.fromList(
      ProtoSmartList(
        id: _uuidToBytes(s.id),
        name: s.name,
        iconCodePoint: s.iconCodePoint,
        colorValue: s.colorValue,
        filter: filterToProto(s.filter),
      ).writeToBuffer(),
    );
  }

  static SmartList smartListFromBytes(Uint8List bytes) {
    final p = ProtoSmartList.fromBuffer(bytes);
    return SmartList(
      id: _uuidFromBytes(p.id),
      name: p.name,
      iconCodePoint: p.iconCodePoint,
      colorValue: p.colorValue,
      filter: filterFromProto(p.filter),
    );
  }

  // ───── SyncIndex ─────

  static Uint8List syncIndexToBytes(SyncIndex index) {
    return Uint8List.fromList(
      ProtoSyncIndex(
        entities: index.entities.entries.map((e) => MapEntry(e.key, _toMs(e.value))),
        deletions: index.deletions.entries.map((e) => MapEntry(e.key, _toMs(e.value))),
      ).writeToBuffer(),
    );
  }

  static SyncIndex syncIndexFromBytes(Uint8List bytes) {
    final p = ProtoSyncIndex.fromBuffer(bytes);
    return SyncIndex(
      entities: p.entities.map((k, v) => MapEntry(k, _fromMs(v))),
      deletions: p.deletions.map((k, v) => MapEntry(k, _fromMs(v))),
    );
  }

  // ───── Per-type entity dispatch ─────

  /// Serialise any entity by its Dropbox type prefix ("tasks", "lists", …).
  static Uint8List entityToBytes(String type, dynamic entity) {
    return switch (type) {
      'tasks' => taskToBytes(entity as Task),
      'lists' => listToBytes(entity as TaskList),
      'folders' => folderToBytes(entity as Folder),
      'tags' => tagToBytes(entity as Tag),
      'smart_lists' => smartListToBytes(entity as SmartList),
      _ => throw ArgumentError('Unknown entity type: $type'),
    };
  }

  /// Deserialise raw bytes back to a domain object by type prefix.
  static dynamic entityFromBytes(String type, Uint8List bytes) {
    return switch (type) {
      'tasks' => taskFromBytes(bytes),
      'lists' => listFromBytes(bytes),
      'folders' => folderFromBytes(bytes),
      'tags' => tagFromBytes(bytes),
      'smart_lists' => smartListFromBytes(bytes),
      _ => throw ArgumentError('Unknown entity type: $type'),
    };
  }
}
