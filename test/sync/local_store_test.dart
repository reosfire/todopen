import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/services/app_database.dart';
import 'package:todopen/sync/local_store.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

/// A distinct op per [n], identified on the way back out by its HLC.
Op op(int n) => SetFieldOp(
  Hlc(1000 + n, 0, 1),
  EntityKind.task,
  Uuid128.generateV4(),
  TaskField.title,
  StringValue('title $n'),
);

List<int> ids(List<Op> ops) => [for (final o in ops) o.hlc.physical - 1000];

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Rows the pending log occupies, to check appends stay appends.
  Future<int> pendingRows() async {
    final rows = await (db.select(
      db.uiStateEntries,
    )..where((t) => t.key.like('pending_ops%'))).get();
    return rows.length;
  }

  /// What a fresh launch would read back.
  Future<List<int>> reload() async => ids(await LocalStore(db).loadPending());

  group('pending log', () {
    test('growing the queue appends only the new ops', () async {
      final store = LocalStore(db);
      final ops = [op(0)];
      await store.savePending(ops, 1);
      for (var i = 1; i < 5; i++) {
        ops.add(op(i));
        await store.savePending(List.of(ops), 1);
      }
      expect(await reload(), [0, 1, 2, 3, 4]);
      expect(await pendingRows(), 5, reason: 'one base row plus four tails');
    });

    test('a queue that no longer extends what is saved is rewritten', () async {
      // What a successful push looks like: the old ops leave the queue and
      // new ones arrive. None of the pushed ops may come back on reload.
      final store = LocalStore(db);
      final pushed = [op(0), op(1)];
      await store.savePending([pushed[0]], 1);
      await store.savePending(pushed, 1);
      await store.savePending([op(2)], 1);
      expect(await reload(), [2]);
      expect(await pendingRows(), 1);
    });

    test('an empty queue clears the log entirely', () async {
      final store = LocalStore(db);
      final ops = [op(0)];
      await store.savePending(ops, 1);
      await store.savePending([...ops, op(1)], 1);
      await store.savePending(const [], 1);
      expect(await reload(), isEmpty);
      expect(await pendingRows(), 0);
    });

    test('tails are folded back once there are many', () async {
      final store = LocalStore(db);
      final ops = <Op>[];
      for (var i = 0; i < 100; i++) {
        ops.add(op(i));
        await store.savePending(List.of(ops), 1);
      }
      expect(await reload(), List.generate(100, (i) => i));
      expect(await pendingRows(), lessThanOrEqualTo(33));
    });

    test('a later launch keeps appending after what it loaded', () async {
      final first = LocalStore(db);
      final a = [op(0)];
      await first.savePending(a, 1);
      await first.savePending([...a, op(1)], 1);

      final second = LocalStore(db);
      final loaded = await second.loadPending();
      expect(ids(loaded), [0, 1]);
      await second.savePending([...loaded, op(2)], 1);
      expect(await reload(), [0, 1, 2]);
      expect(await pendingRows(), 3, reason: 'appended, not rewritten');
    });

    test('saves issued back to back land in order', () async {
      // Edits do not wait for the previous write to finish, so an append
      // and a rewrite can be in flight together; the last one must win.
      final store = LocalStore(db);
      final a = op(0);
      final b = op(1);
      final c = op(3);
      await Future.wait([
        store.savePending([a], 1),
        store.savePending([a, b], 1),
        store.savePending([a, b, op(2)], 1),
        store.savePending([c], 1),
        store.savePending([c, op(4)], 1),
      ]);
      expect(await reload(), [3, 4]);
    });

    test('an unchanged queue writes nothing', () async {
      final store = LocalStore(db);
      final ops = [op(0), op(1)];
      await store.savePending(ops, 1);
      await store.savePending(List.of(ops), 1);
      expect(await pendingRows(), 1);
    });
  });
}
