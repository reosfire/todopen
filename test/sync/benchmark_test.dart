import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/engine/sync_engine.dart';
import 'package:todopen/sync/model/ops.dart';

import 'fake_store.dart';
import 'replica_test.dart' show uid;
import 'sync_engine_test.dart' show engineFor, addTask;

/// Measures the three workloads the layout was designed around, and asserts
/// the bounds that justify the design. These are budgets, not micro-
/// benchmarks: they fail if a change makes a workload qualitatively worse.
void main() {
  /// Build a store holding [taskCount] tasks spread over [listCount] lists.
  Future<(FakeStore, SyncEngine)> seed({
    required int taskCount,
    required int listCount,
  }) async {
    final store = FakeStore();
    final engine = engineFor(store, 1);
    final rnd = Random(42);
    const words = [
      'review', 'draft', 'email', 'call', 'fix', 'ship', 'plan',
      'buy', 'book', 'renew', 'file', 'read',
    ];
    for (var i = 0; i < taskCount; i++) {
      final title =
          '${words[rnd.nextInt(words.length)]} '
          '${words[rnd.nextInt(words.length)]} $i';
      addTask(engine, uid(i), title, listId: uid(900000 + (i % listCount)));
    }
    await engine.sync();
    return (store, engine);
  }

  group('workload: first download', () {
    test('2000 tasks cost a handful of requests, not one per task', () async {
      final (store, _) = await seed(taskCount: 2000, listCount: 20);
      store.resetCounters();

      final fresh = engineFor(store, 2);
      final report = await fresh.hydrate();

      expect(fresh.replica.live(EntityKind.task).length, 2000);
      // Manifest + at most one chunk per shard.
      expect(report.requests, lessThanOrEqualTo(17));

      final perTask = report.bytesDown / 2000;
      // The old per-entity protobuf averaged ~120-180 B/task plus an HTTP
      // round-trip each; anything near that means the format regressed.
      expect(perTask, lessThan(85), reason: '${perTask.toStringAsFixed(1)} B/task');

      // ignore: avoid_print
      print(
        'cold start 2000 tasks: ${report.requests} requests, '
        '${report.bytesDown} B (${perTask.toStringAsFixed(1)} B/task)',
      );
    });

    test('scales sublinearly in requests as data grows', () async {
      final (smallStore, _) = await seed(taskCount: 200, listCount: 10);
      final (bigStore, _) = await seed(taskCount: 4000, listCount: 40);

      smallStore.resetCounters();
      bigStore.resetCounters();
      final small = await engineFor(smallStore, 9).hydrate();
      final big = await engineFor(bigStore, 9).hydrate();

      expect(big.requests, lessThanOrEqualTo(small.requests * 2),
          reason: '20x the data must not mean 20x the requests');

      // ignore: avoid_print
      print(
        'requests: 200 tasks -> ${small.requests}, '
        '4000 tasks -> ${big.requests}',
      );
    });
  });

  group('workload: small change while online', () {
    test('ticking one checkbox uploads a few hundred bytes', () async {
      final (store, engine) = await seed(taskCount: 2000, listCount: 20);
      final baseSize = store.totalBytes;
      store.resetCounters();

      engine.record(
        SetFieldOp(
          engine.clock.issue(),
          EntityKind.task,
          uid(7),
          TaskField.isCompleted,
          const BoolValue(true),
        ),
      );
      await engine.sync(allowCompaction: false);

      expect(store.writes, 2, reason: 'one segment + one manifest');
      expect(store.bytesWritten, lessThan(500));

      // ignore: avoid_print
      print(
        'one checkbox on a ${(baseSize / 1024).toStringAsFixed(0)} KB store: '
        '${store.bytesWritten} B in ${store.writes} writes',
      );
    });

    test('a drag-reorder is one op, not one write per task', () async {
      final (store, engine) = await seed(taskCount: 500, listCount: 5);
      final list = uid(900000);
      final scope = OrderScope(EntityKind.task, list, 0);
      store.resetCounters();

      engine.record(
        MoveWithinOrderOp(engine.clock.issue(), scope, uid(3), null),
      );
      await engine.sync(allowCompaction: false);

      expect(store.writes, 2);
      // The old linked list rewrote up to five whole task files per drag.
      expect(store.bytesWritten, lessThan(400));

      // ignore: avoid_print
      print('drag one task: ${store.bytesWritten} B');
    });
  });

  group('workload: long offline, then reconnect', () {
    test('a week of edits batches into one upload', () async {
      final (store, engine) = await seed(taskCount: 1000, listCount: 10);
      store.resetCounters();

      // 300 edits with no connectivity.
      final rnd = Random(7);
      for (var i = 0; i < 300; i++) {
        engine.record(
          SetFieldOp(
            engine.clock.issue(),
            EntityKind.task,
            uid(rnd.nextInt(1000)),
            TaskField.title,
            StringValue('edited offline $i'),
          ),
        );
      }
      await engine.sync(allowCompaction: false);

      expect(store.writes, 2, reason: '300 edits, one segment');

      // ignore: avoid_print
      print('300 offline edits: ${store.bytesWritten} B in ${store.writes} writes');
    });

    test('catching up after missing many segments stays cheap', () async {
      final store = FakeStore();
      final a = engineFor(store, 1);
      final b = engineFor(store, 2);

      for (var i = 0; i < 50; i++) {
        addTask(a, uid(i), 'task $i', listId: uid(900000));
      }
      await a.sync();
      await b.sync(); // b is now current

      // a makes 30 separate small syncs while b is offline.
      for (var i = 0; i < 30; i++) {
        a.record(
          SetFieldOp(
            a.clock.issue(),
            EntityKind.task,
            uid(i),
            TaskField.notes,
            StringValue('note $i'),
          ),
        );
        await a.sync(allowCompaction: false);
      }

      store.resetCounters();
      final report = await b.sync(allowCompaction: false);

      // b downloads only the segments it missed, not the whole base.
      expect(report.opsPulled, 30);
      expect(store.bytesRead, lessThan(5000));

      // ignore: avoid_print
      print(
        'catch up on 30 missed segments: ${store.reads} reads, '
        '${store.bytesRead} B',
      );
    });
  });

  group('compaction keeps the log bounded', () {
    test('churn does not grow the store without limit', () async {
      final store = FakeStore();
      final engine = engineFor(store, 1);
      for (var i = 0; i < 200; i++) {
        addTask(engine, uid(i), 'task $i', listId: uid(900000 + (i % 5)));
      }
      await engine.sync();
      final afterSeed = store.totalBytes;

      // 500 edits across many sync cycles.
      final rnd = Random(3);
      for (var i = 0; i < 500; i++) {
        engine.record(
          SetFieldOp(
            engine.clock.issue(),
            EntityKind.task,
            uid(rnd.nextInt(200)),
            TaskField.title,
            StringValue('churn $i'),
          ),
        );
        if (i % 10 == 0) await engine.sync();
      }
      await engine.sync();

      final afterChurn = store.totalBytes;
      expect(
        afterChurn,
        lessThan(afterSeed * 3),
        reason: 'compaction should reclaim superseded log data',
      );

      // A fresh client still sees the right thing.
      final fresh = engineFor(store, 2);
      await fresh.hydrate();
      expect(fresh.replica.live(EntityKind.task).length, 200);

      // ignore: avoid_print
      print(
        'after 500 edits: ${(afterSeed / 1024).toStringAsFixed(1)} KB -> '
        '${(afterChurn / 1024).toStringAsFixed(1)} KB, '
        '${store.fileCount} files',
      );
    });
  });
}
