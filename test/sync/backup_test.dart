import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/services/app_database.dart';
import 'package:todopen/sync/backup.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/format/chunk.dart';
import 'package:todopen/sync/local_store.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';

import 'replica_test.dart' show snapshot, uid;

final _list = uid(500);
final _scope = OrderScope(EntityKind.task, _list, 0);

/// A device with a clock that only moves forward, like the real one.
class _Device {
  int _t = 1000;
  late final clock = HlcClock(deviceId: 1, now: () => _t += 10);
  final replica = Replica();

  void apply(List<Op> ops) => replica.applyAll(ops);

  void addTask(int n, String title) {
    final h = clock.issue();
    apply([
      CreateEntityOp(h, EntityKind.task, uid(n)),
      SetFieldOp(
        h,
        EntityKind.task,
        uid(n),
        TaskField.title,
        StringValue(title),
      ),
      SetFieldOp(
        h,
        EntityKind.task,
        uid(n),
        TaskField.listId,
        UuidValue(_list),
      ),
    ]);
  }

  void rename(int n, String title) => apply([
    SetFieldOp(
      clock.issue(),
      EntityKind.task,
      uid(n),
      TaskField.title,
      StringValue(title),
    ),
  ]);

  void delete(int n) =>
      apply([DeleteEntityOp(clock.issue(), EntityKind.task, uid(n))]);

  String? title(int n) {
    final e = replica.get(EntityKind.task, uid(n));
    if (e == null || e.isDeleted) return null;
    return e.stringField(TaskField.title);
  }

  /// A copy as a backup holds it.
  Replica copy() => Replica()..loadChunk(_encodeDecode(replica));
}

/// Round-trip through the stored encoding, as a backup does.
Chunk _encodeDecode(Replica r) => Chunk.decode(
  Chunk.build(r.entities.values.toList(), r.orderSnapshots).encode(),
);

void main() {
  group('restoreOps', () {
    late _Device d;
    late Replica backup;

    setUp(() {
      d = _Device();
      d.addTask(1, 'kept');
      d.addTask(2, 'will be deleted');
      d.addTask(3, 'will be edited');
      d.apply([
        SetOrderOp(d.clock.issue(), _scope, [uid(1), uid(2), uid(3)]),
      ]);
      backup = d.copy();

      d.delete(2);
      d.rename(3, 'edited later');
      d.addTask(4, 'new since backup');
      d.apply([
        SetOrderOp(d.clock.issue(), _scope, [uid(3), uid(4), uid(1)]),
      ]);
    });

    test('bring back missing re-creates deleted items and nothing else', () {
      d.apply(restoreOps(d.replica, backup, d.clock, replaceAll: false));

      expect(d.title(1), 'kept');
      expect(d.title(2), 'will be deleted');
      expect(d.title(3), 'edited later');
      expect(d.title(4), 'new since backup');
    });

    test('replace everything matches the backup exactly', () {
      d.apply(restoreOps(d.replica, backup, d.clock, replaceAll: true));

      expect(d.title(1), 'kept');
      expect(d.title(2), 'will be deleted');
      expect(d.title(3), 'will be edited');
      expect(d.title(4), isNull);
      expect(d.replica.resolvedOrder(_scope), [uid(1), uid(2), uid(3)]);
    });

    test('restores items the device never had, as after a lost sync', () {
      final empty = _Device();
      empty.apply(
        restoreOps(empty.replica, backup, empty.clock, replaceAll: false),
      );
      expect(empty.title(1), 'kept');
      expect(empty.title(2), 'will be deleted');
    });

    test('a restore wins on every device it syncs to', () {
      // Another device already holds the post-backup state. The restore's
      // fresh stamps must beat it, or the next pull would undo the restore.
      final other = Replica()..loadChunk(_encodeDecode(d.replica));
      final ops = restoreOps(d.replica, backup, d.clock, replaceAll: true);
      d.apply(ops);
      other.applyAll(ops);
      expect(snapshot(other), snapshot(d.replica));
    });

    test('restoring the current state is a no-op', () {
      final same = d.copy();
      expect(restoreOps(d.replica, same, d.clock, replaceAll: true), isEmpty);
      expect(restoreOps(d.replica, same, d.clock, replaceAll: false), isEmpty);
    });
  });

  group('LocalStore backups', () {
    late AppDatabase db;
    late LocalStore store;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      store = LocalStore(db);
    });
    tearDown(() => db.close());

    Replica withTasks(int n) {
      final d = _Device();
      for (var i = 1; i <= n; i++) {
        d.addTask(i, 'task $i');
      }
      return d.replica;
    }

    test('round-trips and lists newest first with counts', () async {
      await store.saveBackup(withTasks(1), reason: 'a');
      await store.saveBackup(withTasks(3), reason: 'b');

      final list = await store.listBackups();
      expect(list.map((b) => b.reason), ['b', 'a']);
      expect(list.first.taskCount, 3);
      final restored = await store.loadBackup(list.first.id);
      expect(restored.live(EntityKind.task).length, 3);
    });

    test('an unchanged replica is not backed up twice', () async {
      final r = withTasks(2);
      expect(await store.saveBackup(r, reason: 'a'), isNotNull);
      expect(await store.saveBackup(r, reason: 'b'), isNull);
      expect(await store.listBackups(), hasLength(1));
    });

    test('pruning keeps the newest and every pinned one', () async {
      for (var i = 1; i <= 5; i++) {
        await store.saveBackup(withTasks(i), reason: '$i');
      }
      final oldest = (await store.listBackups()).last;
      await store.setBackupPinned(oldest.id, true);

      await store.pruneBackups(2);

      final left = await store.listBackups();
      expect(left.map((b) => b.reason), ['5', '4', '1']);
      expect(left.last.pinned, isTrue);
    });

    test('clearing the local cache keeps backups', () async {
      await store.saveReplica(withTasks(1));
      await store.saveBackup(withTasks(2), reason: 'a');
      await store.setBackupKeep(7);

      await store.clear();

      expect((await store.loadReplica()).restored, isFalse);
      expect(await store.listBackups(), hasLength(1));
      expect(await store.backupKeep(), 7);
    });

    test(
      'a corrupt backup refuses to restore rather than yield nothing',
      () async {
        final info = (await store.saveBackup(withTasks(1), reason: 'a'))!;
        await db
            .into(db.uiStateEntries)
            .insertOnConflictUpdate(
              UiStateEntriesCompanion.insert(
                key: 'backup.${info.id}',
                value: 'AAAA',
              ),
            );
        expect(store.loadBackup(info.id), throwsA(anything));
      },
    );
  });
}
