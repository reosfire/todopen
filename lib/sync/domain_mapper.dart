import 'dart:typed_data';

import '../models/folder.dart';
import '../models/recurrence.dart';
import '../models/smart_list.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/uuid128.dart';
import 'engine/replica.dart';
import 'format/byte_io.dart';
import 'model/entities.dart';
import 'model/hlc.dart';
import 'model/ops.dart';

/// Converts between the replicated representation and the app's domain
/// models, and turns edits into the minimal set of ops.
///
/// Emitting only the fields that actually changed is what keeps a small edit
/// small: retyping one character in a title uploads a title op, not the
/// whole task.
class DomainMapper {
  // ───── Dates ─────

  /// Day-resolution dates are stored as days since epoch, which delta-encode
  /// to about a byte each for the clustered sets recurring tasks produce.
  static int toDays(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  static DateTime fromDays(int days) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      days * 86400000,
      isUtc: true,
    );
    return DateTime(utc.year, utc.month, utc.day);
  }

  // ───── Recurrence ─────

  /// Recurrence is a tiny tagged union, so it rides as an opaque blob rather
  /// than costing five field ids.
  static Uint8List recurrenceToBlob(RecurrenceRule r) {
    final w = ByteWriter(8);
    switch (r) {
      case DailyRecurrence():
        w.u8(0);
      case EveryNDaysRecurrence(:final interval):
        w.u8(1);
        w.varint(interval);
      case WeeklyRecurrence(:final weekdayBits):
        w.u8(2);
        w.varint(weekdayBits);
      case MonthlyRecurrence(:final dayOfMonth):
        w.u8(3);
        w.varint(dayOfMonth);
      case YearlyRecurrence(:final month, :final dayOfMonth):
        w.u8(4);
        w.varint(month);
        w.varint(dayOfMonth);
    }
    return w.takeBytes();
  }

  static RecurrenceRule? recurrenceFromBlob(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    final r = ByteReader(bytes);
    return switch (r.u8()) {
      0 => const DailyRecurrence(),
      1 => EveryNDaysRecurrence(r.varint()),
      2 => WeeklyRecurrence(r.varint()),
      3 => MonthlyRecurrence(r.varint()),
      4 => YearlyRecurrence(r.varint(), r.varint()),
      final t => throw CorruptDataException('unknown recurrence tag $t'),
    };
  }

  // ───── Smart list filters ─────

  static Uint8List filterToBlob(SmartListFilter f) {
    final w = ByteWriter(16);
    switch (f) {
      case TodayFilter():
        w.u8(0);
      case TomorrowFilter():
        w.u8(1);
      case UpcomingFilter():
        w.u8(2);
      case OverdueFilter():
        w.u8(3);
      case CompletedFilter():
        w.u8(4);
      case AllTasksFilter():
        w.u8(5);
      case DateRangeFilter(:final dateFrom, :final dateTo):
        w.u8(6);
        w.u8((dateFrom != null ? 1 : 0) | (dateTo != null ? 2 : 0));
        if (dateFrom != null) w.svarint(dateFrom.millisecondsSinceEpoch);
        if (dateTo != null) w.svarint(dateTo.millisecondsSinceEpoch);
      case TagsFilter(:final tagIds):
        w.u8(7);
        w.varint(tagIds.length);
        for (final id in tagIds) {
          w.bytes(id.toBytes());
        }
    }
    return w.takeBytes();
  }

  static SmartListFilter filterFromBlob(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return const AllTasksFilter();
    final r = ByteReader(bytes);
    switch (r.u8()) {
      case 0:
        return const TodayFilter();
      case 1:
        return const TomorrowFilter();
      case 2:
        return const UpcomingFilter();
      case 3:
        return const OverdueFilter();
      case 4:
        return const CompletedFilter();
      case 5:
        return const AllTasksFilter();
      case 6:
        final flags = r.u8();
        return DateRangeFilter(
          dateFrom: (flags & 1) != 0
              ? DateTime.fromMillisecondsSinceEpoch(r.svarint())
              : null,
          dateTo: (flags & 2) != 0
              ? DateTime.fromMillisecondsSinceEpoch(r.svarint())
              : null,
        );
      case 7:
        final n = r.varint();
        return TagsFilter(
          tagIds: {
            for (var i = 0; i < n; i++) Uuid128.fromBytes(r.bytesCopy(16)),
          },
        );
      default:
        return const AllTasksFilter();
    }
  }

  // ───── Replica → domain ─────

  static Task? taskFrom(ReplicatedEntity e) {
    if (e.isDeleted) return null;
    final listId = e.uuidField(TaskField.listId);
    if (listId == null) return null; // incomplete; not displayable yet
    return Task(
      id: e.id,
      title: e.stringField(TaskField.title),
      notes: e.stringField(TaskField.notes),
      isCompleted: e.boolField(TaskField.isCompleted),
      createdAt:
          e.dateField(TaskField.createdAt) ?? e.createdAt.wallTime,
      scheduledDate: e.dateField(TaskField.scheduledDate),
      recurrence: recurrenceFromBlob(e.blobField(TaskField.recurrence)),
      tagIds: Set<Uuid128>.from(e.uuidSetField(TaskField.tagIds)),
      listId: listId,
      completedDates: e
          .dateSetField(TaskField.completedDates)
          .map(fromDays)
          .toSet(),
    );
  }

  static TaskList? listFrom(ReplicatedEntity e) {
    if (e.isDeleted) return null;
    return TaskList(
      id: e.id,
      name: e.stringField(ListField.name),
      colorValue: e.intFieldOrNull(ListField.color),
      folderId: e.uuidField(ListField.folderId),
    );
  }

  static Folder? folderFrom(ReplicatedEntity e) {
    if (e.isDeleted) return null;
    return Folder(id: e.id, name: e.stringField(FolderField.name));
  }

  static Tag? tagFrom(ReplicatedEntity e) {
    if (e.isDeleted) return null;
    return Tag(
      id: e.id,
      name: e.stringField(TagField.name),
      colorValue: e.intField(TagField.color, 0xFF42A5F5),
    );
  }

  static SmartList? smartListFrom(ReplicatedEntity e) {
    if (e.isDeleted) return null;
    return SmartList(
      id: e.id,
      name: e.stringField(SmartListField.name),
      iconCodePoint: e.intField(SmartListField.icon, 0xe0c8),
      colorValue: e.intField(SmartListField.color, 0xFFAB47BC),
      filter: filterFromBlob(e.blobField(SmartListField.filter)),
    );
  }

  // ───── Domain → ops ─────

  /// Ops that fully describe a new task.
  static List<Op> createTask(Task t, HlcClock clock) => [
    CreateEntityOp(clock.issue(), EntityKind.task, t.id),
    ..._taskFieldOps(t, clock, null),
  ];

  /// Ops for the fields of [next] that differ from [previous].
  ///
  /// Passing null for [previous] emits every field.
  static List<Op> updateTask(Task next, Task? previous, HlcClock clock) =>
      _taskFieldOps(next, clock, previous);

  static List<Op> _taskFieldOps(Task t, HlcClock clock, Task? prev) {
    final ops = <Op>[];
    void set(int field, OpValue value, bool changed) {
      if (!changed) return;
      ops.add(
        SetFieldOp(clock.issue(), EntityKind.task, t.id, field, value),
      );
    }

    set(
      TaskField.title,
      StringValue(t.title),
      prev == null || prev.title != t.title,
    );
    set(
      TaskField.notes,
      StringValue(t.notes),
      prev == null || prev.notes != t.notes,
    );
    set(
      TaskField.isCompleted,
      BoolValue(t.isCompleted),
      prev == null || prev.isCompleted != t.isCompleted,
    );
    set(
      TaskField.listId,
      UuidValue(t.listId),
      prev == null || prev.listId != t.listId,
    );
    set(
      TaskField.createdAt,
      TimestampValue(t.createdAt.millisecondsSinceEpoch),
      prev == null,
    );
    set(
      TaskField.scheduledDate,
      t.scheduledDate == null
          ? const NullValue()
          : TimestampValue(t.scheduledDate!.millisecondsSinceEpoch),
      prev == null || prev.scheduledDate != t.scheduledDate,
    );
    set(
      TaskField.recurrence,
      t.recurrence == null
          ? const NullValue()
          : BlobValue(recurrenceToBlob(t.recurrence!)),
      prev == null || !_sameRecurrence(prev.recurrence, t.recurrence),
    );
    set(
      TaskField.tagIds,
      UuidSetValue(t.tagIds),
      prev == null || !_sameSet(prev.tagIds, t.tagIds),
    );
    set(
      TaskField.completedDates,
      DateSetValue(t.completedDates.map(toDays).toSet()),
      prev == null ||
          !_sameSet(
            prev.completedDates.map(toDays).toSet(),
            t.completedDates.map(toDays).toSet(),
          ),
    );
    return ops;
  }

  static bool _sameRecurrence(RecurrenceRule? a, RecurrenceRule? b) {
    if (a == null || b == null) return a == null && b == null;
    final ab = recurrenceToBlob(a);
    final bb = recurrenceToBlob(b);
    if (ab.length != bb.length) return false;
    for (var i = 0; i < ab.length; i++) {
      if (ab[i] != bb[i]) return false;
    }
    return true;
  }

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  static List<Op> createList(TaskList l, HlcClock clock) => [
    CreateEntityOp(clock.issue(), EntityKind.list, l.id),
    ..._listFieldOps(l, clock, null),
  ];

  static List<Op> updateList(TaskList next, TaskList? prev, HlcClock clock) =>
      _listFieldOps(next, clock, prev);

  static List<Op> _listFieldOps(TaskList l, HlcClock clock, TaskList? prev) {
    final ops = <Op>[];
    void set(int field, OpValue value, bool changed) {
      if (!changed) return;
      ops.add(
        SetFieldOp(clock.issue(), EntityKind.list, l.id, field, value),
      );
    }

    set(ListField.name, StringValue(l.name), prev == null || prev.name != l.name);
    set(
      ListField.color,
      l.colorValue == null ? const NullValue() : IntValue(l.colorValue!),
      prev == null || prev.colorValue != l.colorValue,
    );
    set(
      ListField.folderId,
      l.folderId == null ? const NullValue() : UuidValue(l.folderId!),
      prev == null || prev.folderId != l.folderId,
    );
    return ops;
  }

  static List<Op> createFolder(Folder f, HlcClock clock) => [
    CreateEntityOp(clock.issue(), EntityKind.folder, f.id),
    SetFieldOp(
      clock.issue(),
      EntityKind.folder,
      f.id,
      FolderField.name,
      StringValue(f.name),
    ),
  ];

  static List<Op> updateFolder(Folder f, Folder? prev, HlcClock clock) => [
    if (prev == null || prev.name != f.name)
      SetFieldOp(
        clock.issue(),
        EntityKind.folder,
        f.id,
        FolderField.name,
        StringValue(f.name),
      ),
  ];

  static List<Op> createTag(Tag t, HlcClock clock) => [
    CreateEntityOp(clock.issue(), EntityKind.tag, t.id),
    ..._tagFieldOps(t, clock, null),
  ];

  static List<Op> updateTag(Tag next, Tag? prev, HlcClock clock) =>
      _tagFieldOps(next, clock, prev);

  static List<Op> _tagFieldOps(Tag t, HlcClock clock, Tag? prev) => [
    if (prev == null || prev.name != t.name)
      SetFieldOp(
        clock.issue(),
        EntityKind.tag,
        t.id,
        TagField.name,
        StringValue(t.name),
      ),
    if (prev == null || prev.colorValue != t.colorValue)
      SetFieldOp(
        clock.issue(),
        EntityKind.tag,
        t.id,
        TagField.color,
        IntValue(t.colorValue),
      ),
  ];

  static List<Op> createSmartList(SmartList s, HlcClock clock) => [
    CreateEntityOp(clock.issue(), EntityKind.smartList, s.id),
    ..._smartListFieldOps(s, clock, null),
  ];

  static List<Op> updateSmartList(
    SmartList next,
    SmartList? prev,
    HlcClock clock,
  ) => _smartListFieldOps(next, clock, prev);

  static List<Op> _smartListFieldOps(
    SmartList s,
    HlcClock clock,
    SmartList? prev,
  ) {
    final ops = <Op>[];
    void set(int field, OpValue value, bool changed) {
      if (!changed) return;
      ops.add(
        SetFieldOp(clock.issue(), EntityKind.smartList, s.id, field, value),
      );
    }

    set(
      SmartListField.name,
      StringValue(s.name),
      prev == null || prev.name != s.name,
    );
    set(
      SmartListField.icon,
      IntValue(s.iconCodePoint),
      prev == null || prev.iconCodePoint != s.iconCodePoint,
    );
    set(
      SmartListField.color,
      IntValue(s.colorValue),
      prev == null || prev.colorValue != s.colorValue,
    );
    final nextBlob = filterToBlob(s.filter);
    final changedFilter =
        prev == null || !_sameBytes(filterToBlob(prev.filter), nextBlob);
    set(SmartListField.filter, BlobValue(nextBlob), changedFilter);
    return ops;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ───── Ordering scopes ─────

  /// Tasks are ordered per list, split into pending (lane 0) and completed
  /// (lane 1) so toggling a checkbox does not disturb the other lane.
  static OrderScope taskScope(Uuid128 listId, {required bool completed}) =>
      OrderScope(EntityKind.task, listId, completed ? 1 : 0);

  /// Lists and folders share one ordering space so they can be interleaved
  /// in the sidebar.
  static final sidebarScope = OrderScope(
    EntityKind.list,
    Uuid128.fromBytes(Uint8List(16)),
    0,
  );

  // ───── Whole-replica reads ─────

  static List<Task> allTasks(Replica r) => [
    for (final e in r.live(EntityKind.task))
      if (taskFrom(e) case final t?) t,
  ];

  static List<TaskList> allLists(Replica r) => [
    for (final e in r.live(EntityKind.list))
      if (listFrom(e) case final l?) l,
  ];

  static List<Folder> allFolders(Replica r) => [
    for (final e in r.live(EntityKind.folder))
      if (folderFrom(e) case final f?) f,
  ];

  static List<Tag> allTags(Replica r) => [
    for (final e in r.live(EntityKind.tag))
      if (tagFrom(e) case final t?) t,
  ];

  static List<SmartList> allSmartLists(Replica r) => [
    for (final e in r.live(EntityKind.smartList))
      if (smartListFrom(e) case final s?) s,
  ];
}
