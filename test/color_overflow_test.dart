import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/services/proto_serializer.dart';
import 'package:todopen/utils/uuid128.dart';

void main() {
  final id = Uuid128.fromBytes(Uint8List(16));

  test('sign-extended list color normalizes to unsigned', () {
    final l = TaskList(id: id, name: 'cyan', colorValue: -14235942, order: 0);
    final back = ProtoSerializer.listFromBytes(ProtoSerializer.listToBytes(l));
    expect(back.colorValue, 0xFF26C6DA);
  });

  test('sign-extended tag color normalizes to unsigned', () {
    final t = Tag(id: id, name: 'cyan', colorValue: -14235942);
    final back = ProtoSerializer.tagFromBytes(ProtoSerializer.tagToBytes(t));
    expect(back.colorValue, 0xFF26C6DA);
  });

  test('already-unsigned colors round-trip unchanged', () {
    final l = TaskList(id: id, name: 'ok', colorValue: 0xFF26C6DA, order: 0);
    final back = ProtoSerializer.listFromBytes(ProtoSerializer.listToBytes(l));
    expect(back.colorValue, 0xFF26C6DA);
  });

  test('null list color stays null', () {
    final l = TaskList(id: id, name: 'none', colorValue: null, order: 0);
    final back = ProtoSerializer.listFromBytes(ProtoSerializer.listToBytes(l));
    expect(back.colorValue, isNull);
  });

  test('smart list color normalizes', () {
    final s = SmartList(
      id: id,
      name: 'cyan',
      iconCodePoint: 0xe000,
      colorValue: -14235942,
      filter: AllTasksFilter(),
    );
    final back =
        ProtoSerializer.smartListFromBytes(ProtoSerializer.smartListToBytes(s));
    expect(back.colorValue, 0xFF26C6DA);
  });
}
