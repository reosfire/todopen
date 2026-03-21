import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/app_data.dart';
import '../models/folder.dart';
import '../models/recurrence.dart';
import '../models/smart_list.dart';
import '../models/sync_index.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/uuid128.dart';
import 'app_database.dart';

class StorageService {
  final AppDatabase _db = AppDatabase();

  // ───── App data ─────

  Future<AppData> load() async {
    try {
      // Load all entities in parallel.
      final results = await Future.wait([
        _db.select(_db.taskEntries).get(),
        _db.select(_db.taskTagEntries).get(),
        _db.select(_db.taskCompletedDateEntries).get(),
        _db.select(_db.listEntries).get(),
        _db.select(_db.folderEntries).get(),
        _db.select(_db.tagEntries).get(),
        _db.select(_db.smartListEntries).get(),
        _db.select(_db.smartListTagFilterEntries).get(),
        (_db.select(_db.metadataEntries)
              ..where((m) => m.key.equals('lastModified')))
            .getSingleOrNull(),
      ]);

      final taskRows = results[0] as List<TaskEntry>;
      final taskTagRows = results[1] as List<TaskTagEntry>;
      final completedDateRows =
          results[2] as List<TaskCompletedDateEntry>;
      final listRows = results[3] as List<ListEntry>;
      final folderRows = results[4] as List<FolderEntry>;
      final tagRows = results[5] as List<TagEntry>;
      final smartListRows = results[6] as List<SmartListEntry>;
      final smartListTagRows =
          results[7] as List<SmartListTagFilterEntry>;
      final metaRow = results[8] as MetadataEntry?;

      // Group junction rows by parent id.
      final tagIdsByTask = <String, Set<Uuid128>>{};
      for (final r in taskTagRows) {
        tagIdsByTask.putIfAbsent(r.taskId, () => {}).add(Uuid128.fromCompactString(r.tagId));
      }

      final completedDatesByTask = <String, Set<DateTime>>{};
      for (final r in completedDateRows) {
        completedDatesByTask.putIfAbsent(r.taskId, () => {}).add(r.date);
      }

      final tagIdsBySmartList = <String, Set<Uuid128>>{};
      for (final r in smartListTagRows) {
        tagIdsBySmartList
            .putIfAbsent(r.smartListId, () => {})
            .add(Uuid128.fromCompactString(r.tagId));
      }

      return AppData(
        tasks: taskRows
            .map(
              (r) => Task(
                id: Uuid128.fromCompactString(r.id),
                title: r.title,
                notes: r.notes,
                isCompleted: r.isCompleted,
                createdAt: r.createdAt,
                scheduledDate: r.scheduledDate,
                recurrence: _recurrenceFromRow(
                  r.recurrenceType,
                  r.recurrenceParam1,
                  r.recurrenceParam2,
                ),
                tagIds: tagIdsByTask[r.id] ?? {},
                listId: Uuid128.fromCompactString(r.listId),
                previousTaskId: r.previousTaskId != null ? Uuid128.fromCompactString(r.previousTaskId!) : null,
                nextTaskId: r.nextTaskId != null ? Uuid128.fromCompactString(r.nextTaskId!) : null,
                completedDates: completedDatesByTask[r.id] ?? {},
              ),
            )
            .toList(),
        lists: listRows
            .map(
              (r) => TaskList(
                id: Uuid128.fromCompactString(r.id),
                name: r.name,
                colorValue: r.colorValue,
                folderId: r.folderId != null ? Uuid128.fromCompactString(r.folderId!) : null,
                order: r.orderIndex,
              ),
            )
            .toList(),
        folders: folderRows
            .map(
              (r) => Folder(id: Uuid128.fromCompactString(r.id), name: r.name, order: r.orderIndex),
            )
            .toList(),
        tags: tagRows
            .map(
              (r) => Tag(id: Uuid128.fromCompactString(r.id), name: r.name, colorValue: r.colorValue),
            )
            .toList(),
        smartLists: smartListRows
            .map(
              (r) => SmartList(
                id: Uuid128.fromCompactString(r.id),
                name: r.name,
                iconCodePoint: r.iconCodePoint,
                colorValue: r.colorValue,
                filter: _filterFromRow(
                  r.filterType,
                  r.filterDateFrom,
                  r.filterDateTo,
                  tagIdsBySmartList[r.id] ?? {},
                ),
              ),
            )
            .toList(),
        lastModified:
            metaRow != null ? DateTime.parse(metaRow.value) : DateTime.now(),
      );
    } catch (_) {
      return AppData();
    }
  }

  Future<void> save(AppData data) async {
    data.lastModified = DateTime.now();

    await _db.transaction(() async {
      // Clear all entity and junction tables.
      await _db.delete(_db.taskEntries).go();
      await _db.delete(_db.taskTagEntries).go();
      await _db.delete(_db.taskCompletedDateEntries).go();
      await _db.delete(_db.listEntries).go();
      await _db.delete(_db.folderEntries).go();
      await _db.delete(_db.tagEntries).go();
      await _db.delete(_db.smartListEntries).go();
      await _db.delete(_db.smartListTagFilterEntries).go();

      await _db.batch((batch) {
        // Tasks.
        batch.insertAll(
          _db.taskEntries,
          data.tasks.map((t) {
            final (type, p1, p2) = _recurrenceToRow(t.recurrence);
            return TaskEntriesCompanion.insert(
              id: t.id.toCompactString(),
              title: t.title,
              notes: Value(t.notes),
              isCompleted: Value(t.isCompleted),
              createdAt: t.createdAt,
              scheduledDate: Value(t.scheduledDate),
              listId: t.listId.toCompactString(),
              previousTaskId: Value(t.previousTaskId?.toCompactString()),
              nextTaskId: Value(t.nextTaskId?.toCompactString()),
              recurrenceType: Value(type),
              recurrenceParam1: Value(p1),
              recurrenceParam2: Value(p2),
            );
          }),
        );

        // Task ↔ Tag junctions.
        batch.insertAll(
          _db.taskTagEntries,
          data.tasks.expand(
            (t) => t.tagIds.map(
              (tagId) => TaskTagEntriesCompanion.insert(
                taskId: t.id.toCompactString(),
                tagId: tagId.toCompactString(),
              ),
            ),
          ),
        );

        // Task completed dates.
        batch.insertAll(
          _db.taskCompletedDateEntries,
          data.tasks.expand(
            (t) => t.completedDates.map(
              (d) => TaskCompletedDateEntriesCompanion.insert(
                taskId: t.id.toCompactString(),
                date: d,
              ),
            ),
          ),
        );

        // Lists.
        batch.insertAll(
          _db.listEntries,
          data.lists.map(
            (l) => ListEntriesCompanion.insert(
              id: l.id.toCompactString(),
              name: l.name,
              colorValue: Value(l.colorValue),
              folderId: Value(l.folderId?.toCompactString()),
              orderIndex: Value(l.order),
            ),
          ),
        );

        // Folders.
        batch.insertAll(
          _db.folderEntries,
          data.folders.map(
            (f) => FolderEntriesCompanion.insert(
              id: f.id.toCompactString(),
              name: f.name,
              orderIndex: Value(f.order),
            ),
          ),
        );

        // Tags.
        batch.insertAll(
          _db.tagEntries,
          data.tags.map(
            (t) => TagEntriesCompanion.insert(
              id: t.id.toCompactString(),
              name: t.name,
              colorValue: t.colorValue,
            ),
          ),
        );

        // Smart lists.
        batch.insertAll(
          _db.smartListEntries,
          data.smartLists.map((s) {
            final (type, dateFrom, dateTo) = _filterToRow(s.filter);
            return SmartListEntriesCompanion.insert(
              id: s.id.toCompactString(),
              name: s.name,
              iconCodePoint: s.iconCodePoint,
              colorValue: s.colorValue,
              filterType: type,
              filterDateFrom: Value(dateFrom),
              filterDateTo: Value(dateTo),
            );
          }),
        );

        // Smart list ↔ Tag filter junctions.
        batch.insertAll(
          _db.smartListTagFilterEntries,
          data.smartLists
              .where((s) => s.filter is TagsFilter)
              .expand(
                (s) => (s.filter as TagsFilter).tagIds.map(
                  (tagId) => SmartListTagFilterEntriesCompanion.insert(
                    smartListId: s.id.toCompactString(),
                    tagId: tagId.toCompactString(),
                  ),
                ),
              ),
        );
      });

      await _db.into(_db.metadataEntries).insertOnConflictUpdate(
            MetadataEntriesCompanion.insert(
              key: 'lastModified',
              value: data.lastModified.toIso8601String(),
            ),
          );
    });
  }

  // ───── Sync index ─────

  Future<SyncIndex> loadSyncIndex() async {
    try {
      final entityRows = await _db.select(_db.syncEntityEntries).get();
      final deletionRows = await _db.select(_db.syncDeletionEntries).get();

      return SyncIndex(
        entities: {for (final r in entityRows) r.key: DateTime.parse(r.ts)},
        deletions: {for (final r in deletionRows) r.key: DateTime.parse(r.ts)},
      );
    } catch (_) {
      return SyncIndex();
    }
  }

  Future<void> saveSyncIndex(SyncIndex index) async {
    await _db.transaction(() async {
      await _db.delete(_db.syncEntityEntries).go();
      await _db.delete(_db.syncDeletionEntries).go();

      await _db.batch((batch) {
        batch.insertAll(
          _db.syncEntityEntries,
          index.entities.entries.map(
            (e) => SyncEntityEntriesCompanion.insert(
              key: e.key,
              ts: e.value.toIso8601String(),
            ),
          ),
        );
        batch.insertAll(
          _db.syncDeletionEntries,
          index.deletions.entries.map(
            (e) => SyncDeletionEntriesCompanion.insert(
              key: e.key,
              ts: e.value.toIso8601String(),
            ),
          ),
        );
      });
    });
  }

  // ───── UI state (local only) ─────

  static const _expandedFoldersKey = 'expanded_folder_ids';

  Future<Set<Uuid128>> loadExpandedFolderIds() async {
    final row = await (_db.select(_db.uiStateEntries)
          ..where((r) => r.key.equals(_expandedFoldersKey)))
        .getSingleOrNull();
    if (row == null) return {};
    final list = jsonDecode(row.value) as List;
    return list.cast<String>().map(Uuid128.fromCompactString).toSet();
  }

  Future<void> saveExpandedFolderIds(Set<Uuid128> folderIds) async {
    await _db.into(_db.uiStateEntries).insertOnConflictUpdate(
          UiStateEntriesCompanion.insert(
            key: _expandedFoldersKey,
            value: jsonEncode(folderIds.map((id) => id.toCompactString()).toList()),
          ),
        );
  }

  // ───── Recurrence helpers ─────

  static RecurrenceRule? _recurrenceFromRow(
    String? type,
    int? p1,
    int? p2,
  ) {
    return switch (type) {
      'daily' => const DailyRecurrence(),
      'every_n_days' => EveryNDaysRecurrence(p1!),
      'weekly' => WeeklyRecurrence(p1!),
      'monthly' => MonthlyRecurrence(p1!),
      'yearly' => YearlyRecurrence(p1!, p2!),
      _ => null,
    };
  }

  /// Returns (type, param1, param2) suitable for storage.
  static (String?, int?, int?) _recurrenceToRow(RecurrenceRule? r) {
    return switch (r) {
      null => (null, null, null),
      DailyRecurrence() => ('daily', null, null),
      EveryNDaysRecurrence(:final interval) => ('every_n_days', interval, null),
      WeeklyRecurrence(:final weekdayBits) => ('weekly', weekdayBits, null),
      MonthlyRecurrence(:final dayOfMonth) => ('monthly', dayOfMonth, null),
      YearlyRecurrence(:final month, :final dayOfMonth) =>
        ('yearly', month, dayOfMonth),
    };
  }

  // ───── SmartListFilter helpers ─────

  static SmartListFilter _filterFromRow(
    String type,
    DateTime? dateFrom,
    DateTime? dateTo,
    Set<Uuid128> tagIds,
  ) {
    return switch (type) {
      'today' => const TodayFilter(),
      'tomorrow' => const TomorrowFilter(),
      'upcoming' => const UpcomingFilter(),
      'overdue' => const OverdueFilter(),
      'completed' => const CompletedFilter(),
      'date_range' => DateRangeFilter(dateFrom: dateFrom, dateTo: dateTo),
      'tags' => TagsFilter(tagIds: tagIds),
      _ => const AllTasksFilter(),
    };
  }

  /// Returns (type, dateFrom, dateTo) suitable for storage.
  static (String, DateTime?, DateTime?) _filterToRow(SmartListFilter f) {
    return switch (f) {
      TodayFilter() => ('today', null, null),
      TomorrowFilter() => ('tomorrow', null, null),
      UpcomingFilter() => ('upcoming', null, null),
      OverdueFilter() => ('overdue', null, null),
      CompletedFilter() => ('completed', null, null),
      AllTasksFilter() => ('all', null, null),
      DateRangeFilter(:final dateFrom, :final dateTo) =>
        ('date_range', dateFrom, dateTo),
      TagsFilter() => ('tags', null, null),
    };
  }
}
