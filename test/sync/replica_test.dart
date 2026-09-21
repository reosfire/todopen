import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/format/chunk.dart';
import 'package:todopen/sync/model/entities.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

/// Deterministic distinct uuid per [n].
///
/// Spreads n over four bytes: a single-byte derivation wraps at 256 and
/// silently makes uid(0) == uid(256), which would let a test "lose" entities
/// that the engine had actually deduplicated correctly.
Uuid128 uid(int n) => Uuid128.fromBytes(
  Uint8List.fromList([
    n & 0xFF,
    (n >> 8) & 0xFF,
    (n >> 16) & 0xFF,
    (n >> 24) & 0xFF,
    ...List.generate(12, (i) => (n * 31 + i * 7) & 0xFF),
  ]),
);

/// Snapshot a replica into a comparable structure, so two replicas can be
/// checked for exact equality of observable state.
Map<String, Object?> snapshot(Replica r) {
  final out = <String, Object?>{};
  final keys = r.entities.keys.toList()
    ..sort((a, b) {
      final k = a.$1.wire.compareTo(b.$1.wire);
      if (k != 0) return k;
      return a.$2.toString().compareTo(b.$2.toString());
    });
  for (final k in keys) {
    final e = r.entities[k]!;
    final fields = <String, Object?>{};
    final fieldKeys = e.fields.keys.toList()..sort();
    for (final f in fieldKeys) {
      final s = e.fields[f]!;
      fields['$f'] = '${_valueKey(s.value)}@${s.hlc}';
    }
    out['${k.$1.name}/${k.$2}'] = {
      'created': e.createdAt.toString(),
      'deleted': e.deletedAt?.toString(),
      'fields': fields,
    };
  }
  final orderKeys = r.orders.keys.toList()
    ..sort((a, b) => a.toString().compareTo(b.toString()));
  for (final k in orderKeys) {
    out['order:$k'] = r.orders[k]!.value.map((e) => e.toString()).toList();
  }
  return out;
}

String _valueKey(OpValue v) => switch (v) {
  NullValue() => 'null',
  BoolValue(:final value) => 'b$value',
  IntValue(:final value) => 'i$value',
  StringValue(:final value) => 's$value',
  TimestampValue(:final millis) => 't$millis',
  UuidValue(:final value) => 'u$value',
  UuidSetValue(:final values) =>
    'us${(values.map((e) => e.toString()).toList()..sort()).join(",")}',
  DateSetValue(:final daysSinceEpoch) =>
    'ds${(daysSinceEpoch.toList()..sort()).join(",")}',
  BlobValue(:final bytes) => 'bl${bytes.join(",")}',
};

void main() {
  group('field-level LWW', () {
    test('later write wins', () {
      final r = Replica();
      r.apply(SetFieldOp(const Hlc(10, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('old')));
      r.apply(SetFieldOp(const Hlc(20, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('new')));
      expect(
        r.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        'new',
      );
    });

    test('earlier write arriving late does not clobber', () {
      final r = Replica();
      r.apply(SetFieldOp(const Hlc(20, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('new')));
      r.apply(SetFieldOp(const Hlc(10, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('old')));
      expect(
        r.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        'new',
      );
    });

    test('concurrent edits to DIFFERENT fields both survive', () {
      // This is the case the old per-entity-file sync got wrong: phone edits
      // the title, desktop ticks the checkbox, one overwrote the other.
      final phone = Replica();
      final desktop = Replica();

      final titleEdit = SetFieldOp(const Hlc(100, 0, 1), EntityKind.task,
          uid(1), TaskField.title, const StringValue('Buy oat milk'));
      final doneEdit = SetFieldOp(const Hlc(101, 0, 2), EntityKind.task,
          uid(1), TaskField.isCompleted, const BoolValue(true));

      phone.apply(titleEdit);
      phone.apply(doneEdit);
      desktop.apply(doneEdit);
      desktop.apply(titleEdit);

      for (final r in [phone, desktop]) {
        final e = r.get(EntityKind.task, uid(1))!;
        expect(e.stringField(TaskField.title), 'Buy oat milk');
        expect(e.boolField(TaskField.isCompleted), isTrue);
      }
      expect(snapshot(phone), snapshot(desktop));
    });

    test('ties broken deterministically by device id', () {
      final a = Replica();
      final b = Replica();
      final x = SetFieldOp(const Hlc(50, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('from device 1'));
      final y = SetFieldOp(const Hlc(50, 0, 2), EntityKind.task, uid(1),
          TaskField.title, const StringValue('from device 2'));
      a.apply(x);
      a.apply(y);
      b.apply(y);
      b.apply(x);
      expect(
        a.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        b.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
      );
      // Higher device id wins the tie.
      expect(
        a.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        'from device 2',
      );
    });
  });

  group('create / delete', () {
    test('delete after create tombstones', () {
      final r = Replica();
      r.apply(CreateEntityOp(const Hlc(10, 0, 1), EntityKind.task, uid(1)));
      r.apply(DeleteEntityOp(const Hlc(20, 0, 1), EntityKind.task, uid(1)));
      expect(r.get(EntityKind.task, uid(1))!.isDeleted, isTrue);
      expect(r.live(EntityKind.task), isEmpty);
    });

    test('delete arriving before create still tombstones (order-free)', () {
      final r = Replica();
      r.apply(DeleteEntityOp(const Hlc(20, 0, 1), EntityKind.task, uid(1)));
      r.apply(CreateEntityOp(const Hlc(10, 0, 1), EntityKind.task, uid(1)));
      expect(r.get(EntityKind.task, uid(1))!.isDeleted, isTrue);
    });

    test('field write on a deleted entity does not resurrect it', () {
      final r = Replica();
      r.apply(DeleteEntityOp(const Hlc(20, 0, 1), EntityKind.task, uid(1)));
      r.apply(SetFieldOp(const Hlc(30, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('zombie')));
      expect(r.get(EntityKind.task, uid(1))!.isDeleted, isTrue,
          reason: 'editing a task deleted elsewhere must not undelete it');
    });

    test('explicit later create undeletes', () {
      final r = Replica();
      r.apply(DeleteEntityOp(const Hlc(20, 0, 1), EntityKind.task, uid(1)));
      r.apply(CreateEntityOp(const Hlc(30, 0, 1), EntityKind.task, uid(1)));
      expect(r.get(EntityKind.task, uid(1))!.isDeleted, isFalse);
    });
  });

  group('ordering', () {
    final scope = OrderScope(EntityKind.task, uid(99), 0);

    test('dense array defines order', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope,
          [uid(3), uid(1), uid(2)]));
      expect(
        r.orderedIds(scope, {uid(1), uid(2), uid(3)}),
        [uid(3), uid(1), uid(2)],
      );
    });

    test('deleted ids drop out, unknown ids append deterministically', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope,
          [uid(3), uid(1), uid(2)]));
      // uid(2) gone, uid(7) new and not in the array.
      final got = r.orderedIds(scope, {uid(1), uid(3), uid(7)});
      expect(got.sublist(0, 2), [uid(3), uid(1)]);
      expect(got.last, uid(7));
    });

    test('later full reorder wins over earlier', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(20, 0, 1), scope, [uid(1), uid(2)]));
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope, [uid(2), uid(1)]));
      expect(r.orderedIds(scope, {uid(1), uid(2)}), [uid(1), uid(2)]);
    });

    test('move to head', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope,
          [uid(1), uid(2), uid(3)]));
      r.apply(MoveWithinOrderOp(const Hlc(20, 0, 1), scope, uid(3), null));
      expect(r.orderedIds(scope, {uid(1), uid(2), uid(3)}),
          [uid(3), uid(1), uid(2)]);
    });

    test('move after an anchor', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope,
          [uid(1), uid(2), uid(3)]));
      r.apply(MoveWithinOrderOp(const Hlc(20, 0, 1), scope, uid(1), uid(2)));
      expect(r.orderedIds(scope, {uid(1), uid(2), uid(3)}),
          [uid(2), uid(1), uid(3)]);
    });

    test('move with a missing anchor appends rather than losing the item', () {
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope, [uid(1), uid(2)]));
      r.apply(MoveWithinOrderOp(const Hlc(20, 0, 1), scope, uid(1), uid(404)));
      final got = r.orderedIds(scope, {uid(1), uid(2)});
      expect(got.toSet(), {uid(1), uid(2)}, reason: 'nothing may be lost');
    });

    test('two devices moving different items both keep their intent', () {
      final a = Replica();
      final b = Replica();
      final setup =
          SetOrderOp(const Hlc(10, 0, 0), scope, [uid(1), uid(2), uid(3)]);
      final moveA =
          MoveWithinOrderOp(const Hlc(20, 0, 1), scope, uid(3), null);
      final moveB =
          MoveWithinOrderOp(const Hlc(21, 0, 2), scope, uid(1), uid(2));

      // Apply in HLC order on both, arriving via different paths.
      a.apply(setup);
      a.apply(moveA);
      a.apply(moveB);
      b.apply(setup);
      b.apply(moveA);
      b.apply(moveB);

      expect(a.orderedIds(scope, {uid(1), uid(2), uid(3)}),
          b.orderedIds(scope, {uid(1), uid(2), uid(3)}));
      expect(a.orderedIds(scope, {uid(1), uid(2), uid(3)}).toSet(),
          {uid(1), uid(2), uid(3)});
    });

    test('lanes are independent (pending vs completed)', () {
      final r = Replica();
      final pending = OrderScope(EntityKind.task, uid(99), 0);
      final done = OrderScope(EntityKind.task, uid(99), 1);
      r.apply(SetOrderOp(const Hlc(10, 0, 1), pending, [uid(1), uid(2)]));
      r.apply(SetOrderOp(const Hlc(10, 0, 1), done, [uid(3)]));
      expect(r.orderedIds(pending, {uid(1), uid(2)}), [uid(1), uid(2)]);
      expect(r.orderedIds(done, {uid(3)}), [uid(3)]);
    });
  });

  group('convergence', () {
    /// The core guarantee: any permutation of the same op set yields
    /// identical state.
    test('random op sets converge under every permutation', () {
      final rnd = Random(12345);

      for (var trial = 0; trial < 40; trial++) {
        final ops = <Op>[];
        var tick = 1000;
        for (var i = 0; i < 60; i++) {
          tick += rnd.nextInt(3); // allow ties, forcing device-id tiebreaks
          final hlc = Hlc(tick, rnd.nextInt(3), 1 + rnd.nextInt(3));
          final target = uid(rnd.nextInt(8));
          final scope = OrderScope(EntityKind.task, uid(90), rnd.nextInt(2));
          switch (rnd.nextInt(6)) {
            case 0:
              ops.add(CreateEntityOp(hlc, EntityKind.task, target));
            case 1:
              ops.add(DeleteEntityOp(hlc, EntityKind.task, target));
            case 2:
              ops.add(SetFieldOp(hlc, EntityKind.task, target,
                  TaskField.title, StringValue('t${rnd.nextInt(5)}')));
            case 3:
              ops.add(SetFieldOp(hlc, EntityKind.task, target,
                  TaskField.isCompleted, BoolValue(rnd.nextBool())));
            case 4:
              ops.add(SetOrderOp(
                  hlc,
                  scope,
                  List.generate(
                      rnd.nextInt(5), (_) => uid(rnd.nextInt(8)))));
            default:
              ops.add(MoveWithinOrderOp(hlc, scope, uid(rnd.nextInt(8)),
                  rnd.nextBool() ? uid(rnd.nextInt(8)) : null));
          }
        }

        // Reference: strict HLC order.
        final reference = Replica()
          ..applyAll(
            List<Op>.from(ops)..sort((a, b) => a.hlc.compareTo(b.hlc)),
          );
        final want = snapshot(reference);

        // Deliver in arbitrary order WITHOUT pre-sorting. Segments arrive
        // interleaved from several devices and a device may replay an old
        // segment at any time, so apply() itself has to be order-free —
        // sorting first in the test would hide exactly that class of bug.
        for (var p = 0; p < 8; p++) {
          final shuffled = List<Op>.from(ops)..shuffle(Random(p));
          final replica = Replica()..applyAll(shuffled);
          expect(
            snapshot(replica),
            want,
            reason: 'trial $trial permutation $p diverged',
          );
        }

        // Delivering in several arbitrary batches, with overlap between
        // them, must also land in the same place.
        for (var p = 0; p < 4; p++) {
          final rng2 = Random(1000 + p);
          final replica = Replica();
          for (var batch = 0; batch < 4; batch++) {
            final slice = List<Op>.from(ops)..shuffle(rng2);
            replica.applyAll(slice.take(1 + rng2.nextInt(ops.length)));
          }
          replica.applyAll(ops); // everything eventually arrives
          expect(
            snapshot(replica),
            want,
            reason: 'trial $trial batched delivery $p diverged',
          );
        }
      }
    });

    test('duplicate delivery is idempotent', () {
      final rnd = Random(99);
      final ops = List<Op>.generate(
        30,
        (i) => SetFieldOp(Hlc(1000 + i, 0, 1 + (i % 2)), EntityKind.task,
            uid(i % 5), TaskField.title, StringValue('v$i')),
      );
      final once = Replica()..applyAll(ops);
      final twice = Replica()
        ..applyAll(ops)
        ..applyAll(ops)
        ..applyAll(List<Op>.from(ops)..shuffle(rnd));
      expect(snapshot(twice), snapshot(once),
          reason: 'replaying a segment twice must change nothing');
    });

    test('split-brain: two devices offline then exchange everything', () {
      // Shared starting point.
      final common = <Op>[
        CreateEntityOp(const Hlc(100, 0, 0), EntityKind.task, uid(1)),
        SetFieldOp(const Hlc(101, 0, 0), EntityKind.task, uid(1),
            TaskField.title, const StringValue('original')),
        SetOrderOp(const Hlc(102, 0, 0),
            OrderScope(EntityKind.task, uid(90), 0), [uid(1)]),
      ];

      // Device A works offline for a week.
      final aOps = <Op>[
        SetFieldOp(const Hlc(200, 0, 1), EntityKind.task, uid(1),
            TaskField.notes, const StringValue('phone notes')),
        CreateEntityOp(const Hlc(201, 0, 1), EntityKind.task, uid(2)),
        SetFieldOp(const Hlc(202, 0, 1), EntityKind.task, uid(2),
            TaskField.title, const StringValue('added on phone')),
        MoveWithinOrderOp(const Hlc(203, 0, 1),
            OrderScope(EntityKind.task, uid(90), 0), uid(2), null),
      ];

      // Device B works offline too, touching a different field.
      final bOps = <Op>[
        SetFieldOp(const Hlc(210, 0, 2), EntityKind.task, uid(1),
            TaskField.isCompleted, const BoolValue(true)),
        CreateEntityOp(const Hlc(211, 0, 2), EntityKind.task, uid(3)),
        SetFieldOp(const Hlc(212, 0, 2), EntityKind.task, uid(3),
            TaskField.title, const StringValue('added on desktop')),
      ];

      Replica build(List<List<Op>> batches) {
        final all = <Op>[for (final b in batches) ...b]
          ..sort((x, y) => x.hlc.compareTo(y.hlc));
        return Replica()..applyAll(all);
      }

      final a = build([common, aOps, bOps]);
      final b = build([common, bOps, aOps]);

      expect(snapshot(a), snapshot(b), reason: 'devices must converge');

      // Nothing was lost in the merge.
      final t1 = a.get(EntityKind.task, uid(1))!;
      expect(t1.stringField(TaskField.title), 'original');
      expect(t1.stringField(TaskField.notes), 'phone notes');
      expect(t1.boolField(TaskField.isCompleted), isTrue);
      expect(a.live(EntityKind.task).length, 3,
          reason: 'both offline additions survive');
    });
  });

  group('chunk load', () {
    test('loading a chunk merges instead of overwriting newer state', () {
      final r = Replica();
      // Newer edit already applied from a segment.
      r.apply(SetFieldOp(const Hlc(500, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('newer from log')));

      // Older base chunk arrives afterwards.
      final stale = ReplicatedEntity(
        kind: EntityKind.task,
        id: uid(1),
        createdAt: const Hlc(10, 0, 1),
      )..setField(TaskField.title, const StringValue('older from base'),
          const Hlc(100, 0, 1));
      r.loadChunk(Chunk.build([stale], {}));

      expect(r.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
          'newer from log',
          reason: 'base must never clobber a newer logged edit');
    });

    test('unfolded moves survive a chunk round-trip', () {
      // A move that is newer than the baseline must still be a *move* after
      // persisting, not silently folded in. Otherwise a peer holding the
      // same move would discard it as "already in the baseline" and the two
      // devices would order the list differently forever.
      final scope = OrderScope(EntityKind.task, uid(90), 0);
      final r = Replica();
      r.apply(SetOrderOp(const Hlc(10, 0, 1), scope, [uid(1), uid(2), uid(3)]));
      r.apply(MoveWithinOrderOp(const Hlc(20, 0, 1), scope, uid(3), null));

      final snap = r.orderSnapshots[scope]!;
      expect(snap.baseline, [uid(1), uid(2), uid(3)]);
      expect(snap.moves.length, 1, reason: 'move must not be pre-folded');

      final restored = Replica()
        ..loadChunk(
          Chunk.decode(
            Chunk.build(r.entities.values.toList(), r.orderSnapshots).encode(),
          ),
        );
      final members = {uid(1), uid(2), uid(3)};
      expect(restored.orderedIds(scope, members),
          r.orderedIds(scope, members));
      expect(restored.orderSnapshots[scope]!.moves.length, 1);
    });

    test('round-trips through encode/decode preserving convergence', () {
      final r = Replica();
      r.apply(CreateEntityOp(const Hlc(10, 0, 1), EntityKind.task, uid(1)));
      r.apply(SetFieldOp(const Hlc(11, 0, 1), EntityKind.task, uid(1),
          TaskField.title, const StringValue('persisted')));
      r.apply(SetOrderOp(const Hlc(12, 0, 1),
          OrderScope(EntityKind.task, uid(90), 0), [uid(1)]));
      r.apply(DeleteEntityOp(const Hlc(13, 0, 1), EntityKind.tag, uid(5)));

      final chunk =
          Chunk.build(r.entities.values.toList(), r.orderSnapshots);
      final restored = Replica()..loadChunk(Chunk.decode(chunk.encode()));

      expect(snapshot(restored), snapshot(r));
    });
  });
}
