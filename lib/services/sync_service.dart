import 'dart:async';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';
import 'dropbox_service.dart';
import 'binary_serializer.dart';
import 'storage_service.dart';

/// Orchestrates per-entity sync with Dropbox.
///
/// Dropbox layout:
/// ```
/// /index.bin              – SyncIndex
/// /tasks/{id}.bin         – individual Task
/// /lists/{id}.bin         – individual TaskList
/// /folders/{id}.bin       – individual Folder
/// /tags/{id}.bin          – individual Tag
/// /smart_lists/{id}.bin   – individual SmartList
/// ```
///
/// On every local change the affected entity is pushed to Dropbox in the
/// background.  Rapid changes are batched (500 ms debounce) so that only one
/// remote index round-trip is needed per batch.
class SyncService {
  final DropboxService _dropbox;
  final StorageService _storage;

  /// Tracks each entity's last-modified time as known locally.
  SyncIndex _localIndex = SyncIndex();

  // ── Batching / queueing ──

  /// Buffered changes waiting for the next flush.
  /// Value is the serialised protobuf bytes, or `null` for a deletion.
  final Map<String, Uint8List?> _pendingChanges = {};
  Timer? _pushTimer;

  /// Sequential operation chain so pushes never overlap.
  Future<void>? _pendingOp;

  /// Callback invoked when remote changes have been pulled into [AppData].
  /// The caller (AppState) sets this so it can call notifyListeners / save.
  void Function(AppData)? onRemoteDataChanged;

  /// Current longpoll cursor (Dropbox list_folder cursor).
  String? _longpollCursor;

  /// Whether the remote-polling loop is active.
  bool _polling = false;

  SyncService(this._dropbox, this._storage);

  bool get isSignedIn => _dropbox.isSignedIn;

  // ───── Initialisation ─────

  /// Load the persisted local index and make sure every entity in [data]
  /// has an entry (important on first run or after adding entities offline).
  Future<void> init(AppData data) async {
    _localIndex = await _storage.loadSyncIndex();
    _ensureAllEntitiesIndexed(data);
    await _storage.saveSyncIndex(_localIndex);
  }

  void _ensureAllEntitiesIndexed(AppData data) {
    final fallback = data.lastModified;
    for (final t in data.tasks) {
      _localIndex.entities.putIfAbsent('tasks/${t.id}', () => fallback);
    }
    for (final l in data.lists) {
      _localIndex.entities.putIfAbsent('lists/${l.id}', () => fallback);
    }
    for (final f in data.folders) {
      _localIndex.entities.putIfAbsent('folders/${f.id}', () => fallback);
    }
    for (final t in data.tags) {
      _localIndex.entities.putIfAbsent('tags/${t.id}', () => fallback);
    }
    for (final s in data.smartLists) {
      _localIndex.entities.putIfAbsent('smart_lists/${s.id}', () => fallback);
    }
  }

  // ───── Auto-push (called on every local change) ─────

  /// Schedule an entity upsert to Dropbox.
  void pushEntity(String type, String id, Uint8List bytes) {
    final key = '$type/$id';
    final now = DateTime.now();
    _localIndex.entities[key] = now;
    _localIndex.deletions.remove(key);
    _storage.saveSyncIndex(_localIndex); // fire-and-forget

    if (!_dropbox.isSignedIn) return;
    _pendingChanges[key] = bytes;
    _schedulePush();
  }

  /// Schedule an entity deletion on Dropbox.
  void pushDeletion(String type, String id) {
    final key = '$type/$id';
    final now = DateTime.now();
    _localIndex.entities.remove(key);
    _localIndex.deletions[key] = now;
    _storage.saveSyncIndex(_localIndex);

    if (!_dropbox.isSignedIn) return;
    _pendingChanges[key] = null; // null ⇒ delete
    _schedulePush();
  }

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 500), _flushPendingChanges);
  }

  void _flushPendingChanges() {
    if (_pendingChanges.isEmpty) return;

    final batch = Map<String, Uint8List?>.from(_pendingChanges);
    _pendingChanges.clear();

    _enqueue(() async {
      try {
        // 1. Upload / delete each entity file (in parallel).
        await _runParallel(
          batch.entries
              .map(
                (entry) => () async {
                  if (entry.value != null) {
                    await _dropbox.uploadBinaryFile(
                      '/${entry.key}.bin',
                      entry.value!,
                    );
                  } else {
                    try {
                      await _dropbox.deleteFile('/${entry.key}.bin');
                    } catch (_) {}
                  }
                },
              )
              .toList(),
          maxConcurrency: _maxUploadConcurrency,
        );

        // 2. Single remote-index round-trip for the whole batch.
        final remoteIndex = await _downloadRemoteIndex();
        for (final entry in batch.entries) {
          if (entry.value != null) {
            remoteIndex.entities[entry.key] = _localIndex.entities[entry.key]!;
            remoteIndex.deletions.remove(entry.key);
          } else {
            remoteIndex.entities.remove(entry.key);
            remoteIndex.deletions[entry.key] =
                _localIndex.deletions[entry.key]!;
          }
        }
        await _uploadRemoteIndex(remoteIndex);
      } catch (e) {
        debugPrint('Batch sync error: $e');
      }
    });
  }

  // ───── Queue helpers ─────

  void _enqueue(Future<void> Function() op) {
    _pendingOp = (_pendingOp ?? Future.value()).then(
      (_) => op().catchError(
        (Object e) => debugPrint('Enqueued sync op error: $e'),
      ),
    );
  }

  Future<void> _waitForPendingOps() async {
    _pushTimer?.cancel();
    _flushPendingChanges();
    if (_pendingOp != null) await _pendingOp;
  }

  // ───── Full sync ─────

  Future<AppData> fullSync(AppData localData) async {
    if (!_dropbox.isSignedIn) return localData;

    await _waitForPendingOps();

    final completer = Completer<AppData>();
    _enqueue(() async {
      try {
        completer.complete(await _performFullSync(localData));
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<AppData> _performFullSync(AppData localData) async {
    _clearZipCache();

    // 1. Download remote index.
    final indexBytes = await _dropbox.downloadBinaryFile('/index.bin');

    if (indexBytes == null) {
      // No index yet – completely fresh remote, upload everything.
      await _uploadAllEntities(localData);
      return localData;
    }

    final remoteIndex = BinarySerializer.syncIndexFromBytes(indexBytes);

    bool localChanged = false;

    // 2. Process remote deletions.
    for (final entry in remoteIndex.deletions.entries) {
      final localTime = _localIndex.entities[entry.key];
      if (localTime != null && entry.value.isAfter(localTime)) {
        _removeEntityFromData(localData, entry.key);
        _localIndex.entities.remove(entry.key);
        _localIndex.deletions[entry.key] = entry.value;
        localChanged = true;
      }
    }

    // 3. Download entities that are newer remotely (in parallel).
    final toDownload = <MapEntry<String, DateTime>>[];
    for (final entry in remoteIndex.entities.entries) {
      if (remoteIndex.deletions.containsKey(entry.key)) continue;
      final localTime = _localIndex.entities[entry.key];
      if (localTime == null || entry.value.isAfter(localTime)) {
        toDownload.add(entry);
      }
    }
    final downloadResults = await _smartDownload(
      toDownload.map((e) => e.key).toList(),
      totalRemoteEntities: remoteIndex.entities.length,
    );
    for (var i = 0; i < toDownload.length; i++) {
      final entry = toDownload[i];
      final bytes = downloadResults[i];
      if (bytes != null) {
        try {
          _applyEntityToData(localData, entry.key, bytes);
          _localIndex.entities[entry.key] = entry.value;
          localChanged = true;
        } catch (e) {
          debugPrint('Error parsing ${entry.key}: $e');
        }
      }
    }

    // 4. Upload entities that are newer locally (in parallel).
    final toUpload = <MapEntry<String, DateTime>>[];
    final toUploadBytes = <Uint8List>[];
    for (final entry in _localIndex.entities.entries) {
      if (_localIndex.deletions.containsKey(entry.key)) continue;
      final remoteDeletion = remoteIndex.deletions[entry.key];
      if (remoteDeletion != null && remoteDeletion.isAfter(entry.value)) {
        continue;
      }
      final remoteTime = remoteIndex.entities[entry.key];
      if (remoteTime == null || entry.value.isAfter(remoteTime)) {
        final bytes = _extractEntityFromData(localData, entry.key);
        if (bytes != null) {
          toUpload.add(entry);
          toUploadBytes.add(bytes);
        }
      }
    }
    await _runParallel(
      List.generate(
        toUpload.length,
        (i) => () async {
          try {
            await _dropbox.uploadBinaryFile(
              '/${toUpload[i].key}.bin',
              toUploadBytes[i],
            );
            remoteIndex.entities[toUpload[i].key] = toUpload[i].value;
            remoteIndex.deletions.remove(toUpload[i].key);
          } catch (e) {
            debugPrint('Error uploading ${toUpload[i].key}: $e');
          }
        },
      ),
      maxConcurrency: _maxUploadConcurrency,
    );

    // 5. Push local deletions to remote (in parallel).
    final toDelete = <MapEntry<String, DateTime>>[];
    for (final entry in _localIndex.deletions.entries) {
      final remoteTime = remoteIndex.entities[entry.key];
      if (remoteTime != null && entry.value.isAfter(remoteTime)) {
        toDelete.add(entry);
      }
    }
    await _runParallel(
      toDelete
          .map(
            (entry) => () async {
              try {
                await _dropbox.deleteFile('/${entry.key}.bin');
              } catch (_) {}
              remoteIndex.entities.remove(entry.key);
              remoteIndex.deletions[entry.key] = entry.value;
            },
          )
          .toList(),
      maxConcurrency: _maxUploadConcurrency,
    );

    // 6. Persist.
    await _uploadRemoteIndex(remoteIndex);
    await _storage.saveSyncIndex(_localIndex);

    if (localChanged) {
      localData.lastModified = DateTime.now();
    }
    return localData;
  }

  // ───── Force upload / download ─────

  Future<void> forceUploadAll(AppData data) async {
    if (!_dropbox.isSignedIn) return;
    await _waitForPendingOps();

    final completer = Completer<void>();
    _enqueue(() async {
      try {
        await _uploadAllEntities(data);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<AppData> forceDownloadAll() async {
    if (!_dropbox.isSignedIn) return AppData();
    await _waitForPendingOps();

    final completer = Completer<AppData>();
    _enqueue(() async {
      try {
        completer.complete(await _performForceDownload());
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<AppData> _performForceDownload() async {
    _clearZipCache();
    final remoteIndex = await _downloadRemoteIndex();
    final data = AppData();

    final keys = remoteIndex.entities.keys
        .where((k) => !remoteIndex.deletions.containsKey(k))
        .toList();
    final results = await _smartDownload(
      keys,
      totalRemoteEntities: remoteIndex.entities.length,
    );
    for (var i = 0; i < keys.length; i++) {
      final bytes = results[i];
      if (bytes != null) {
        try {
          _applyEntityToData(data, keys[i], bytes);
          _localIndex.entities[keys[i]] = remoteIndex.entities[keys[i]]!;
        } catch (e) {
          debugPrint('Error parsing ${keys[i]}: $e');
        }
      }
    }

    _localIndex.deletions = Map.from(remoteIndex.deletions);
    await _storage.saveSyncIndex(_localIndex);
    return data;
  }

  // ───── Upload all entities (used by force-upload & first sync) ─────

  Future<void> _uploadAllEntities(AppData data) async {
    final remoteIndex = SyncIndex();
    final now = DateTime.now();

    // Collect all entities to upload.
    final entries = <(String key, Uint8List bytes)>[];
    for (final t in data.tasks) {
      entries.add(('tasks/${t.id}', BinarySerializer.taskToBytes(t)));
    }
    for (final l in data.lists) {
      entries.add(('lists/${l.id}', BinarySerializer.listToBytes(l)));
    }
    for (final f in data.folders) {
      entries.add(('folders/${f.id}', BinarySerializer.folderToBytes(f)));
    }
    for (final t in data.tags) {
      entries.add(('tags/${t.id}', BinarySerializer.tagToBytes(t)));
    }
    for (final s in data.smartLists) {
      entries.add(('smart_lists/${s.id}', BinarySerializer.smartListToBytes(s)));
    }

    await _runParallel(
      entries
          .map(
            (e) => () async {
              final (key, bytes) = e;
              await _dropbox.uploadBinaryFile('/$key.bin', bytes);
              remoteIndex.entities[key] = now;
              _localIndex.entities[key] = now;
            },
          )
          .toList(),
      maxConcurrency: _maxUploadConcurrency,
    );

    _localIndex.deletions.clear();
    await _uploadRemoteIndex(remoteIndex);
    await _storage.saveSyncIndex(_localIndex);
  }

  // ───── Remote index helpers ─────

  Future<SyncIndex> _downloadRemoteIndex() async {
    final bytes = await _dropbox.downloadBinaryFile('/index.bin');
    if (bytes != null) {
      return BinarySerializer.syncIndexFromBytes(bytes);
    }
    return SyncIndex();
  }

  Future<void> _uploadRemoteIndex(SyncIndex index) async {
    await _dropbox.uploadBinaryFile(
      '/index.bin',
      BinarySerializer.syncIndexToBytes(index),
    );
  }

  // ───── Data manipulation helpers ─────

  void _applyEntityToData(AppData data, String key, Uint8List bytes) {
    final slash = key.indexOf('/');
    final type = key.substring(0, slash);
    switch (type) {
      case 'tasks':
        final entity = BinarySerializer.taskFromBytes(bytes);
        final idx = data.tasks.indexWhere((t) => t.id == entity.id);
        if (idx >= 0) {
          data.tasks[idx] = entity;
        } else {
          data.tasks.add(entity);
        }
      case 'lists':
        final entity = BinarySerializer.listFromBytes(bytes);
        final idx = data.lists.indexWhere((l) => l.id == entity.id);
        if (idx >= 0) {
          data.lists[idx] = entity;
        } else {
          data.lists.add(entity);
        }
      case 'folders':
        final entity = BinarySerializer.folderFromBytes(bytes);
        final idx = data.folders.indexWhere((f) => f.id == entity.id);
        if (idx >= 0) {
          data.folders[idx] = entity;
        } else {
          data.folders.add(entity);
        }
      case 'tags':
        final entity = BinarySerializer.tagFromBytes(bytes);
        final idx = data.tags.indexWhere((t) => t.id == entity.id);
        if (idx >= 0) {
          data.tags[idx] = entity;
        } else {
          data.tags.add(entity);
        }
      case 'smart_lists':
        final entity = BinarySerializer.smartListFromBytes(bytes);
        final idx = data.smartLists.indexWhere((s) => s.id == entity.id);
        if (idx >= 0) {
          data.smartLists[idx] = entity;
        } else {
          data.smartLists.add(entity);
        }
    }
  }

  void _removeEntityFromData(AppData data, String key) {
    final slash = key.indexOf('/');
    final type = key.substring(0, slash);
    final id = key.substring(slash + 1);
    switch (type) {
      case 'tasks':
        data.tasks.removeWhere((t) => t.id == id);
      case 'lists':
        data.lists.removeWhere((l) => l.id == id);
      case 'folders':
        data.folders.removeWhere((f) => f.id == id);
      case 'tags':
        data.tags.removeWhere((t) => t.id == id);
      case 'smart_lists':
        data.smartLists.removeWhere((s) => s.id == id);
    }
  }

  Uint8List? _extractEntityFromData(AppData data, String key) {
    final slash = key.indexOf('/');
    final type = key.substring(0, slash);
    final id = key.substring(slash + 1);
    try {
      switch (type) {
        case 'tasks':
          return BinarySerializer.taskToBytes(
            data.tasks.firstWhere((t) => t.id == id),
          );
        case 'lists':
          return BinarySerializer.listToBytes(
            data.lists.firstWhere((l) => l.id == id),
          );
        case 'folders':
          return BinarySerializer.folderToBytes(
            data.folders.firstWhere((f) => f.id == id),
          );
        case 'tags':
          return BinarySerializer.tagToBytes(
            data.tags.firstWhere((t) => t.id == id),
          );
        case 'smart_lists':
          return BinarySerializer.smartListToBytes(
            data.smartLists.firstWhere((s) => s.id == id),
          );
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  // ───── Pull remote changes (index-based) ─────

  /// Downloads only the entities that are newer on the server than locally.
  /// Returns `true` if any local data was changed.
  Future<bool> pullRemoteChanges(AppData localData) async {
    if (!_dropbox.isSignedIn) return false;
    _clearZipCache();

    try {
      final indexBytes = await _dropbox.downloadBinaryFile('/index.bin');
      if (indexBytes == null) return false;

      final remoteIndex = BinarySerializer.syncIndexFromBytes(indexBytes);

      bool changed = false;

      // Process remote deletions.
      for (final entry in remoteIndex.deletions.entries) {
        final localTime = _localIndex.entities[entry.key];
        if (localTime != null && entry.value.isAfter(localTime)) {
          _removeEntityFromData(localData, entry.key);
          _localIndex.entities.remove(entry.key);
          _localIndex.deletions[entry.key] = entry.value;
          changed = true;
        }
      }

      // Download entities that are newer remotely (in parallel).
      final toPull = <MapEntry<String, DateTime>>[];
      for (final entry in remoteIndex.entities.entries) {
        if (remoteIndex.deletions.containsKey(entry.key)) continue;
        final localTime = _localIndex.entities[entry.key];
        if (localTime == null || entry.value.isAfter(localTime)) {
          toPull.add(entry);
        }
      }
      final pullResults = await _smartDownload(
        toPull.map((e) => e.key).toList(),
        totalRemoteEntities: remoteIndex.entities.length,
      );
      for (var i = 0; i < toPull.length; i++) {
        final entry = toPull[i];
        final bytes = pullResults[i];
        if (bytes != null) {
          try {
            _applyEntityToData(localData, entry.key, bytes);
            _localIndex.entities[entry.key] = entry.value;
            changed = true;
          } catch (e) {
            debugPrint('Pull error for ${entry.key}: $e');
          }
        }
      }

      if (changed) {
        localData.lastModified = DateTime.now();
        await _storage.saveSyncIndex(_localIndex);
      }

      return changed;
    } catch (e) {
      debugPrint('pullRemoteChanges error: $e');
      return false;
    }
  }

  // ───── Dropbox longpoll-based remote polling ─────

  /// Start continuously polling Dropbox for remote changes.
  /// When changes are detected the remote index is checked and new entities
  /// are pulled.  This runs an infinite loop until [stopRemotePolling] is
  /// called.
  void startRemotePolling(AppData Function() currentData) {
    if (_polling) return;
    _polling = true;
    _pollLoop(currentData);
  }

  void stopRemotePolling() {
    _polling = false;
  }

  // ───── Parallel I/O helpers ─────

  static const _maxDownloadConcurrency = 10;
  static const _maxUploadConcurrency = 4;

  /// When the number of files to download exceeds this fraction of the
  /// total remote entity count, download the whole folder as a zip instead
  /// of issuing individual requests.
  static const _zipRatioThreshold = 0.30;

  /// When more than this many files need downloading, always prefer zip
  /// regardless of the ratio.
  static const _zipAbsoluteThreshold = 100;

  /// Cached zip contents — populated by [_downloadViaZip] so a single zip
  /// fetch can serve multiple callers during one sync cycle.
  Map<String, Uint8List>? _cachedZipContents;

  /// Download files using the best strategy:
  /// - If [totalRemoteEntities] is provided and the download count exceeds
  ///   [_zipRatioThreshold] of it, OR more than [_zipAbsoluteThreshold]
  ///   files are requested, the entire folder is fetched as a zip.
  /// - Otherwise individual parallel downloads are used.
  ///
  /// Returns a list of contents in the same order as [keys].
  /// Failed / missing files are represented as `null`.
  Future<List<Uint8List?>> _smartDownload(
    List<String> keys, {
    int totalRemoteEntities = 0,
  }) async {
    if (keys.isEmpty) return [];

    final useZip =
        keys.length >= _zipAbsoluteThreshold ||
        (totalRemoteEntities > 0 &&
            keys.length / totalRemoteEntities >= _zipRatioThreshold);

    if (useZip) {
      debugPrint(
        'Using zip download (${keys.length} files, '
        '$totalRemoteEntities total)',
      );
      final zipContents = await _getZipContents();
      if (zipContents != null) {
        return keys.map((key) => zipContents[key]).toList();
      }
      // Zip failed — fall through to parallel downloads.
      debugPrint('Zip download failed, falling back to parallel downloads');
    }

    return _downloadParallel(keys);
  }

  /// Download multiple files in parallel with bounded concurrency.
  Future<List<Uint8List?>> _downloadParallel(List<String> keys) async {
    if (keys.isEmpty) return [];
    final results = List<Uint8List?>.filled(keys.length, null);
    final pool = _Pool(_maxDownloadConcurrency);
    await Future.wait(
      List.generate(keys.length, (i) async {
        await pool.acquire();
        try {
          results[i] = await _dropbox.downloadBinaryFile('/${keys[i]}.bin');
        } catch (e) {
          debugPrint('Error downloading ${keys[i]}: $e');
        } finally {
          pool.release();
        }
      }),
    );
    return results;
  }

  /// Known entity subfolder names in Dropbox.
  static const _entityFolders = [
    'tasks',
    'lists',
    'folders',
    'tags',
    'smart_lists',
  ];

  /// Download all entity subfolders as zips (in parallel) and extract every
  /// `.bin` file into a `Map<entityKey, bytes>`.
  /// Uses [_cachedZipContents] so repeated calls in one sync cycle are free.
  Future<Map<String, Uint8List>?> _getZipContents() async {
    if (_cachedZipContents != null) return _cachedZipContents;

    try {
      final contents = <String, Uint8List>{};

      // Download each subfolder zip in parallel.
      final zipResults = await Future.wait(
        _entityFolders.map((folder) => _dropbox.downloadFolderZip('/$folder')),
      );

      for (var fi = 0; fi < _entityFolders.length; fi++) {
        final zipBytes = zipResults[fi];
        if (zipBytes == null) continue; // folder doesn't exist yet

        final archive = ZipDecoder().decodeBytes(zipBytes);
        for (final file in archive.files) {
          if (!file.isFile || !file.name.endsWith('.bin')) continue;

          // Zip paths look like:  <folderName>/abc.bin
          // Strip the leading folder component added by download_zip.
          var path = file.name;
          final firstSlash = path.indexOf('/');
          if (firstSlash >= 0) {
            path = path.substring(firstSlash + 1); // e.g. abc.bin
          }
          if (path.endsWith('.bin')) {
            final id = path.substring(0, path.length - 4); // e.g. abc
            final key = '${_entityFolders[fi]}/$id'; // e.g. tasks/abc
            contents[key] = Uint8List.fromList(file.content as List<int>);
          }
        }
      }

      _cachedZipContents = contents;
      return contents;
    } catch (e) {
      debugPrint('Zip extraction error: $e');
      return null;
    }
  }

  /// Clear the cached zip contents (call at the start of each sync cycle).
  void _clearZipCache() {
    _cachedZipContents = null;
  }

  /// Run multiple async operations with bounded concurrency.
  Future<void> _runParallel(
    List<Future<void> Function()> tasks, {
    required int maxConcurrency,
  }) async {
    if (tasks.isEmpty) return;
    final pool = _Pool(maxConcurrency);
    await Future.wait(
      tasks.map((task) async {
        await pool.acquire();
        try {
          await task();
        } finally {
          pool.release();
        }
      }),
    );
  }

  Future<void> _pollLoop(AppData Function() currentData) async {
    while (_polling && _dropbox.isSignedIn) {
      try {
        // Obtain a cursor if we don't have one yet.
        _longpollCursor ??= await _dropbox.getLatestCursor();
        if (_longpollCursor == null) {
          // Could not get cursor – wait and retry.
          await Future.delayed(const Duration(seconds: 30));
          continue;
        }

        // Block until Dropbox signals a change (or timeout).
        final hasChanges = await _dropbox.longpollForChanges(
          _longpollCursor!,
          timeout: 120,
        );

        if (!_polling) break;

        if (hasChanges == null) {
          // Error or cursor reset – get a fresh cursor.
          _longpollCursor = null;
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        if (hasChanges) {
          // Something changed – refresh the cursor and pull updates.
          _longpollCursor = await _dropbox.getLatestCursor();

          final data = currentData();
          final changed = await pullRemoteChanges(data);
          if (changed && onRemoteDataChanged != null) {
            onRemoteDataChanged!(data);
          }
        } else {
          // Timeout with no changes – refresh cursor and loop.
          _longpollCursor = await _dropbox.getLatestCursor();
        }
      } catch (e) {
        debugPrint('Poll loop error: $e');
        _longpollCursor = null;
        if (_polling) {
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }
  }
}

/// Tiny semaphore for bounding concurrency.
class _Pool {
  _Pool(this._maxConcurrency);
  final int _maxConcurrency;
  int _running = 0;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() async {
    if (_running < _maxConcurrency) {
      _running++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _running--;
    }
  }
}
