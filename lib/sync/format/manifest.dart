import 'dart:typed_data';

import '../model/hlc.dart';
import 'byte_io.dart';
import 'crc32c.dart';
import 'op_codec.dart';

/// Description of one base chunk as recorded in the manifest.
class ChunkRef {
  /// Shard key: 0 for the singleton shard holding lists/folders/tags/smart
  /// lists, otherwise a hash bucket of the owning list id.
  final int shard;

  /// Generation this chunk was written at; part of its filename.
  final int gen;

  /// Byte length, so a client can budget downloads before fetching.
  final int size;

  /// Highest HLC contained; lets a client skip a chunk it is already current
  /// with even after the manifest advanced for other shards.
  final Hlc maxHlc;

  /// CRC-32C of the encoded chunk.
  ///
  /// The authoritative content identity. Compaction uses it to decide
  /// whether a shard really changed, and clients use it to tell a rewritten
  /// chunk from one merely carried over at its old generation.
  final int crc;

  const ChunkRef({
    required this.shard,
    required this.gen,
    required this.size,
    required this.maxHlc,
    required this.crc,
  });

  String get path => '/base/${shard.toRadixString(16)}.$gen.tc';
}

/// Description of one log segment.
class SegmentRef {
  final int seq;
  final int size;
  final Hlc minHlc;
  final Hlc maxHlc;
  final int deviceId;

  const SegmentRef({
    required this.seq,
    required this.size,
    required this.minHlc,
    required this.maxHlc,
    required this.deviceId,
  });

  /// Segment filenames embed the writing device as well as the sequence
  /// number. Two devices can pick the same `seq` when they read the same
  /// manifest concurrently; only one will win the CAS, but both will have
  /// already uploaded. Without the device suffix the loser's cleanup would
  /// delete the winner's file, leaving the manifest pointing at nothing.
  String get path =>
      '/seg/${seq.toString().padLeft(8, '0')}-'
      '${deviceId.toRadixString(16).padLeft(8, '0')}.ts';
}

/// The root pointer.
///
/// This is the only mutable file in the store, and every write to it is a
/// compare-and-swap against its Dropbox `rev`. That single serialisation
/// point is what makes concurrent devices safe: whoever loses the CAS
/// re-reads, rebases and retries, so no update is ever silently dropped.
///
/// Kept deliberately tiny (a few hundred bytes) — it is read on every sync.
///
/// Layout:
///   magic    u32  'TMAN'
///   version  u8
///   flags    u8
///   baseGen  varint
///   nextSeq  varint
///   chunkN   varint  then chunkN × chunk refs
///   segN     varint  then segN  × segment refs
///   crc32c   u32
class Manifest {
  static const magic = 0x4E414D54; // 'TMAN'
  static const version = 1;

  /// Current base generation. Chunks from older generations are garbage.
  final int baseGen;

  /// Next free segment sequence number.
  final int nextSeq;

  final List<ChunkRef> chunks;
  final List<SegmentRef> segments;

  const Manifest({
    required this.baseGen,
    required this.nextSeq,
    required this.chunks,
    required this.segments,
  });

  factory Manifest.empty() =>
      const Manifest(baseGen: 0, nextSeq: 0, chunks: [], segments: []);

  /// Total bytes a fresh client must download to reconstruct state.
  int get coldDownloadBytes =>
      chunks.fold(0, (a, c) => a + c.size) +
      segments.fold(0, (a, s) => a + s.size);

  int get segmentBytes => segments.fold(0, (a, s) => a + s.size);
  int get baseBytes => chunks.fold(0, (a, c) => a + c.size);

  Uint8List encode() {
    final w = ByteWriter(128 + chunks.length * 24 + segments.length * 36);
    w.u32(magic);
    w.u8(version);
    w.u8(0);
    w.varint(baseGen);
    w.varint(nextSeq);

    w.varint(chunks.length);
    for (final c in chunks) {
      w.varint(c.shard);
      w.varint(c.gen);
      w.varint(c.size);
      OpCodec.writeHlc(w, c.maxHlc);
      w.u32(c.crc);
    }

    w.varint(segments.length);
    for (final s in segments) {
      w.varint(s.seq);
      w.varint(s.size);
      OpCodec.writeHlc(w, s.minHlc);
      OpCodec.writeHlc(w, s.maxHlc);
      w.u32(s.deviceId);
    }

    final body = w.viewBytes();
    w.u32(Crc32c.compute(body, 0, body.length));
    return w.takeBytes();
  }

  static Manifest decode(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const CorruptDataException('manifest too short');
    }
    final bodyEnd = bytes.length - 4;
    final expected =
        (bytes[bodyEnd] |
            (bytes[bodyEnd + 1] << 8) |
            (bytes[bodyEnd + 2] << 16) |
            (bytes[bodyEnd + 3] << 24)) &
        0xFFFFFFFF;
    if (Crc32c.compute(bytes, 0, bodyEnd) != expected) {
      throw const CorruptDataException('manifest checksum mismatch');
    }

    final r = ByteReader(bytes, 0, bodyEnd);
    if (r.u32() != magic) {
      throw const CorruptDataException('bad manifest magic');
    }
    final v = r.u8();
    if (v != version) {
      throw CorruptDataException('unsupported manifest version $v');
    }
    r.u8();
    final baseGen = r.varint();
    final nextSeq = r.varint();

    final chunkN = r.varint();
    final chunks = <ChunkRef>[];
    for (var i = 0; i < chunkN; i++) {
      chunks.add(
        ChunkRef(
          shard: r.varint(),
          gen: r.varint(),
          size: r.varint(),
          maxHlc: OpCodec.readHlc(r),
          crc: r.u32(),
        ),
      );
    }

    final segN = r.varint();
    final segments = <SegmentRef>[];
    for (var i = 0; i < segN; i++) {
      segments.add(
        SegmentRef(
          seq: r.varint(),
          size: r.varint(),
          minHlc: OpCodec.readHlc(r),
          maxHlc: OpCodec.readHlc(r),
          deviceId: r.u32(),
        ),
      );
    }

    return Manifest(
      baseGen: baseGen,
      nextSeq: nextSeq,
      chunks: chunks,
      segments: segments,
    );
  }

  Manifest copyWith({
    int? baseGen,
    int? nextSeq,
    List<ChunkRef>? chunks,
    List<SegmentRef>? segments,
  }) => Manifest(
    baseGen: baseGen ?? this.baseGen,
    nextSeq: nextSeq ?? this.nextSeq,
    chunks: chunks ?? this.chunks,
    segments: segments ?? this.segments,
  );
}
