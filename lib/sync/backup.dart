import 'package:flutter/foundation.dart' show listEquals;

import 'engine/replica.dart';
import 'format/byte_io.dart';
import 'format/op_codec.dart';
import 'model/entities.dart';
import 'model/hlc.dart';
import 'model/ops.dart';

/// One local full backup, as listed in sync settings.
///
/// The replica itself is stored separately and only decoded on restore, so
/// listing backups stays cheap however many there are.
class BackupInfo {
  /// Storage key; also the creation time in microseconds.
  final int id;
  final DateTime createdAt;

  /// Why it was taken, e.g. "Before sync" or "Before restore".
  final String reason;
  final int taskCount;
  final int listCount;
  final int bytes;

  /// CRC-32C of the encoded replica, so an unchanged replica is not backed
  /// up twice in a row.
  final int crc;

  /// Pinned backups are never pruned.
  final bool pinned;

  const BackupInfo({
    required this.id,
    required this.createdAt,
    required this.reason,
    required this.taskCount,
    required this.listCount,
    required this.bytes,
    required this.crc,
    required this.pinned,
  });

  Map<String, Object?> toJson() => {
    'at': createdAt.millisecondsSinceEpoch,
    'reason': reason,
    'tasks': taskCount,
    'lists': listCount,
    'bytes': bytes,
    'crc': crc,
    'pinned': pinned,
  };

  factory BackupInfo.fromJson(int id, Map<String, dynamic> json) => BackupInfo(
    id: id,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    reason: json['reason'] as String? ?? '',
    taskCount: json['tasks'] as int? ?? 0,
    listCount: json['lists'] as int? ?? 0,
    bytes: json['bytes'] as int? ?? 0,
    crc: json['crc'] as int? ?? 0,
    pinned: json['pinned'] as bool? ?? false,
  );

  BackupInfo copyWith({bool? pinned}) => BackupInfo(
    id: id,
    createdAt: createdAt,
    reason: reason,
    taskCount: taskCount,
    listCount: listCount,
    bytes: bytes,
    crc: crc,
    pinned: pinned ?? this.pinned,
  );
}

/// Ops that bring [current] back to the state held in [backup].
///
/// A restore is expressed as ordinary ops with fresh timestamps rather than
/// by swapping the replica out, because the replica is a CRDT: anything
/// older than what other devices already have would simply lose the merge
/// and the restore would be undone by the next pull. New ops win everywhere
/// and sync like any other edit.
///
/// With [replaceAll] false only what is missing comes back: entities live in
/// the backup but absent or deleted now are re-created with their backed-up
/// fields, and nothing else is touched. With [replaceAll] true the result
/// matches the backup exactly — edits made since are reverted and entities
/// created since are deleted.
List<Op> restoreOps(
  Replica current,
  Replica backup,
  HlcClock clock, {
  required bool replaceAll,
}) {
  final ops = <Op>[];

  for (final e in backup.entities.values) {
    final cur = current.get(e.kind, e.id);
    final curLive = cur != null && !cur.isDeleted;

    if (e.isDeleted) {
      if (replaceAll && curLive) {
        ops.add(DeleteEntityOp(clock.issue(), e.kind, e.id));
      }
      continue;
    }

    if (!curLive) {
      // Re-create with one shared stamp, as a fresh create would.
      final hlc = clock.issue();
      ops.add(CreateEntityOp(hlc, e.kind, e.id));
      for (final f in e.fields.entries) {
        ops.add(SetFieldOp(hlc, e.kind, e.id, f.key, f.value.value));
      }
      // A tombstoned entity keeps the fields it had when deleted; anything
      // the backup does not set would otherwise leak back in.
      ops.addAll(_clearExtraFields(cur, e, hlc));
    } else if (replaceAll) {
      Hlc? hlc;
      for (final f in e.fields.entries) {
        final now = cur.fields[f.key]?.value;
        if (now != null && sameValue(now, f.value.value)) continue;
        ops.add(
          SetFieldOp(hlc ??= clock.issue(), e.kind, e.id, f.key, f.value.value),
        );
      }
      ops.addAll(_clearExtraFields(cur, e, hlc ?? clock.issue()));
    }
  }

  if (replaceAll) {
    for (final cur in current.entities.values) {
      if (cur.isDeleted || backup.get(cur.kind, cur.id) != null) continue;
      ops.add(DeleteEntityOp(clock.issue(), cur.kind, cur.id));
    }
    for (final scope in backup.orderSnapshots.keys) {
      final order = backup.resolvedOrder(scope);
      if (listEquals(current.resolvedOrder(scope), order)) continue;
      ops.add(SetOrderOp(clock.issue(), scope, order));
    }
  }

  return ops;
}

/// Null out fields [cur] has that [target] does not.
Iterable<Op> _clearExtraFields(
  ReplicatedEntity? cur,
  ReplicatedEntity target,
  Hlc hlc,
) sync* {
  if (cur == null) return;
  for (final f in cur.fields.entries) {
    if (target.fields.containsKey(f.key) || f.value.value is NullValue) {
      continue;
    }
    yield SetFieldOp(hlc, target.kind, target.id, f.key, const NullValue());
  }
}

/// Values compare by their wire encoding; [OpValue] has no `==`.
bool sameValue(OpValue a, OpValue b) {
  final wa = ByteWriter(32);
  final wb = ByteWriter(32);
  OpCodec.writeValue(wa, a);
  OpCodec.writeValue(wb, b);
  return listEquals(wa.takeBytes(), wb.takeBytes());
}
