import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/sync/domain_mapper.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/model/entities.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

/// ARGB colours are conceptually unsigned 32-bit, but Flutter (and older
/// builds of this app) can hand back a sign-extended value such as
/// -14235942 for 0xFF26C6DA. Storing that verbatim and reading it back as a
/// negative would make `Color(colorValue)` render wrongly, so the round-trip
/// must land in the unsigned domain.
void main() {
  final id = Uuid128.fromBytes(Uint8List(16));
  const signExtendedCyan = -14235942;
  const unsignedCyan = 0xFF26C6DA;

  /// Push ops through a replica and hand the entity back for reading.
  ReplicatedEntity roundTrip(List<Op> ops, EntityKind kind) =>
      (Replica()..applyAll(ops)).get(kind, id)!;

  test('sign-extended list color normalizes to unsigned', () {
    final clock = HlcClock(deviceId: 1);
    final l = TaskList(id: id, name: 'cyan', colorValue: signExtendedCyan);
    final back = DomainMapper.listFrom(
      roundTrip(DomainMapper.createList(l, clock), EntityKind.list),
    )!;
    expect(back.colorValue, unsignedCyan);
  });

  test('sign-extended tag color normalizes to unsigned', () {
    final clock = HlcClock(deviceId: 1);
    final t = Tag(id: id, name: 'cyan', colorValue: signExtendedCyan);
    final back = DomainMapper.tagFrom(
      roundTrip(DomainMapper.createTag(t, clock), EntityKind.tag),
    )!;
    expect(back.colorValue, unsignedCyan);
  });

  test('already-unsigned colors round-trip unchanged', () {
    final clock = HlcClock(deviceId: 1);
    final l = TaskList(id: id, name: 'ok', colorValue: unsignedCyan);
    final back = DomainMapper.listFrom(
      roundTrip(DomainMapper.createList(l, clock), EntityKind.list),
    )!;
    expect(back.colorValue, unsignedCyan);
  });

  test('null list color stays null', () {
    final clock = HlcClock(deviceId: 1);
    final l = TaskList(id: id, name: 'none');
    final back = DomainMapper.listFrom(
      roundTrip(DomainMapper.createList(l, clock), EntityKind.list),
    )!;
    expect(back.colorValue, isNull);
  });

  test('smart list color normalizes', () {
    final clock = HlcClock(deviceId: 1);
    final s = SmartList(
      id: id,
      name: 'cyan',
      iconCodePoint: 0xe000,
      colorValue: signExtendedCyan,
      filter: const AllTasksFilter(),
    );
    final back = DomainMapper.smartListFrom(
      roundTrip(DomainMapper.createSmartList(s, clock), EntityKind.smartList),
    )!;
    expect(back.colorValue, unsignedCyan);
  });

  test('a cleared list colour reads back as null', () {
    final clock = HlcClock(deviceId: 1);
    final coloured = TaskList(id: id, name: 'x', colorValue: unsignedCyan);
    final replica = Replica()
      ..applyAll(DomainMapper.createList(coloured, clock));
    final cleared = TaskList(id: id, name: 'x');
    replica.applyAll(DomainMapper.updateList(cleared, coloured, clock));
    expect(
      DomainMapper.listFrom(replica.get(EntityKind.list, id)!)!.colorValue,
      isNull,
    );
  });
}
