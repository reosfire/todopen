import 'dart:typed_data';

import '../../utils/uuid128.dart';
import 'hlc.dart';

/// Entity kinds addressable by the log.
enum EntityKind {
  task(0),
  list(1),
  folder(2),
  tag(3),
  smartList(4);

  final int wire;
  const EntityKind(this.wire);

  static EntityKind fromWire(int w) => switch (w) {
    0 => EntityKind.task,
    1 => EntityKind.list,
    2 => EntityKind.folder,
    3 => EntityKind.tag,
    4 => EntityKind.smartList,
    _ => throw ArgumentError('unknown EntityKind wire value $w'),
  };
}

/// Field identifiers, unique per [EntityKind].
///
/// Each field carries its own HLC, so two devices editing different fields
/// of the same entity both keep their edit. Renumbering a value here is a
/// format break; only ever append.
abstract final class TaskField {
  static const title = 0;
  static const notes = 1;
  static const isCompleted = 2;
  static const scheduledDate = 3;
  static const recurrence = 4;
  static const listId = 5;
  static const tagIds = 6;
  static const completedDates = 7;
  static const createdAt = 8;
}

abstract final class ListField {
  static const name = 0;
  static const color = 1;
  static const folderId = 2;
}

abstract final class FolderField {
  static const name = 0;
}

abstract final class TagField {
  static const name = 0;
  static const color = 1;
}

abstract final class SmartListField {
  static const name = 0;
  static const icon = 1;
  static const color = 2;
  static const filter = 3;
}

/// Opcodes written into segment files.
enum OpCode {
  /// Set one field of one entity. Carries an HLC for per-field LWW.
  setField(1),

  /// Create an entity with no fields set yet (fields follow as setField ops).
  createEntity(2),

  /// Tombstone an entity.
  deleteEntity(3),

  /// Replace the dense ordering array of one ordering scope.
  setOrder(4),

  /// Move a single entity within its ordering scope without resending the
  /// whole array. Cheap for the common drag-one-task case.
  moveWithinOrder(5);

  final int wire;
  const OpCode(this.wire);

  static OpCode fromWire(int w) => switch (w) {
    1 => OpCode.setField,
    2 => OpCode.createEntity,
    3 => OpCode.deleteEntity,
    4 => OpCode.setOrder,
    5 => OpCode.moveWithinOrder,
    _ => throw ArgumentError('unknown OpCode wire value $w'),
  };
}

/// Tagged value union carried by [SetFieldOp].
///
/// Encoded as a 1-byte tag followed by a payload whose shape the tag
/// determines. No field numbers, no lengths where the type is fixed-width.
sealed class OpValue {
  const OpValue();
}

class NullValue extends OpValue {
  const NullValue();
}

class BoolValue extends OpValue {
  final bool value;
  const BoolValue(this.value);
}

/// Signed integer, zigzag varint encoded.
class IntValue extends OpValue {
  final int value;
  const IntValue(this.value);
}

class StringValue extends OpValue {
  final String value;
  const StringValue(this.value);
}

/// Milliseconds since epoch. Distinct from [IntValue] so the decoder can
/// rebuild a DateTime without the schema telling it to.
class TimestampValue extends OpValue {
  final int millis;
  const TimestampValue(this.millis);
}

class UuidValue extends OpValue {
  final Uuid128 value;
  const UuidValue(this.value);
}

/// Unordered set of UUIDs (tag membership).
class UuidSetValue extends OpValue {
  final Set<Uuid128> values;
  const UuidSetValue(this.values);
}

/// Sorted set of day-resolution dates, stored as days-since-epoch deltas.
class DateSetValue extends OpValue {
  final Set<int> daysSinceEpoch;
  const DateSetValue(this.daysSinceEpoch);
}

/// Opaque pre-encoded blob (recurrence rules, smart-list filters).
class BlobValue extends OpValue {
  final Uint8List bytes;
  const BlobValue(this.bytes);
}

abstract final class ValueTag {
  static const nullTag = 0;
  static const boolFalse = 1;
  static const boolTrue = 2;
  static const int_ = 3;
  static const string = 4;
  static const timestamp = 5;
  static const uuid = 6;
  static const uuidSet = 7;
  static const dateSet = 8;
  static const blob = 9;
}

/// A single mutation.
sealed class Op {
  /// Timestamp of the mutation, used for conflict resolution.
  final Hlc hlc;
  const Op(this.hlc);
}

class CreateEntityOp extends Op {
  final EntityKind kind;
  final Uuid128 id;
  const CreateEntityOp(super.hlc, this.kind, this.id);
}

class SetFieldOp extends Op {
  final EntityKind kind;
  final Uuid128 id;
  final int field;
  final OpValue value;
  const SetFieldOp(super.hlc, this.kind, this.id, this.field, this.value);
}

class DeleteEntityOp extends Op {
  final EntityKind kind;
  final Uuid128 id;
  const DeleteEntityOp(super.hlc, this.kind, this.id);
}

/// Ordering scopes are addressed by (kind, scopeId).
///
/// - tasks pending  : scopeId = listId, kind = task,      lane 0
/// - tasks completed: scopeId = listId, kind = task,      lane 1
/// - lists/folders  : scopeId = Uuid128.zero, kind = list, lane 0
class OrderScope {
  final EntityKind kind;
  final Uuid128 scopeId;
  final int lane;

  const OrderScope(this.kind, this.scopeId, this.lane);

  @override
  bool operator ==(Object other) =>
      other is OrderScope &&
      kind == other.kind &&
      scopeId == other.scopeId &&
      lane == other.lane;

  @override
  int get hashCode => Object.hash(kind, scopeId, lane);

  @override
  String toString() => 'OrderScope(${kind.name}, $scopeId, lane $lane)';
}

/// Wholesale replacement of a dense ordering array.
///
/// The array is the authoritative order: position in the array *is* the
/// order. No gaps, no fractional indices, no linked-list pointers.
class SetOrderOp extends Op {
  final OrderScope scope;
  final List<Uuid128> ids;
  const SetOrderOp(super.hlc, this.scope, this.ids);
}

/// Move one id to sit immediately after [afterId] (null = move to head).
///
/// Commutes better than [SetOrderOp] under concurrent edits: two devices
/// moving two different tasks both keep their intent, whereas two full
/// array replacements would discard one.
class MoveWithinOrderOp extends Op {
  final OrderScope scope;
  final Uuid128 id;
  final Uuid128? afterId;
  const MoveWithinOrderOp(super.hlc, this.scope, this.id, this.afterId);
}
