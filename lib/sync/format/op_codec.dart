import 'dart:typed_data';

import '../../utils/uuid128.dart';
import '../model/hlc.dart';
import '../model/ops.dart';
import 'byte_io.dart';

/// Encodes and decodes [Op]s.
///
/// Layout of one op:
///   u8        opcode
///   12 bytes  hlc
///   ...       opcode-specific payload
///
/// There are no field tags and no lengths except where a value is genuinely
/// variable-length. The opcode fully determines the shape of what follows,
/// which is what lets this beat protobuf on size.
class OpCodec {
  static void writeUuid(ByteWriter w, Uuid128 id) {
    w.bytes(id.toBytes());
  }

  static Uuid128 readUuid(ByteReader r) {
    return Uuid128.fromBytes(r.bytesCopy(16));
  }

  static void writeHlc(ByteWriter w, Hlc hlc) {
    final tmp = Uint8List(Hlc.encodedSize);
    hlc.writeTo(tmp, 0);
    w.bytes(tmp);
  }

  static Hlc readHlc(ByteReader r) {
    final view = r.bytesView(Hlc.encodedSize);
    return Hlc.readFrom(view, 0);
  }

  // ───── Values ─────

  static void writeValue(ByteWriter w, OpValue v) {
    switch (v) {
      case NullValue():
        w.u8(ValueTag.nullTag);
      case BoolValue(:final value):
        w.u8(value ? ValueTag.boolTrue : ValueTag.boolFalse);
      case IntValue(:final value):
        w.u8(ValueTag.int_);
        w.svarint(value);
      case StringValue(:final value):
        w.u8(ValueTag.string);
        w.str(value);
      case TimestampValue(:final millis):
        w.u8(ValueTag.timestamp);
        w.svarint(millis);
      case UuidValue(:final value):
        w.u8(ValueTag.uuid);
        writeUuid(w, value);
      case UuidSetValue(:final values):
        w.u8(ValueTag.uuidSet);
        w.varint(values.length);
        for (final id in values) {
          writeUuid(w, id);
        }
      case DateSetValue(:final daysSinceEpoch):
        w.u8(ValueTag.dateSet);
        // Sort and delta-encode: completion dates cluster, so deltas are
        // almost always a single byte.
        final sorted = daysSinceEpoch.toList()..sort();
        w.varint(sorted.length);
        var prev = 0;
        for (final d in sorted) {
          w.svarint(d - prev);
          prev = d;
        }
      case BlobValue(:final bytes):
        w.u8(ValueTag.blob);
        w.varint(bytes.length);
        w.bytes(bytes);
    }
  }

  static OpValue readValue(ByteReader r) {
    final tag = r.u8();
    switch (tag) {
      case ValueTag.nullTag:
        return const NullValue();
      case ValueTag.boolFalse:
        return const BoolValue(false);
      case ValueTag.boolTrue:
        return const BoolValue(true);
      case ValueTag.int_:
        return IntValue(r.svarint());
      case ValueTag.string:
        return StringValue(r.str());
      case ValueTag.timestamp:
        return TimestampValue(r.svarint());
      case ValueTag.uuid:
        return UuidValue(readUuid(r));
      case ValueTag.uuidSet:
        final n = r.varint();
        final out = <Uuid128>{};
        for (var i = 0; i < n; i++) {
          out.add(readUuid(r));
        }
        return UuidSetValue(out);
      case ValueTag.dateSet:
        final n = r.varint();
        final out = <int>{};
        var prev = 0;
        for (var i = 0; i < n; i++) {
          prev += r.svarint();
          out.add(prev);
        }
        return DateSetValue(out);
      case ValueTag.blob:
        final n = r.varint();
        return BlobValue(r.bytesCopy(n));
      default:
        throw CorruptDataException('unknown value tag $tag', r.position);
    }
  }

  // ───── Ops ─────

  static void writeOp(ByteWriter w, Op op) {
    switch (op) {
      case CreateEntityOp(:final kind, :final id):
        w.u8(OpCode.createEntity.wire);
        writeHlc(w, op.hlc);
        w.u8(kind.wire);
        writeUuid(w, id);
      case SetFieldOp(:final kind, :final id, :final field, :final value):
        w.u8(OpCode.setField.wire);
        writeHlc(w, op.hlc);
        w.u8(kind.wire);
        writeUuid(w, id);
        w.varint(field);
        writeValue(w, value);
      case DeleteEntityOp(:final kind, :final id):
        w.u8(OpCode.deleteEntity.wire);
        writeHlc(w, op.hlc);
        w.u8(kind.wire);
        writeUuid(w, id);
      case SetOrderOp(:final scope, :final ids):
        w.u8(OpCode.setOrder.wire);
        writeHlc(w, op.hlc);
        w.u8(scope.kind.wire);
        writeUuid(w, scope.scopeId);
        w.u8(scope.lane);
        w.varint(ids.length);
        for (final id in ids) {
          writeUuid(w, id);
        }
      case MoveWithinOrderOp(:final scope, :final id, :final afterId):
        w.u8(OpCode.moveWithinOrder.wire);
        writeHlc(w, op.hlc);
        w.u8(scope.kind.wire);
        writeUuid(w, scope.scopeId);
        w.u8(scope.lane);
        writeUuid(w, id);
        w.u8(afterId == null ? 0 : 1);
        if (afterId != null) writeUuid(w, afterId);
    }
  }

  static Op readOp(ByteReader r) {
    final code = OpCode.fromWire(r.u8());
    final hlc = readHlc(r);
    switch (code) {
      case OpCode.createEntity:
        final kind = EntityKind.fromWire(r.u8());
        return CreateEntityOp(hlc, kind, readUuid(r));
      case OpCode.setField:
        final kind = EntityKind.fromWire(r.u8());
        final id = readUuid(r);
        final field = r.varint();
        return SetFieldOp(hlc, kind, id, field, readValue(r));
      case OpCode.deleteEntity:
        final kind = EntityKind.fromWire(r.u8());
        return DeleteEntityOp(hlc, kind, readUuid(r));
      case OpCode.setOrder:
        final kind = EntityKind.fromWire(r.u8());
        final scopeId = readUuid(r);
        final lane = r.u8();
        final n = r.varint();
        final ids = <Uuid128>[];
        for (var i = 0; i < n; i++) {
          ids.add(readUuid(r));
        }
        return SetOrderOp(hlc, OrderScope(kind, scopeId, lane), ids);
      case OpCode.moveWithinOrder:
        final kind = EntityKind.fromWire(r.u8());
        final scopeId = readUuid(r);
        final lane = r.u8();
        final id = readUuid(r);
        final hasAfter = r.u8() != 0;
        final afterId = hasAfter ? readUuid(r) : null;
        return MoveWithinOrderOp(
          hlc,
          OrderScope(kind, scopeId, lane),
          id,
          afterId,
        );
    }
  }
}
