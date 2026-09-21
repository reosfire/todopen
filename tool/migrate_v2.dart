// One-shot migration from the v1 per-entity Dropbox layout to the v2
// base+segment-log format.
//
// Reads the old tree (/index.bin plus /tasks/*.bin and friends), rebuilds it
// as a v2 store, and writes the result under a fresh prefix. The old files
// are left untouched so this can be re-run and verified before anything is
// deleted.
//
// Usage:
//   dart run tool/migrate_v2.dart --token <dropbox-access-token>
//   dart run tool/migrate_v2.dart --token <tok> --commit
//   dart run tool/migrate_v2.dart --token <tok> --commit --delete-old
//
// Without --commit it is a dry run: it reports what it would write and
// verifies the result round-trips, but uploads nothing.
//
// Get a token from https://www.dropbox.com/developers/apps → your app →
// "Generated access token". It only needs to last for this one run.
//
// This is the last thing in the project that reads the v1 protobuf format.
// Once the migration has run and been verified, this file, lib/proto/,
// lib/builders.dart, proto/, and the `protobuf` dependency can all go.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:todopen/proto/models.pb.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/format/byte_io.dart';
import 'package:todopen/sync/engine/sync_engine.dart';
import 'package:todopen/sync/format/chunk.dart';
import 'package:todopen/sync/format/manifest.dart';
import 'package:todopen/sync/model/entities.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

const _entityFolders = ['tasks', 'lists', 'folders', 'tags', 'smart_lists'];

/// Shard count must match SyncPolicy's default, or the app will refetch
/// everything on first launch.
const _shardCount = 16;

Future<void> main(List<String> args) async {
  final token = _arg(args, '--token');
  if (token == null) {
    stderr.writeln('error: --token <dropbox-access-token> is required');
    stderr.writeln(
      'Create one at https://www.dropbox.com/developers/apps '
      '→ your app → Generated access token',
    );
    exit(2);
  }
  final commit = args.contains('--commit');
  final deleteOld = args.contains('--delete-old');

  final api = _Dropbox(token);

  stdout.writeln('== Todopen v1 → v2 migration ==');
  stdout.writeln(commit ? 'mode: COMMIT (will write)' : 'mode: dry run');
  stdout.writeln('');

  // ───── 1. Read the old index ─────

  final indexBytes = await api.download('/index.bin');
  if (indexBytes == null) {
    stderr.writeln(
      'No /index.bin found. Either this account has no v1 data, or the '
      'app folder is different from the one this token grants.',
    );
    exit(1);
  }
  final oldIndex = ProtoSyncIndex.fromBuffer(indexBytes);
  final liveKeys = oldIndex.entities.keys
      .where((k) => !oldIndex.deletions.containsKey(k))
      .toList();
  stdout.writeln(
    'v1 index: ${oldIndex.entities.length} entities, '
    '${oldIndex.deletions.length} tombstones, '
    '${liveKeys.length} live',
  );

  // ───── 2. Download every live entity ─────

  stdout.writeln('Downloading ${liveKeys.length} entity files...');
  final blobs = <String, Uint8List>{};
  var downloaded = 0;
  for (final batch in _chunked(liveKeys, 8)) {
    final results = await Future.wait(
      batch.map((k) async => MapEntry(k, await api.download('/$k.bin'))),
    );
    for (final r in results) {
      if (r.value != null) blobs[r.key] = r.value!;
    }
    downloaded += batch.length;
    stdout.write('\r  $downloaded/${liveKeys.length}');
  }
  stdout.writeln('\r  ${blobs.length}/${liveKeys.length} downloaded');

  // ───── 3. Rebuild as a replica ─────
  //
  // Each v1 entity's index timestamp becomes its HLC, so the relative order
  // of past edits is preserved rather than collapsing to "all at once".

  final replica = Replica();
  const migrationDevice = 1;
  var counter = 0;
  Hlc stampFor(String key) {
    final ts = oldIndex.entities[key];
    final ms = ts != null
        ? ts.toInt()
        : DateTime.now().millisecondsSinceEpoch;
    // The counter keeps stamps distinct when several entities share a
    // millisecond, which the v1 index made likely for batched writes.
    return Hlc(ms, (counter++) & 0xFFFF, migrationDevice);
  }

  final stats = <String, int>{};
  // Ordering is reconstructed per (list, lane) from the old linked list.
  final chains = <(Uuid128 listId, bool completed), List<ProtoTask>>{};

  for (final entry in blobs.entries) {
    final key = entry.key;
    final slash = key.indexOf('/');
    final type = key.substring(0, slash);
    final hlc = stampFor(key);

    try {
      switch (type) {
        case 'tasks':
          final p = ProtoTask.fromBuffer(entry.value);
          final id = Uuid128.fromBytes(Uint8List.fromList(p.id));
          final listId = Uuid128.fromBytes(Uint8List.fromList(p.listId));
          final e = ReplicatedEntity(
            kind: EntityKind.task,
            id: id,
            createdAt: hlc,
            lastCreate: hlc,
          );
          e.setField(TaskField.title, StringValue(p.title), hlc);
          e.setField(TaskField.notes, StringValue(p.notes), hlc);
          e.setField(
            TaskField.isCompleted,
            BoolValue(p.isCompleted),
            hlc,
          );
          e.setField(TaskField.listId, UuidValue(listId), hlc);
          e.setField(
            TaskField.createdAt,
            TimestampValue(p.createdAtMs.toInt()),
            hlc,
          );
          if (p.scheduledDateMs.toInt() != 0) {
            e.setField(
              TaskField.scheduledDate,
              TimestampValue(p.scheduledDateMs.toInt()),
              hlc,
            );
          }
          if (p.hasRecurrence()) {
            e.setField(
              TaskField.recurrence,
              BlobValue(_recurrenceBlob(p.recurrence)),
              hlc,
            );
          }
          if (p.tagIds.isNotEmpty) {
            e.setField(
              TaskField.tagIds,
              UuidSetValue({
                for (final t in p.tagIds)
                  Uuid128.fromBytes(Uint8List.fromList(t)),
              }),
              hlc,
            );
          }
          if (p.completedDatesMs.isNotEmpty) {
            e.setField(
              TaskField.completedDates,
              DateSetValue({
                for (final ms in p.completedDatesMs) _toDays(ms.toInt()),
              }),
              hlc,
            );
          }
          replica.entities[(EntityKind.task, id)] = e;
          (chains[(listId, p.isCompleted)] ??= []).add(p);

        case 'lists':
          final p = ProtoTaskList.fromBuffer(entry.value);
          final id = Uuid128.fromBytes(Uint8List.fromList(p.id));
          final e = ReplicatedEntity(
            kind: EntityKind.list,
            id: id,
            createdAt: hlc,
            lastCreate: hlc,
          );
          e.setField(ListField.name, StringValue(p.name), hlc);
          if (p.hasColor) {
            e.setField(
              ListField.color,
              IntValue(p.colorValue & 0xFFFFFFFF),
              hlc,
            );
          }
          if (p.folderId.isNotEmpty) {
            e.setField(
              ListField.folderId,
              UuidValue(Uuid128.fromBytes(Uint8List.fromList(p.folderId))),
              hlc,
            );
          }
          replica.entities[(EntityKind.list, id)] = e;

        case 'folders':
          final p = ProtoFolder.fromBuffer(entry.value);
          final id = Uuid128.fromBytes(Uint8List.fromList(p.id));
          final e = ReplicatedEntity(
            kind: EntityKind.folder,
            id: id,
            createdAt: hlc,
            lastCreate: hlc,
          );
          e.setField(FolderField.name, StringValue(p.name), hlc);
          replica.entities[(EntityKind.folder, id)] = e;

        case 'tags':
          final p = ProtoTag.fromBuffer(entry.value);
          final id = Uuid128.fromBytes(Uint8List.fromList(p.id));
          final e = ReplicatedEntity(
            kind: EntityKind.tag,
            id: id,
            createdAt: hlc,
            lastCreate: hlc,
          );
          e.setField(TagField.name, StringValue(p.name), hlc);
          e.setField(
            TagField.color,
            IntValue(p.colorValue & 0xFFFFFFFF),
            hlc,
          );
          replica.entities[(EntityKind.tag, id)] = e;

        case 'smart_lists':
          final p = ProtoSmartList.fromBuffer(entry.value);
          final id = Uuid128.fromBytes(Uint8List.fromList(p.id));
          final e = ReplicatedEntity(
            kind: EntityKind.smartList,
            id: id,
            createdAt: hlc,
            lastCreate: hlc,
          );
          e.setField(SmartListField.name, StringValue(p.name), hlc);
          e.setField(
            SmartListField.icon,
            IntValue(p.iconCodePoint),
            hlc,
          );
          e.setField(
            SmartListField.color,
            IntValue(p.colorValue & 0xFFFFFFFF),
            hlc,
          );
          e.setField(
            SmartListField.filter,
            BlobValue(_filterBlob(p.filter)),
            hlc,
          );
          replica.entities[(EntityKind.smartList, id)] = e;
      }
      stats[type] = (stats[type] ?? 0) + 1;
    } catch (e) {
      stderr.writeln('  ! skipping $key: $e');
    }
  }

  stdout.writeln('Converted: ${stats.entries.map((e) => '${e.value} ${e.key}').join(', ')}');

  // ───── 4. Rebuild ordering from the old linked list ─────

  var chainsRebuilt = 0;
  var brokenChains = 0;
  for (final entry in chains.entries) {
    final (listId, completed) = entry.key;
    final ordered = _walkChain(entry.value);
    if (ordered.broken) brokenChains++;
    replica.apply(
      SetOrderOp(
        Hlc(DateTime.now().millisecondsSinceEpoch, counter++ & 0xFFFF,
            migrationDevice),
        OrderScope(EntityKind.task, listId, completed ? 1 : 0),
        ordered.ids,
      ),
    );
    chainsRebuilt++;
  }
  stdout.writeln(
    'Rebuilt $chainsRebuilt task orderings'
    '${brokenChains > 0 ? ' ($brokenChains had broken links, '
        'repaired by creation date)' : ''}',
  );

  // Sidebar ordering came from an `order` int on lists and folders.
  final sidebar = <({Uuid128 id, int order})>[];
  for (final e in blobs.entries) {
    try {
      if (e.key.startsWith('lists/')) {
        final p = ProtoTaskList.fromBuffer(e.value);
        sidebar.add((
          id: Uuid128.fromBytes(Uint8List.fromList(p.id)),
          order: p.order,
        ));
      } else if (e.key.startsWith('folders/')) {
        final p = ProtoFolder.fromBuffer(e.value);
        sidebar.add((
          id: Uuid128.fromBytes(Uint8List.fromList(p.id)),
          order: p.order,
        ));
      }
    } catch (_) {
      // Already reported above.
    }
  }
  sidebar.sort((a, b) => a.order.compareTo(b.order));
  replica.apply(
    SetOrderOp(
      Hlc(DateTime.now().millisecondsSinceEpoch, counter++ & 0xFFFF,
          migrationDevice),
      OrderScope(EntityKind.list, _zeroUuid, 0),
      sidebar.map((s) => s.id).toList(),
    ),
  );
  stdout.writeln('Rebuilt sidebar ordering (${sidebar.length} items)');

  // ───── 5. Encode as v2 chunks ─────

  final byShard = <int, List<ReplicatedEntity>>{};
  for (final e in replica.entities.values) {
    (byShard[_shardOf(e)] ??= []).add(e);
  }
  final ordersByShard = <int, Map<OrderScope, OrderSnapshot>>{};
  for (final entry in replica.orderSnapshots.entries) {
    final scope = entry.key;
    final shard = scope.kind == EntityKind.task && scope.scopeId != _zeroUuid
        ? _shardOfUuid(scope.scopeId)
        : 0;
    (ordersByShard[shard] ??= {})[scope] = entry.value;
  }

  final chunkRefs = <ChunkRef>[];
  final payloads = <String, Uint8List>{};
  for (final shard in {...byShard.keys, ...ordersByShard.keys}) {
    final chunk = Chunk.build(
      byShard[shard] ?? const [],
      ordersByShard[shard] ?? const {},
    );
    final bytes = chunk.encode();
    final ref = ChunkRef(
      shard: shard,
      gen: 1,
      size: bytes.length,
      maxHlc: chunk.maxHlc,
      crc: _crc(bytes),
    );
    chunkRefs.add(ref);
    payloads[ref.path] = bytes;
  }

  final manifest = Manifest(
    baseGen: 1,
    nextSeq: 0,
    chunks: chunkRefs,
    segments: const [],
  );
  payloads['/manifest'] = manifest.encode();

  final totalBytes = payloads.values.fold(0, (a, b) => a + b.length);
  final oldBytes = blobs.values.fold(0, (a, b) => a + b.length);
  stdout.writeln('');
  stdout.writeln('v2 store: ${payloads.length} files, $totalBytes bytes');
  stdout.writeln(
    'v1 store: ${blobs.length + 1} files, $oldBytes bytes '
    '(+ ${indexBytes.length} index)',
  );
  stdout.writeln(
    'Cold start: ${payloads.length} requests vs ${blobs.length + 1} before',
  );

  // ───── 6. Verify the encoding round-trips ─────

  final check = Replica();
  for (final ref in chunkRefs) {
    check.loadChunk(Chunk.decode(payloads[ref.path]!));
  }
  final before = _fingerprint(replica);
  final after = _fingerprint(check);
  if (before != after) {
    stderr.writeln('');
    stderr.writeln('VERIFY FAILED: re-decoded store does not match.');
    stderr.writeln('Nothing was written. Please report this.');
    exit(1);
  }
  stdout.writeln(
    'Verified: ${check.liveCount} live entities round-trip exactly',
  );

  if (!commit) {
    stdout.writeln('');
    stdout.writeln('Dry run complete. Re-run with --commit to upload.');
    return;
  }

  // ───── 7. Upload ─────

  stdout.writeln('');
  stdout.writeln('Uploading...');
  // The manifest goes last: until it exists, the app sees no v2 store and
  // keeps working off its local cache, so a failure part-way leaves only
  // unreferenced chunks rather than a half-readable store.
  for (final entry in payloads.entries) {
    if (entry.key == '/manifest') continue;
    await api.upload(entry.key, entry.value);
    stdout.writeln('  ${entry.key} (${entry.value.length} B)');
  }
  await api.upload('/manifest', payloads['/manifest']!);
  stdout.writeln('  /manifest (${payloads['/manifest']!.length} B)');
  stdout.writeln('Upload complete.');

  if (deleteOld) {
    stdout.writeln('');
    stdout.writeln('Deleting v1 files...');
    for (final folder in _entityFolders) {
      await api.delete('/$folder');
      stdout.writeln('  /$folder');
    }
    await api.delete('/index.bin');
    stdout.writeln('  /index.bin');
  } else {
    stdout.writeln('');
    stdout.writeln(
      'v1 files kept. Once the app works, remove them with --delete-old,\n'
      'or delete /tasks /lists /folders /tags /smart_lists /index.bin by hand.',
    );
  }
}

// ───── Old linked list → dense array ─────

class _Chain {
  final List<Uuid128> ids;
  final bool broken;
  const _Chain(this.ids, this.broken);
}

/// Walk the v1 intrusive linked list into a dense array.
///
/// The old structure could hold cycles and orphans — the app had fallbacks
/// for both — so anything unreachable is appended by creation date rather
/// than dropped.
_Chain _walkChain(List<ProtoTask> tasks) {
  final byId = <Uuid128, ProtoTask>{
    for (final t in tasks) Uuid128.fromBytes(Uint8List.fromList(t.id)): t,
  };
  final hasPrev = <Uuid128>{};
  for (final t in tasks) {
    if (t.previousTaskId.isNotEmpty) {
      final p = Uuid128.fromBytes(Uint8List.fromList(t.previousTaskId));
      if (byId.containsKey(p)) {
        hasPrev.add(Uuid128.fromBytes(Uint8List.fromList(t.id)));
      }
    }
  }

  Uuid128? head;
  for (final t in tasks) {
    final id = Uuid128.fromBytes(Uint8List.fromList(t.id));
    if (!hasPrev.contains(id)) {
      head = id;
      break;
    }
  }

  final out = <Uuid128>[];
  final seen = <Uuid128>{};
  var cursor = head;
  while (cursor != null && seen.add(cursor)) {
    out.add(cursor);
    final t = byId[cursor];
    if (t == null || t.nextTaskId.isEmpty) break;
    final next = Uuid128.fromBytes(Uint8List.fromList(t.nextTaskId));
    cursor = byId.containsKey(next) ? next : null;
  }

  final orphans = byId.keys.where((id) => !seen.contains(id)).toList()
    ..sort((a, b) {
      final ta = byId[a]!.createdAtMs.toInt();
      final tb = byId[b]!.createdAtMs.toInt();
      return tb.compareTo(ta); // newest first, matching the old UI
    });
  out.addAll(orphans);
  return _Chain(out, orphans.isNotEmpty);
}

// ───── Proto → domain conversions ─────

/// Encode a v1 recurrence straight to the v2 blob.
///
/// Written against the proto rather than the domain model so this script
/// stays runnable with plain `dart run`: the model layer imports
/// package:flutter for its Color/IconData getters, which a console script
/// cannot load. The byte layout must match DomainMapper.recurrenceToBlob.
Uint8List _recurrenceBlob(ProtoRecurrenceRule p) {
  final w = ByteWriter(8);
  switch (p.whichRule()) {
    case ProtoRecurrenceRule_Rule.daily:
      w.u8(0);
    case ProtoRecurrenceRule_Rule.everyNDays:
      w.u8(1);
      w.varint(p.everyNDays.interval);
    case ProtoRecurrenceRule_Rule.weekly:
      w.u8(2);
      w.varint(p.weekly.weekdayBits);
    case ProtoRecurrenceRule_Rule.monthly:
      w.u8(3);
      w.varint(p.monthly.dayOfMonth);
    case ProtoRecurrenceRule_Rule.yearly:
      w.u8(4);
      w.varint(p.yearly.month);
      w.varint(p.yearly.dayOfMonth);
    case ProtoRecurrenceRule_Rule.notSet:
      w.u8(0);
  }
  return w.takeBytes();
}

/// Must match DomainMapper.filterToBlob.
Uint8List _filterBlob(ProtoSmartListFilter p) {
  final w = ByteWriter(16);
  switch (p.whichFilter()) {
    case ProtoSmartListFilter_Filter.today:
      w.u8(0);
    case ProtoSmartListFilter_Filter.tomorrow:
      w.u8(1);
    case ProtoSmartListFilter_Filter.upcoming:
      w.u8(2);
    case ProtoSmartListFilter_Filter.overdue:
      w.u8(3);
    case ProtoSmartListFilter_Filter.completed:
      w.u8(4);
    case ProtoSmartListFilter_Filter.all:
    case ProtoSmartListFilter_Filter.notSet:
      w.u8(5);
    case ProtoSmartListFilter_Filter.dateRange:
      w.u8(6);
      final hasFrom = p.dateRange.hasDateFrom;
      final hasTo = p.dateRange.hasDateTo;
      w.u8((hasFrom ? 1 : 0) | (hasTo ? 2 : 0));
      if (hasFrom) w.svarint(p.dateRange.dateFromMs.toInt());
      if (hasTo) w.svarint(p.dateRange.dateToMs.toInt());
    case ProtoSmartListFilter_Filter.tags:
      w.u8(7);
      w.varint(p.tags.tagIds.length);
      for (final t in p.tags.tagIds) {
        w.bytes(Uint8List.fromList(t));
      }
  }
  return w.takeBytes();
}

/// Days since epoch, matching DomainMapper.toDays.
int _toDays(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      86400000;
}

// ───── Helpers ─────

final _zeroUuid = Uuid128.fromBytes(Uint8List(16));

int _shardOf(ReplicatedEntity e) {
  if (e.kind != EntityKind.task) return 0;
  final listId = e.uuidField(TaskField.listId);
  return listId == null ? 0 : _shardOfUuid(listId);
}

/// Delegates to the engine's own hash, so the migration can never place an
/// entity in a different chunk than the app would.
int _shardOfUuid(Uuid128 id) => SyncEngine.shardOfUuid(id, _shardCount);

int _crc(Uint8List bytes) => _Crc.compute(bytes);

String _fingerprint(Replica r) {
  final keys = r.entities.keys.toList()
    ..sort((a, b) {
      final k = a.$1.wire.compareTo(b.$1.wire);
      return k != 0 ? k : a.$2.toString().compareTo(b.$2.toString());
    });
  final buf = StringBuffer();
  for (final k in keys) {
    final e = r.entities[k]!;
    buf.write('${k.$1.name}/${k.$2}|${e.deletedAt}|');
    final fields = e.fields.keys.toList()..sort();
    for (final f in fields) {
      buf.write('$f=${e.fields[f]!.value.runtimeType}:${e.fields[f]!.hlc};');
    }
    buf.write('\n');
  }
  final scopes = r.orders.keys.toList()
    ..sort((a, b) => a.toString().compareTo(b.toString()));
  for (final s in scopes) {
    buf.write('$s=${r.orders[s]!.value.join(",")}\n');
  }
  return buf.toString();
}

Iterable<List<T>> _chunked<T>(List<T> items, int size) sync* {
  for (var i = 0; i < items.length; i += size) {
    yield items.sublist(i, i + size > items.length ? items.length : i + size);
  }
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// Minimal Dropbox client; the app's own service depends on Flutter.
class _Dropbox {
  final String token;
  _Dropbox(this.token);

  Future<Uint8List?> download(String path) async {
    final r = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': path}),
      },
    );
    if (r.statusCode == 409) return null;
    if (r.statusCode != 200) {
      throw Exception('download $path failed ${r.statusCode}: ${r.body}');
    }
    return r.bodyBytes;
  }

  Future<void> upload(String path, Uint8List bytes) async {
    final r = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': path,
          'mode': 'overwrite',
          'autorename': false,
          'mute': true,
        }),
      },
      body: bytes,
    );
    if (r.statusCode != 200) {
      throw Exception('upload $path failed ${r.statusCode}: ${r.body}');
    }
  }

  Future<void> delete(String path) async {
    final r = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'path': path}),
    );
    if (r.statusCode != 200 && r.statusCode != 409) {
      throw Exception('delete $path failed ${r.statusCode}: ${r.body}');
    }
  }
}

class _Crc {
  static final _table = _build();
  static List<int> _build() {
    final t = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var j = 0; j < 8; j++) {
        c = (c & 1) != 0 ? (c >> 1) ^ 0x82F63B78 : c >> 1;
      }
      t[i] = c;
    }
    return t;
  }

  static int compute(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final b in data) {
      crc = _table[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
