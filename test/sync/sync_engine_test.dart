import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/sync/domain_mapper.dart';
import 'package:todopen/sync/engine/sync_engine.dart';
import 'package:todopen/sync/format/manifest.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

import 'fake_store.dart';
import 'replica_test.dart' show snapshot, uid;

/// Build an engine with a controllable clock.
SyncEngine engineFor(
  FakeStore store,
  int deviceId, {
  int Function()? now,
  SyncPolicy policy = const SyncPolicy(),
}) {
  return SyncEngine(
    store: store,
    clock: HlcClock(deviceId: deviceId, now: now),
    deviceId: deviceId,
    policy: policy,
  );
}

/// Record a task creation the way the app does.
///
/// Routes through DomainMapper rather than hand-rolling ops, so the tests
/// measure and exercise the real write path — including the shared
/// per-edit timestamp that lets the snapshot elide per-field stamps.
void addTask(SyncEngine e, Uuid128 id, String title, {Uuid128? listId}) {
  e.recordAll(
    DomainMapper.createTask(
      Task(
        id: id,
        title: title,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        listId: listId ?? _defaultList,
      ),
      e.clock,
    ),
  );
}

final _defaultList = Uuid128.fromBytes(Uint8List(16));

void main() {
  group('basic push/pull', () {
    test('first sync on an empty store writes a base and a manifest', () async {
      final store = FakeStore();
      final e = engineFor(store, 1);
      addTask(e, uid(1), 'first task');

      final report = await e.sync();

      expect(store.files.containsKey(SyncEngine.manifestPath), isTrue);
      // create + title + listId + createdAt; empty/default fields such as
      // notes and tags are omitted on create rather than written as blanks.
      expect(report.opsPushed, 4);
      // Compaction folds the very first segment straight into a base.
      expect(report.compacted, isTrue);
      expect(store.pathsUnder('/base'), isNotEmpty);
      expect(e.pendingOpCount, 0);
    });

    test('second device pulls the first device\'s work', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'from A');
      await a.sync();

      final b = engineFor(store, 2);
      await b.hydrate();

      expect(
        b.replica.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        'from A',
      );
    });

    test('round-trip of edits between two devices converges', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);

      addTask(a, uid(1), 'task one');
      await a.sync();
      await b.sync();

      // B edits, A edits a different field.
      b.record(
        SetFieldOp(
          b.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.isCompleted,
          const BoolValue(true),
        ),
      );
      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.notes,
          const StringValue('a note'),
        ),
      );

      // Push both, then let each pull the other's segment.
      await b.sync();
      await a.sync();
      await b.sync();
      await a.sync();

      expect(snapshot(a.replica), snapshot(b.replica));
      final t = a.replica.get(EntityKind.task, uid(1))!;
      expect(t.boolField(TaskField.isCompleted), isTrue);
      expect(t.stringField(TaskField.notes), 'a note');
      expect(t.stringField(TaskField.title), 'task one');
    });

    test('pulling twice is idempotent', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'x');
      await a.sync();

      final b = engineFor(store, 2);
      await b.sync();
      final first = snapshot(b.replica);
      await b.sync();
      await b.sync();
      expect(snapshot(b.replica), first);
    });
  });

  group('CAS conflicts', () {
    test('losing the manifest race retries and loses no data', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);

      addTask(a, uid(1), 'seed');
      await a.sync();
      await b.sync();

      // Both queue work while offline.
      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.title,
          const StringValue('renamed by A'),
        ),
      );
      addTask(b, uid(2), 'added by B');

      // Force A to lose the CAS exactly once: B commits mid-flight.
      var fired = false;
      store.beforeCas = (path) async {
        if (fired || path != SyncEngine.manifestPath) return;
        fired = true;
        store.beforeCas = null;
        await b.sync();
      };

      final report = await a.sync();
      expect(report.casRetries, isTrue, reason: 'A should have retried');

      await b.sync();
      await a.sync();

      expect(snapshot(a.replica), snapshot(b.replica));
      expect(
        a.replica.get(EntityKind.task, uid(1))!.stringField(TaskField.title),
        'renamed by A',
      );
      expect(
        a.replica.get(EntityKind.task, uid(2))!.stringField(TaskField.title),
        'added by B',
      );
    });

    test('orphaned segment from a lost CAS is cleaned up', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);
      addTask(a, uid(1), 'seed');
      await a.sync();
      await b.sync();

      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.notes,
          const StringValue('note'),
        ),
      );
      addTask(b, uid(2), 'b task');

      var fired = false;
      store.beforeCas = (path) async {
        if (fired || path != SyncEngine.manifestPath) return;
        fired = true;
        store.beforeCas = null;
        await b.sync();
      };
      await a.sync();

      // Every segment the manifest lists must exist on the store.
      final m = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      for (final s in m.segments) {
        expect(store.files.containsKey(s.path), isTrue,
            reason: 'manifest must not reference a missing segment ${s.path}');
      }
    });

    test('a device that never wins still converges after retry budget',
        () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'seed');
      await a.sync();

      final b = engineFor(store, 2);
      await b.sync();
      addTask(b, uid(2), 'b work');

      // Interfere on every CAS but one, then let it through.
      var count = 0;
      store.beforeCas = (path) async {
        if (path != SyncEngine.manifestPath) return;
        count++;
        if (count > 3) return;
        final other = engineFor(store, 90 + count);
        await other.sync();
        other.record(
          SetFieldOp(
            other.clock.issue(),
            EntityKind.task,
            uid(1),
            TaskField.notes,
            StringValue('interference $count'),
          ),
        );
        final saved = store.beforeCas;
        store.beforeCas = null;
        await other.sync();
        store.beforeCas = saved;
      };

      await b.sync();
      store.beforeCas = null;
      await b.sync();

      expect(b.replica.get(EntityKind.task, uid(2)), isNotNull);
      expect(b.pendingOpCount, 0);
    });
  });

  group('compaction', () {
    test('folds segments into the base and drops them', () async {
      final store = FakeStore();
      // Compact aggressively so the test does not need 48 syncs.
      const policy = SyncPolicy(maxSegments: 3, maxLogBytes: 1 << 30);
      final a = engineFor(store, 1, policy: policy);

      addTask(a, uid(1), 'one');
      await a.sync(allowCompaction: false);
      addTask(a, uid(2), 'two');
      await a.sync(allowCompaction: false);
      addTask(a, uid(3), 'three');

      final before = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      expect(before.segments.length, 2);

      final report = await a.sync();
      expect(report.compacted, isTrue);

      final after = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      expect(after.segments, isEmpty, reason: 'log folded into base');
      expect(after.baseGen, greaterThan(before.baseGen));
      expect(store.pathsUnder('/seg'), isEmpty, reason: 'old segments GCd');

      // State survived the fold.
      final fresh = engineFor(store, 2);
      await fresh.hydrate();
      expect(fresh.replica.live(EntityKind.task).length, 3);
      expect(snapshot(fresh.replica), snapshot(a.replica));
    });

    test('only rewrites shards that actually changed', () async {
      final store = FakeStore();
      const policy = SyncPolicy(maxSegments: 2, shardCount: 8);
      final a = engineFor(store, 1, policy: policy);

      // Two lists that hash to different shards.
      final listA = uid(400);
      final listB = uid(811);
      expect(a.shardFor(EntityKind.task, null), 0);

      addTask(a, uid(1), 'in list A', listId: listA);
      addTask(a, uid(2), 'in list B', listId: listB);
      await a.sync();

      final gen1 = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      final shardsWithTasks =
          gen1.chunks.where((c) => c.shard != 0).map((c) => c.shard).toSet();
      expect(shardsWithTasks.length, greaterThanOrEqualTo(1));

      // Touch only list A's task, then force compaction.
      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.title,
          const StringValue('renamed in A'),
        ),
      );
      await a.sync(allowCompaction: false);
      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.notes,
          const StringValue('n'),
        ),
      );
      await a.sync();

      final gen2 = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      expect(gen2.baseGen, greaterThan(gen1.baseGen));

      // Chunks whose content did not change keep their old generation,
      // proving they were carried by reference rather than rewritten.
      final carried = gen2.chunks.where((c) => c.gen < gen2.baseGen).toList();
      expect(carried, isNotEmpty,
          reason: 'untouched shards must not be rewritten');
    });

    test('compaction losing its CAS leaves the store consistent', () async {
      final store = FakeStore();
      const policy = SyncPolicy(maxSegments: 2);
      final a = engineFor(store, 1, policy: policy);
      final b = engineFor(store, 2, policy: policy);

      addTask(a, uid(1), 'seed');
      await a.sync();
      await b.sync();

      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(1),
          TaskField.notes,
          const StringValue('x'),
        ),
      );

      var fired = false;
      store.beforeCas = (path) async {
        if (fired) return;
        fired = true;
        store.beforeCas = null;
        addTask(b, uid(2), 'b wins');
        await b.sync();
      };

      await a.sync();
      store.beforeCas = null;
      await a.sync();
      await b.sync();

      // Whatever happened, the manifest must describe a loadable store.
      final fresh = engineFor(store, 3);
      await fresh.hydrate();
      expect(fresh.replica.get(EntityKind.task, uid(1)), isNotNull);
      expect(fresh.replica.get(EntityKind.task, uid(2)), isNotNull);
      expect(snapshot(fresh.replica), snapshot(a.replica));
    });

    test('old tombstones are dropped, recent ones retained', () async {
      final store = FakeStore();
      const policy = SyncPolicy(
        maxSegments: 1,
        tombstoneRetention: Duration(days: 30),
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final ancient = now - const Duration(days: 365).inMilliseconds;
      final a = engineFor(store, 1, now: () => now, policy: policy);

      // uid(1) is created AND deleted a year ago. Backdating only the delete
      // would leave a create newer than the tombstone, which correctly means
      // "re-created after deletion" rather than "long deleted".
      a.record(CreateEntityOp(Hlc(ancient, 0, 1), EntityKind.task, uid(1)));
      a.record(
        SetFieldOp(
          Hlc(ancient, 1, 1),
          EntityKind.task,
          uid(1),
          TaskField.title,
          const StringValue('old'),
        ),
      );
      addTask(a, uid(2), 'recent');
      await a.sync();

      a.record(DeleteEntityOp(Hlc(ancient, 2, 1), EntityKind.task, uid(1)));
      a.record(DeleteEntityOp(Hlc(now, 5, 1), EntityKind.task, uid(2)));
      await a.sync();

      final fresh = engineFor(store, 2);
      await fresh.hydrate();

      expect(fresh.replica.get(EntityKind.task, uid(1)), isNull,
          reason: 'tombstone past retention should be forgotten');
      final recent = fresh.replica.get(EntityKind.task, uid(2));
      expect(recent, isNotNull);
      expect(recent!.isDeleted, isTrue,
          reason: 'recent tombstone must survive so offline peers see it');
    });
  });

  group('cold start cost', () {
    test('is a small constant number of requests, not one per task', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);

      // 2000 tasks spread over 20 lists.
      for (var i = 0; i < 2000; i++) {
        addTask(a, uid(i), 'task number $i', listId: uid(9000 + (i % 20)));
      }
      await a.sync();

      store.resetCounters();
      final fresh = engineFor(store, 2);
      final report = await fresh.hydrate();

      expect(fresh.replica.live(EntityKind.task).length, 2000);
      // Manifest + at most one chunk per shard. The old design needed 2001.
      expect(report.requests, lessThanOrEqualTo(1 + 16),
          reason: 'cold start must not scale with task count');
      expect(store.reads, lessThanOrEqualTo(17));
    });

    test('small edit after sync uploads only a tiny segment', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      for (var i = 0; i < 500; i++) {
        addTask(a, uid(i), 'task $i', listId: uid(9000 + (i % 10)));
      }
      await a.sync();
      final baseSize = store.totalBytes;

      store.resetCounters();
      // Tick one checkbox.
      a.record(
        SetFieldOp(
          a.clock.issue(),
          EntityKind.task,
          uid(7),
          TaskField.isCompleted,
          const BoolValue(true),
        ),
      );
      await a.sync(allowCompaction: false);

      expect(store.bytesWritten, lessThan(400),
          reason: 'one checkbox must not rewrite the dataset '
              '(base is $baseSize bytes)');
      expect(store.writes, 2, reason: 'one segment + one manifest');
    });

    test('long offline with many edits pushes one segment', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'seed');
      await a.sync();

      store.resetCounters();
      // A week of offline edits.
      for (var i = 0; i < 200; i++) {
        a.record(
          SetFieldOp(
            a.clock.issue(),
            EntityKind.task,
            uid(1000 + i),
            TaskField.title,
            StringValue('offline task $i'),
          ),
        );
      }
      await a.sync(allowCompaction: false);

      expect(store.writes, 2,
          reason: '200 offline edits batch into a single segment upload');
    });
  });

  group('resilience', () {
    test('a segment vanishing mid-sync does not corrupt state', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'one');
      await a.sync(allowCompaction: false);
      addTask(a, uid(2), 'two');
      await a.sync(allowCompaction: false);

      // Simulate a GC race: a referenced segment disappears.
      final m = Manifest.decode(store.files[SyncEngine.manifestPath]!);
      if (m.segments.isNotEmpty) {
        store.files.remove(m.segments.first.path);
      }

      final fresh = engineFor(store, 2);
      await fresh.hydrate(); // must not throw
      expect(fresh.replica, isNotNull);
    });

    test('corrupt manifest surfaces as an error rather than silent loss',
        () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      addTask(a, uid(1), 'x');
      await a.sync();

      final good = store.files[SyncEngine.manifestPath]!;
      final bad = Uint8List.fromList(good);
      bad[bad.length ~/ 2] ^= 0xFF;
      store.files[SyncEngine.manifestPath] = bad;

      final fresh = engineFor(store, 2);
      expect(fresh.hydrate(), throwsA(isA<Exception>()));
    });

    test('empty store hydrates to an empty replica', () async {
      final store = FakeStore();
      final e = engineFor(store, 1);
      final report = await e.hydrate();
      expect(report.opsPulled, 0);
      expect(e.replica.entities, isEmpty);
    });
  });

  group('ordering across devices', () {
    test('reorder on one device is one op and converges', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);
      final list = uid(500);
      final scope = OrderScope(EntityKind.task, list, 0);

      for (var i = 1; i <= 4; i++) {
        addTask(a, uid(i), 'task $i', listId: list);
      }
      a.record(
        SetOrderOp(a.clock.issue(), scope, [uid(1), uid(2), uid(3), uid(4)]),
      );
      await a.sync();
      await b.sync();

      store.resetCounters();
      // Drag task 4 to the top: a single op, unlike the old linked list
      // which rewrote up to five task files.
      a.record(MoveWithinOrderOp(a.clock.issue(), scope, uid(4), null));
      await a.sync(allowCompaction: false);
      expect(store.writes, 2);

      await b.sync();
      final members = {uid(1), uid(2), uid(3), uid(4)};
      expect(b.replica.orderedIds(scope, members), [
        uid(4),
        uid(1),
        uid(2),
        uid(3),
      ]);
      expect(
        a.replica.orderedIds(scope, members),
        b.replica.orderedIds(scope, members),
      );
    });

    test('concurrent reorders on two devices converge without losing tasks',
        () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);
      final list = uid(500);
      final scope = OrderScope(EntityKind.task, list, 0);

      for (var i = 1; i <= 5; i++) {
        addTask(a, uid(i), 'task $i', listId: list);
      }
      a.record(
        SetOrderOp(a.clock.issue(), scope, [
          uid(1),
          uid(2),
          uid(3),
          uid(4),
          uid(5),
        ]),
      );
      await a.sync();
      await b.sync();

      a.record(MoveWithinOrderOp(a.clock.issue(), scope, uid(5), null));
      b.record(MoveWithinOrderOp(b.clock.issue(), scope, uid(1), uid(3)));

      await a.sync();
      await b.sync();
      await a.sync();
      await b.sync();

      final members = {uid(1), uid(2), uid(3), uid(4), uid(5)};
      expect(
        a.replica.orderedIds(scope, members),
        b.replica.orderedIds(scope, members),
        reason: 'both devices must agree on the final order',
      );
      expect(
        a.replica.orderedIds(scope, members).toSet(),
        members,
        reason: 'no task may be lost or duplicated by a concurrent reorder',
      );
    });
  });
}
