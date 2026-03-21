import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ───── Tasks ─────

class TaskEntries extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  TextColumn get listId => text()();
  TextColumn get previousTaskId => text().nullable()();
  TextColumn get nextTaskId => text().nullable()();

  // Recurrence: type string ('daily' | 'every_n_days' | 'weekly' | 'monthly' |
  // 'yearly') + up to two integer params.
  // daily        — no params
  // every_n_days — param1 = interval
  // weekly       — param1 = weekdayBits
  // monthly      — param1 = dayOfMonth
  // yearly       — param1 = month, param2 = dayOfMonth
  TextColumn get recurrenceType => text().nullable()();
  IntColumn get recurrenceParam1 => integer().nullable()();
  IntColumn get recurrenceParam2 => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many: task ↔ tag.
class TaskTagEntries extends Table {
  @override
  String get tableName => 'task_tags';

  TextColumn get taskId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

/// Per-task completion dates (for recurring tasks).
class TaskCompletedDateEntries extends Table {
  @override
  String get tableName => 'task_completed_dates';

  TextColumn get taskId => text()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {taskId, date};
}

// ───── Lists ─────

class ListEntries extends Table {
  @override
  String get tableName => 'lists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get folderId => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ───── Folders ─────

class FolderEntries extends Table {
  @override
  String get tableName => 'folders';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ───── Tags ─────

class TagEntries extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ───── SmartLists ─────

class SmartListEntries extends Table {
  @override
  String get tableName => 'smart_lists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();

  // filter_type: 'today' | 'tomorrow' | 'upcoming' | 'overdue' | 'completed'
  //              | 'all' | 'date_range' | 'tags'
  TextColumn get filterType => text()();
  // DateRangeFilter boundaries (nullable for other filter types).
  DateTimeColumn get filterDateFrom => dateTime().nullable()();
  DateTimeColumn get filterDateTo => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tag IDs in a smart list's TagsFilter.
class SmartListTagFilterEntries extends Table {
  @override
  String get tableName => 'smart_list_tag_filters';

  TextColumn get smartListId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {smartListId, tagId};
}

// ───── Metadata (scalar key/value, e.g. lastModified) ─────

class MetadataEntries extends Table {
  @override
  String get tableName => 'metadata';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ───── Sync index ─────

class SyncEntityEntries extends Table {
  @override
  String get tableName => 'sync_entities';

  TextColumn get key => text()();
  TextColumn get ts => text()(); // ISO-8601 DateTime

  @override
  Set<Column> get primaryKey => {key};
}

class SyncDeletionEntries extends Table {
  @override
  String get tableName => 'sync_deletions';

  TextColumn get key => text()();
  TextColumn get ts => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ───── UI state (local only) ─────

class UiStateEntries extends Table {
  @override
  String get tableName => 'ui_state';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ───── Database ─────

@DriftDatabase(
  tables: [
    TaskEntries,
    TaskTagEntries,
    TaskCompletedDateEntries,
    ListEntries,
    FolderEntries,
    TagEntries,
    SmartListEntries,
    SmartListTagFilterEntries,
    MetadataEntries,
    SyncEntityEntries,
    SyncDeletionEntries,
    UiStateEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'todopen_app',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;
}
