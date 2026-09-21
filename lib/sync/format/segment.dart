import 'dart:typed_data';

import '../model/hlc.dart';
import '../model/ops.dart';
import 'byte_io.dart';
import 'crc32c.dart';
import 'op_codec.dart';

/// An immutable batch of operations.
///
/// Segments are written once and never modified, which is what makes the
/// whole scheme safe on a store with no atomic append: concurrent writers
/// each claim a distinct sequence number and never touch each other's bytes.
///
/// File layout:
///   magic    u32  'TSEG' (0x47455354 LE)
///   version  u8
///   flags    u8   reserved
///   opCount  varint
///   minHlc   12B  smallest HLC in the batch
///   maxHlc   12B  largest HLC in the batch
///   deviceId u32  origin device
///   ops      ...  opCount encoded ops
///   crc32c   u32  over everything preceding
///
/// minHlc/maxHlc in the header let a reader skip an entire segment without
/// decoding its ops when it has already seen that range.
class Segment {
  static const magic = 0x47455354; // 'TSEG'
  static const version = 1;

  final List<Op> ops;
  final Hlc minHlc;
  final Hlc maxHlc;
  final int deviceId;

  const Segment({
    required this.ops,
    required this.minHlc,
    required this.maxHlc,
    required this.deviceId,
  });

  factory Segment.fromOps(List<Op> ops, int deviceId) {
    if (ops.isEmpty) {
      return Segment(
        ops: const [],
        minHlc: Hlc.zero,
        maxHlc: Hlc.zero,
        deviceId: deviceId,
      );
    }
    var lo = ops.first.hlc;
    var hi = ops.first.hlc;
    for (final op in ops) {
      if (op.hlc < lo) lo = op.hlc;
      if (op.hlc > hi) hi = op.hlc;
    }
    return Segment(ops: ops, minHlc: lo, maxHlc: hi, deviceId: deviceId);
  }

  Uint8List encode() {
    final w = ByteWriter(64 + ops.length * 48);
    w.u32(magic);
    w.u8(version);
    w.u8(0); // flags
    w.varint(ops.length);
    OpCodec.writeHlc(w, minHlc);
    OpCodec.writeHlc(w, maxHlc);
    w.u32(deviceId);
    for (final op in ops) {
      OpCodec.writeOp(w, op);
    }
    final body = w.viewBytes();
    final crc = Crc32c.compute(body, 0, body.length);
    w.u32(crc);
    return w.takeBytes();
  }

  static Segment decode(Uint8List bytes) {
    if (bytes.length < 8) {
      throw const CorruptDataException('segment too short');
    }
    // Verify the checksum before trusting any length field inside, so a
    // corrupt opCount can never make us allocate wildly.
    final bodyEnd = bytes.length - 4;
    final expected =
        bytes[bodyEnd] |
        (bytes[bodyEnd + 1] << 8) |
        (bytes[bodyEnd + 2] << 16) |
        (bytes[bodyEnd + 3] << 24);
    final actual = Crc32c.compute(bytes, 0, bodyEnd);
    if ((expected & 0xFFFFFFFF) != actual) {
      throw const CorruptDataException('segment checksum mismatch');
    }

    final r = ByteReader(bytes, 0, bodyEnd);
    if (r.u32() != magic) {
      throw const CorruptDataException('bad segment magic');
    }
    final v = r.u8();
    if (v != version) {
      throw CorruptDataException('unsupported segment version $v');
    }
    r.u8(); // flags
    final opCount = r.varint();
    final minHlc = OpCodec.readHlc(r);
    final maxHlc = OpCodec.readHlc(r);
    final deviceId = r.u32();

    final ops = <Op>[];
    for (var i = 0; i < opCount; i++) {
      ops.add(OpCodec.readOp(r));
    }
    return Segment(
      ops: ops,
      minHlc: minHlc,
      maxHlc: maxHlc,
      deviceId: deviceId,
    );
  }

  /// Read only the header, without decoding ops — used to decide whether a
  /// segment is worth downloading in full.
  static ({Hlc minHlc, Hlc maxHlc, int deviceId, int opCount}) peek(
    Uint8List bytes,
  ) {
    final r = ByteReader(bytes);
    if (r.u32() != magic) {
      throw const CorruptDataException('bad segment magic');
    }
    r.u8();
    r.u8();
    final opCount = r.varint();
    final minHlc = OpCodec.readHlc(r);
    final maxHlc = OpCodec.readHlc(r);
    final deviceId = r.u32();
    return (
      minHlc: minHlc,
      maxHlc: maxHlc,
      deviceId: deviceId,
      opCount: opCount,
    );
  }
}
