import 'dart:convert';
import '../models/app_data.dart';
import '../models/sync_index.dart';
import 'app_database.dart';
import 'proto_serializer.dart';

class StorageService {
  final AppDatabase _db = AppDatabase();

  // ───── App data ─────

  Future<AppData> load() async {
    try {
      final taskRows = await _db.select(_db.taskEntries).get();
      final listRows = await _db.select(_db.listEntries).get();
      final folderRows = await _db.select(_db.folderEntries).get();
      final tagRows = await _db.select(_db.tagEntries).get();
      final smartListRows = await _db.select(_db.smartListEntries).get();
      final metaRow = await (_db.select(
        _db.metadataEntries,
      )..where((m) => m.key.equals('lastModified'))).getSingleOrNull();

      return AppData(
        tasks: taskRows
            .map((r) => ProtoSerializer.taskFromBytes(r.data))
            .toList(),
        lists: listRows
            .map((r) => ProtoSerializer.listFromBytes(r.data))
            .toList(),
        folders: folderRows
            .map((r) => ProtoSerializer.folderFromBytes(r.data))
            .toList(),
        tags: tagRows.map((r) => ProtoSerializer.tagFromBytes(r.data)).toList(),
        smartLists: smartListRows
            .map((r) => ProtoSerializer.smartListFromBytes(r.data))
            .toList(),
        lastModified: metaRow != null
            ? DateTime.parse(metaRow.value)
            : DateTime.now(),
      );
    } catch (_) {
      // Ignore corrupt data, return defaults.
      return AppData();
    }
  }

  Future<void> save(AppData data) async {
    data.lastModified = DateTime.now();

    await _db.transaction(() async {
      // Clear all entity tables, then re-insert.
      await _db.delete(_db.taskEntries).go();
      await _db.delete(_db.listEntries).go();
      await _db.delete(_db.folderEntries).go();
      await _db.delete(_db.tagEntries).go();
      await _db.delete(_db.smartListEntries).go();

      await _db.batch((batch) {
        batch.insertAll(
          _db.taskEntries,
          data.tasks.map(
            (t) => TaskEntriesCompanion.insert(
              id: t.id,
              data: ProtoSerializer.taskToBytes(t),
            ),
          ),
        );
        batch.insertAll(
          _db.listEntries,
          data.lists.map(
            (l) => ListEntriesCompanion.insert(
              id: l.id,
              data: ProtoSerializer.listToBytes(l),
            ),
          ),
        );
        batch.insertAll(
          _db.folderEntries,
          data.folders.map(
            (f) => FolderEntriesCompanion.insert(
              id: f.id,
              data: ProtoSerializer.folderToBytes(f),
            ),
          ),
        );
        batch.insertAll(
          _db.tagEntries,
          data.tags.map(
            (t) => TagEntriesCompanion.insert(
              id: t.id,
              data: ProtoSerializer.tagToBytes(t),
            ),
          ),
        );
        batch.insertAll(
          _db.smartListEntries,
          data.smartLists.map(
            (s) => SmartListEntriesCompanion.insert(
              id: s.id,
              data: ProtoSerializer.smartListToBytes(s),
            ),
          ),
        );
      });

      await _db
          .into(_db.metadataEntries)
          .insertOnConflictUpdate(
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

  Future<Set<String>> loadExpandedFolderIds() async {
    final row = await (_db.select(
      _db.uiStateEntries,
    )..where((r) => r.key.equals(_expandedFoldersKey))).getSingleOrNull();
    if (row == null) return {};
    final list = jsonDecode(row.value) as List;
    return list.cast<String>().toSet();
  }

  Future<void> saveExpandedFolderIds(Set<String> folderIds) async {
    await _db
        .into(_db.uiStateEntries)
        .insertOnConflictUpdate(
          UiStateEntriesCompanion.insert(
            key: _expandedFoldersKey,
            value: jsonEncode(folderIds.toList()),
          ),
        );
  }
}
