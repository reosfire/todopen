import 'dart:typed_data';

import '../../utils/uuid128.dart';
import '../engine/replica.dart';
import '../model/entities.dart';
import '../model/hlc.dart';
import '../model/ops.dart';
import 'byte_io.dart';
import 'crc32c.dart';
import 'op_codec.dart';
import 'string_pool.dart';

/// One shard of the base snapshot.
///
/// Sharding is what keeps this workable at 20k+ tasks: a change confined to
/// one list rewrites only that list's chunk, not the entire dataset.
///
/// File layout:
///   magic     u32  'TCNK'
///   version   u8
///   flags     u8
///   maxHlc    12B  high-water mark of everything inside
///   poolOff   u32  absolute offset of the string pool
///   entCount  varint
///   ordCount  varint
///   entities  ...
///   orders    ...
///   pool      ...  (at poolOff)
///   crc32c    u32
///
/// The pool is written last but its offset is patched into the header, so a
/// reader can jump to it, load the strings, then decode entities in one
/// forward pass.
class Chunk {
  static const magic = 0x4B4E4354; // 'TCNK'
  static const version = 1;

  final List<ReplicatedEntity> entities;

  /// Ordering state per scope: the baseline plus any moves not yet folded
  /// into it. Storing only the resolved array would erase that distinction
  /// and make peers disagree about what a later move applies to.
  final Map<OrderScope, OrderSnapshot> orderSnapshots;

  final Hlc maxHlc;

  const Chunk({
    required this.entities,
    required this.orderSnapshots,
    required this.maxHlc,
  });

  factory Chunk.build(
    List<ReplicatedEntity> entities,
    Map<OrderScope, OrderSnapshot> orderSnapshots,
  ) {
    var hi = Hlc.zero;
    for (final e in entities) {
      final m = e.maxHlc;
      if (m > hi) hi = m;
    }
    for (final o in orderSnapshots.values) {
      if (o.baselineHlc > hi) hi = o.baselineHlc;
      for (final mv in o.moves) {
        if (mv.hlc > hi) hi = mv.hlc;
      }
    }
    return Chunk(
      entities: entities,
      orderSnapshots: orderSnapshots,
      maxHlc: hi,
    );
  }

  // ───── Encoding ─────

  Uint8List encode() {
    final pool = StringPoolBuilder();

    // Pass 1: intern every string so pool indices are known before we emit
    // entity bodies.
    for (final e in entities) {
      for (final s in e.fields.values) {
        final v = s.value;
        if (v is StringValue) pool.intern(v.value);
      }
    }

    final w = ByteWriter(1024 + entities.length * 64);
    w.u32(magic);
    w.u8(version);
    w.u8(0);
    OpCodec.writeHlc(w, maxHlc);
    final poolOffPos = w.reserveU32();
    w.varint(entities.length);
    w.varint(orderSnapshots.length);

    for (final e in entities) {
      _writeEntity(w, e, pool);
    }
    for (final entry in orderSnapshots.entries) {
      _writeOrder(w, entry.key, entry.value);
    }

    w.patchU32(poolOffPos, w.length);
    pool.writeTo(w);

    final body = w.viewBytes();
    w.u32(Crc32c.compute(body, 0, body.length));
    return w.takeBytes();
  }

  static void _writeEntity(
    ByteWriter w,
    ReplicatedEntity e,
    StringPoolBuilder pool,
  ) {
    w.u8(e.kind.wire);
    OpCodec.writeUuid(w, e.id);
    OpCodec.writeHlc(w, e.createdAt);
    // Presence bits: 1 = has a delete stamp, 2 = lastCreate differs from
    // createdAt (an explicit re-create). Both are needed to reconstruct
    // liveness without depending on op arrival order.
    final hasDelete = e.rawDeletedAt != null;
    final hasRecreate = e.lastCreate != e.createdAt;
    w.u8((hasDelete ? 1 : 0) | (hasRecreate ? 2 : 0));
    if (hasDelete) OpCodec.writeHlc(w, e.rawDeletedAt!);
    if (hasRecreate) OpCodec.writeHlc(w, e.lastCreate);
    w.varint(e.fields.length);
    for (final entry in e.fields.entries) {
      // Field id carries a flag in bit 0: set means "this field's stamp is
      // the entity's createdAt", which lets us omit 12 bytes. Fields written
      // together in one action — which is most of them, since a task is
      // created in a single edit — all share that stamp, and at four fields
      // per task the HLCs otherwise outweigh the data.
      final sameAsCreate = entry.value.hlc == e.createdAt;
      w.varint((entry.key << 1) | (sameAsCreate ? 1 : 0));
      if (!sameAsCreate) OpCodec.writeHlc(w, entry.value.hlc);
      _writePooledValue(w, entry.value.value, pool);
    }
  }

  /// Same encoding as [OpCodec.writeValue] except strings become pool
  /// indices. Uses a distinct tag so the two encodings cannot be confused.
  static const _pooledStringTag = 0x7F;

  static void _writePooledValue(
    ByteWriter w,
    OpValue v,
    StringPoolBuilder pool,
  ) {
    if (v is StringValue) {
      w.u8(_pooledStringTag);
      w.varint(pool.intern(v.value));
      return;
    }
    OpCodec.writeValue(w, v);
  }

  static OpValue _readPooledValue(ByteReader r, StringPool pool) {
    // Peek the tag without consuming, so OpCodec can read it itself.
    final tag = r.buf[r.position];
    if (tag == _pooledStringTag) {
      r.u8();
      return StringValue(pool[r.varint()]);
    }
    return OpCodec.readValue(r);
  }

  static void _writeOrder(ByteWriter w, OrderScope scope, OrderSnapshot order) {
    w.u8(scope.kind.wire);
    OpCodec.writeUuid(w, scope.scopeId);
    w.u8(scope.lane);
    OpCodec.writeHlc(w, order.baselineHlc);
    w.varint(order.baseline.length);
    for (final id in order.baseline) {
      OpCodec.writeUuid(w, id);
    }
    w.varint(order.moves.length);
    for (final m in order.moves) {
      OpCodec.writeUuid(w, m.id);
      OpCodec.writeHlc(w, m.hlc);
      w.u8(m.after == null ? 0 : 1);
      if (m.after != null) OpCodec.writeUuid(w, m.after!);
    }
  }

  // ───── Decoding ─────

  static Chunk decode(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const CorruptDataException('chunk too short');
    }
    final bodyEnd = bytes.length - 4;
    final expected =
        (bytes[bodyEnd] |
            (bytes[bodyEnd + 1] << 8) |
            (bytes[bodyEnd + 2] << 16) |
            (bytes[bodyEnd + 3] << 24)) &
        0xFFFFFFFF;
    if (Crc32c.compute(bytes, 0, bodyEnd) != expected) {
      throw const CorruptDataException('chunk checksum mismatch');
    }

    final r = ByteReader(bytes, 0, bodyEnd);
    if (r.u32() != magic) {
      throw const CorruptDataException('bad chunk magic');
    }
    final v = r.u8();
    if (v != version) {
      throw CorruptDataException('unsupported chunk version $v');
    }
    r.u8();
    final maxHlc = OpCodec.readHlc(r);
    final poolOff = r.u32();
    final entCount = r.varint();
    final ordCount = r.varint();

    if (poolOff > bodyEnd) {
      throw const CorruptDataException('chunk pool offset out of range');
    }
    final poolReader = ByteReader(bytes, poolOff, bodyEnd);
    final pool = StringPool.readFrom(poolReader);

    final entities = <ReplicatedEntity>[];
    for (var i = 0; i < entCount; i++) {
      entities.add(_readEntity(r, pool));
    }
    final orders = <OrderScope, OrderSnapshot>{};
    for (var i = 0; i < ordCount; i++) {
      final entry = _readOrder(r);
      orders[entry.$1] = entry.$2;
    }

    return Chunk(entities: entities, orderSnapshots: orders, maxHlc: maxHlc);
  }

  static ReplicatedEntity _readEntity(ByteReader r, StringPool pool) {
    final kind = EntityKind.fromWire(r.u8());
    final id = OpCodec.readUuid(r);
    final createdAt = OpCodec.readHlc(r);
    final flags = r.u8();
    final deletedAt = (flags & 1) != 0 ? OpCodec.readHlc(r) : null;
    final lastCreate = (flags & 2) != 0 ? OpCodec.readHlc(r) : createdAt;
    final fieldCount = r.varint();
    final fields = <int, Stamped<OpValue>>{};
    for (var i = 0; i < fieldCount; i++) {
      final tagged = r.varint();
      final fieldId = tagged >> 1;
      // Bit 0 set means the stamp was elided because it equals createdAt.
      final hlc = (tagged & 1) != 0 ? createdAt : OpCodec.readHlc(r);
      fields[fieldId] = Stamped(_readPooledValue(r, pool), hlc);
    }
    return ReplicatedEntity(
      kind: kind,
      id: id,
      fields: fields,
      createdAt: createdAt,
      deletedAt: deletedAt,
      lastCreate: lastCreate,
    );
  }

  static (OrderScope, OrderSnapshot) _readOrder(ByteReader r) {
    final kind = EntityKind.fromWire(r.u8());
    final scopeId = OpCodec.readUuid(r);
    final lane = r.u8();
    final baselineHlc = OpCodec.readHlc(r);
    final n = r.varint();
    final ids = <Uuid128>[];
    for (var i = 0; i < n; i++) {
      ids.add(OpCodec.readUuid(r));
    }
    final moveCount = r.varint();
    final moves = <({Uuid128 id, Uuid128? after, Hlc hlc})>[];
    for (var i = 0; i < moveCount; i++) {
      final id = OpCodec.readUuid(r);
      final hlc = OpCodec.readHlc(r);
      final after = r.u8() != 0 ? OpCodec.readUuid(r) : null;
      moves.add((id: id, after: after, hlc: hlc));
    }
    return (
      OrderScope(kind, scopeId, lane),
      OrderSnapshot(baseline: ids, baselineHlc: baselineHlc, moves: moves),
    );
  }
}
