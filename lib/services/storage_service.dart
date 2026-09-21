import 'dart:convert';

// drift supplies the query-builder extensions used below.
// ignore: unused_import
import 'package:drift/drift.dart';

import '../utils/uuid128.dart';
import 'app_database.dart';

/// Local-only UI preferences: which folders are expanded, what was last
/// selected.
///
/// Task data lives in the sync layer ([LocalStore] + the replica), not here.
/// This state is deliberately *not* synced — which list you had open on your
/// phone should not move the selection on your desktop.
class StorageService {
  final AppDatabase _db = AppDatabase();

  static const _expandedFoldersKey = 'expanded_folder_ids';
  static const _selectedListKey = 'selected_list_id';
  static const _selectedSmartListKey = 'selected_smart_list_id';

  Future<Set<Uuid128>> loadExpandedFolderIds() async {
    final row = await (_db.select(
      _db.uiStateEntries,
    )..where((r) => r.key.equals(_expandedFoldersKey))).getSingleOrNull();
    if (row == null) return {};
    try {
      final list = jsonDecode(row.value) as List;
      return list.cast<String>().map(Uuid128.fromCompactString).toSet();
    } catch (_) {
      // Malformed preference: forget it rather than fail to open a screen.
      return {};
    }
  }

  Future<void> saveExpandedFolderIds(Set<Uuid128> folderIds) async {
    await _put(
      _expandedFoldersKey,
      jsonEncode(folderIds.map((id) => id.toCompactString()).toList()),
    );
  }

  Future<Uuid128?> loadSelectedListId() => _loadId(_selectedListKey);

  Future<void> saveSelectedListId(Uuid128? id) => _saveId(_selectedListKey, id);

  Future<Uuid128?> loadSelectedSmartListId() => _loadId(_selectedSmartListKey);

  Future<void> saveSelectedSmartListId(Uuid128? id) =>
      _saveId(_selectedSmartListKey, id);

  /// Panel geometry the user dragged into place — side panel width, the
  /// heights of its sections. Stored under free-form keys so a new draggable
  /// divider needs no schema change.
  Future<double?> loadDouble(String key) async {
    final row = await (_db.select(
      _db.uiStateEntries,
    )..where((r) => r.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    return double.tryParse(row.value);
  }

  Future<void> saveDouble(String key, double value) =>
      _put(key, value.toString());

  // ───── Helpers ─────

  Future<Uuid128?> _loadId(String key) async {
    final row = await (_db.select(
      _db.uiStateEntries,
    )..where((r) => r.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      return Uuid128.fromCompactString(row.value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveId(String key, Uuid128? id) async {
    if (id == null) {
      await (_db.delete(
        _db.uiStateEntries,
      )..where((r) => r.key.equals(key))).go();
      return;
    }
    await _put(key, id.toCompactString());
  }

  Future<void> _put(String key, String value) async {
    await _db
        .into(_db.uiStateEntries)
        .insertOnConflictUpdate(
          UiStateEntriesCompanion.insert(key: key, value: value),
        );
  }
}
