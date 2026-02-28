import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

// ───── Table definitions ─────

class TaskEntries extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  BlobColumn get data => blob()(); // protobuf binary

  @override
  Set<Column> get primaryKey => {id};
}

class ListEntries extends Table {
  @override
  String get tableName => 'lists';

  TextColumn get id => text()();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

class FolderEntries extends Table {
  @override
  String get tableName => 'folders';

  TextColumn get id => text()();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

class TagEntries extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

class SmartListEntries extends Table {
  @override
  String get tableName => 'smart_lists';

  TextColumn get id => text()();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row table for scalar metadata (e.g. `lastModified`).
class MetadataEntries extends Table {
  @override
  String get tableName => 'metadata';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

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
    ListEntries,
    FolderEntries,
    TagEntries,
    SmartListEntries,
    MetadataEntries,
    SyncEntityEntries,
    SyncDeletionEntries,
    UiStateEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'todo_app',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }
    return driftDatabase(name: 'todo_app');
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Recreate all tables on upgrade (binary format change).
          for (final table in allTables) {
            await m.drop(table);
          }
          await m.createAll();
        },
      );
}
