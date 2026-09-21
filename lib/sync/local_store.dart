import 'dart:convert';

// drift provides the query builder extensions (.where/.go) used below; the
// analyzer's "unnecessary import" hint is wrong because foundation only
// supplies the Uint8List/debugPrint symbols.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../services/app_database.dart';
import 'engine/replica.dart';
import 'format/chunk.dart';
import 'format/segment.dart';
import 'model/hlc.dart';
import 'model/ops.dart';

/// Local durability for the replica.
///
/// The whole replica is persisted as one encoded [Chunk] blob rather than
/// being shredded across relational tables. The old code rewrote every row
/// of every table on each keystroke-level save; here a save is a single
/// blob write, and a load is one read plus one decode.
///
/// Unsynced local ops are stored separately as an append-only segment log so
/// that edits made offline survive a crash or a force-quit before the next
/// successful push.
class LocalStore {
  final AppDatabase _db;

  LocalStore([AppDatabase? db]) : _db = db ?? AppDatabase();

  static const _keyReplica = 'replica_chunk';
  static const _keyPending = 'pending_ops';
  static const _keyDeviceId = 'device_id';
  static const _keySyncState = 'sync_state';

  // ───── Replica snapshot ─────

  Future<void> saveReplica(Replica replica) async {
    final chunk = Chunk.build(
      replica.entities.values.toList(),
      replica.orderSnapshots,
    );
    await _putBlob(_keyReplica, chunk.encode());
  }

  Future<Replica> loadReplica() async {
    final bytes = await _getBlob(_keyReplica);
    final replica = Replica();
    if (bytes == null) return replica;
    try {
      replica.loadChunk(Chunk.decode(bytes));
    } catch (e) {
      // A corrupt local cache is recoverable: the remote store is the
      // source of truth, so start empty and re-hydrate rather than
      // refusing to launch.
      debugPrint('Local replica corrupt, starting empty: $e');
      return Replica();
    }
    return replica;
  }

  // ───── Pending (unsynced) ops ─────

  /// Persist the ops that have not reached the server yet.
  ///
  /// Written on every local edit, so this is the hot path; a pending buffer
  /// is small (it is cleared on each successful push) and encodes as one
  /// segment.
  Future<void> savePending(List<Op> ops, int deviceId) async {
    if (ops.isEmpty) {
      await _deleteBlob(_keyPending);
      return;
    }
    await _putBlob(_keyPending, Segment.fromOps(ops, deviceId).encode());
  }

  Future<List<Op>> loadPending() async {
    final bytes = await _getBlob(_keyPending);
    if (bytes == null) return [];
    try {
      return Segment.decode(bytes).ops;
    } catch (e) {
      debugPrint('Pending ops corrupt, dropping: $e');
      return [];
    }
  }

  // ───── Sync bookkeeping ─────

  /// Stable per-installation id used as the HLC's tiebreak component.
  ///
  /// Two installations must never share one, or their timestamps could
  /// collide and make conflict resolution ambiguous.
  Future<int> deviceId() async {
    final existing = await _getString(_keyDeviceId);
    if (existing != null) {
      final parsed = int.tryParse(existing);
      if (parsed != null) return parsed;
    }
    // 31 bits keeps it positive and inside the HLC's 32-bit slot.
    final generated =
        DateTime.now().microsecondsSinceEpoch.abs() % 0x7FFFFFFF;
    await _putString(_keyDeviceId, generated.toString());
    return generated;
  }

  /// Which remote files this device has already merged, so a restart does
  /// not re-download and re-apply the entire log.
  Future<SyncState> loadSyncState() async {
    final raw = await _getString(_keySyncState);
    if (raw == null) return SyncState.empty();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SyncState(
        baseGen: json['baseGen'] as int? ?? -1,
        loadedChunks: Map<String, String>.from(
          (json['chunks'] as Map?) ?? const {},
        ).map((k, v) => MapEntry(int.parse(k), v)),
        appliedSegments: Set<String>.from(
          (json['segments'] as List?) ?? const [],
        ),
        lastHlc: json['lastHlc'] != null
            ? Hlc(
                json['lastHlc']['p'] as int,
                json['lastHlc']['c'] as int,
                json['lastHlc']['d'] as int,
              )
            : Hlc.zero,
      );
    } catch (e) {
      debugPrint('Sync state unreadable, resyncing from scratch: $e');
      return SyncState.empty();
    }
  }

  Future<void> saveSyncState(SyncState state) async {
    await _putString(
      _keySyncState,
      jsonEncode({
        'baseGen': state.baseGen,
        'chunks': state.loadedChunks.map((k, v) => MapEntry('$k', v)),
        'segments': state.appliedSegments.toList(),
        'lastHlc': {
          'p': state.lastHlc.physical,
          'c': state.lastHlc.counter,
          'd': state.lastHlc.deviceId,
        },
      }),
    );
  }

  /// Wipe everything this store owns. Used by the migration tool and by a
  /// "reset local cache" action.
  Future<void> clear() async {
    await _deleteBlob(_keyReplica);
    await _deleteBlob(_keyPending);
    await _db.delete(_db.uiStateEntries).go();
  }

  // ───── Blob helpers ─────
  //
  // Blobs ride in the existing key/value table as base64. Drift's web
  // backend is happiest with text columns, and the replica blob is read and
  // written whole, so the encoding overhead is not on any hot path.

  Future<void> _putBlob(String key, Uint8List bytes) =>
      _putString(key, base64Encode(bytes));

  Future<Uint8List?> _getBlob(String key) async {
    final s = await _getString(key);
    if (s == null) return null;
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _putString(String key, String value) async {
    await _db
        .into(_db.uiStateEntries)
        .insertOnConflictUpdate(
          UiStateEntriesCompanion.insert(key: key, value: value),
        );
  }

  Future<String?> _getString(String key) async {
    final row =
        await (_db.select(
          _db.uiStateEntries,
        )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _deleteBlob(String key) async {
    await (_db.delete(_db.uiStateEntries)..where((t) => t.key.equals(key)))
        .go();
  }
}

/// What this device has already merged from the remote store.
class SyncState {
  final int baseGen;

  /// shard → chunk identity, matching [SyncEngine]'s in-memory tracking.
  final Map<int, String> loadedChunks;

  /// Paths of segments already applied.
  final Set<String> appliedSegments;

  /// Highest HLC seen, so the clock resumes monotonically after a restart.
  final Hlc lastHlc;

  const SyncState({
    required this.baseGen,
    required this.loadedChunks,
    required this.appliedSegments,
    required this.lastHlc,
  });

  factory SyncState.empty() => const SyncState(
    baseGen: -1,
    loadedChunks: {},
    appliedSegments: {},
    lastHlc: Hlc.zero,
  );
}
