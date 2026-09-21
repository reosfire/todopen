import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/format/byte_io.dart';
import 'package:todopen/sync/engine/replica.dart';
import 'package:todopen/sync/format/chunk.dart';
import 'package:todopen/sync/format/crc32c.dart';
import 'package:todopen/sync/format/manifest.dart';
import 'package:todopen/sync/format/op_codec.dart';
import 'package:todopen/sync/format/segment.dart';
import 'package:todopen/sync/model/entities.dart';
import 'package:todopen/sync/model/hlc.dart';
import 'package:todopen/sync/model/ops.dart';
import 'package:todopen/utils/uuid128.dart';

/// Deterministic distinct uuid per [n] (see replica_test for rationale).
Uuid128 uid(int n) => Uuid128.fromBytes(
  Uint8List.fromList([
    n & 0xFF,
    (n >> 8) & 0xFF,
    (n >> 16) & 0xFF,
    (n >> 24) & 0xFF,
    ...List.generate(12, (i) => (n * 31 + i * 7) & 0xFF),
  ]),
);

void main() {
  _largeValueTests();

  group('varint', () {
    test('round-trips boundary values', () {
      final values = [
        0,
        1,
        127,
        128,
        129,
        255,
        256,
        16383,
        16384,
        1 << 20,
        1 << 31,
        1 << 40,
        (1 << 53) - 1,
      ];
      final w = ByteWriter();
      for (final v in values) {
        w.varint(v);
      }
      final r = ByteReader(w.takeBytes());
      for (final v in values) {
        expect(r.varint(), v, reason: 'varint $v');
      }
      expect(r.isAtEnd, isTrue);
    });

    test('single byte below 128', () {
      final w = ByteWriter();
      w.varint(127);
      expect(w.length, 1);
    });

    test('zigzag round-trips negatives', () {
      final values = [0, -1, 1, -64, 63, -1000000, 1000000, -(1 << 40)];
      final w = ByteWriter();
      for (final v in values) {
        w.svarint(v);
      }
      final r = ByteReader(w.takeBytes());
      for (final v in values) {
        expect(r.svarint(), v, reason: 'svarint $v');
      }
    });

    test('rejects negative in unsigned varint', () {
      expect(() => ByteWriter().varint(-1), throwsArgumentError);
    });
  });

  group('ByteReader bounds', () {
    test('throws on truncated read rather than returning garbage', () {
      final r = ByteReader(Uint8List.fromList([1, 2]));
      expect(() => r.u32(), throwsA(isA<CorruptDataException>()));
    });

    test('throws on truncated string', () {
      final w = ByteWriter();
      w.varint(50); // claims 50 bytes
      w.bytes(Uint8List.fromList([65, 66]));
      final r = ByteReader(w.takeBytes());
      expect(() => r.str(), throwsA(isA<CorruptDataException>()));
    });
  });

  group('strings', () {
    test('round-trips unicode and empty', () {
      final cases = [
        '',
        'hello',
        'привет',
        '日本語',
        '🎉 emoji',
        List.filled(1000, 'a').join(),
      ];
      final w = ByteWriter();
      for (final s in cases) {
        w.str(s);
      }
      final r = ByteReader(w.takeBytes());
      for (final s in cases) {
        expect(r.str(), s);
      }
    });
  });

  group('Hlc', () {
    test('orders by physical, then counter, then device', () {
      expect(const Hlc(1, 0, 0) < const Hlc(2, 0, 0), isTrue);
      expect(const Hlc(1, 0, 0) < const Hlc(1, 1, 0), isTrue);
      expect(const Hlc(1, 1, 0) < const Hlc(1, 1, 5), isTrue);
      expect(const Hlc(2, 0, 0) > const Hlc(1, 99, 99), isTrue);
    });

    test('round-trips through bytes preserving order', () {
      final values = [
        const Hlc(0, 0, 0),
        const Hlc(1, 2, 3),
        Hlc(DateTime.now().millisecondsSinceEpoch, 7, 0xDEADBEEF),
        Hlc.max,
      ];
      for (final h in values) {
        final buf = Uint8List(Hlc.encodedSize);
        h.writeTo(buf, 0);
        expect(Hlc.readFrom(buf, 0), h, reason: '$h');
      }
    });

    test('byte order matches numeric order (big-endian physical)', () {
      final a = Uint8List(12), b = Uint8List(12);
      const Hlc(1000, 0, 0).writeTo(a, 0);
      const Hlc(2000, 0, 0).writeTo(b, 0);
      var cmp = 0;
      for (var i = 0; i < 12 && cmp == 0; i++) {
        cmp = a[i].compareTo(b[i]);
      }
      expect(cmp, lessThan(0));
    });
  });

  group('HlcClock', () {
    test('is monotonic when wall clock stalls', () {
      const fixed = 1000;
      final clock = HlcClock(deviceId: 1, now: () => fixed);
      final a = clock.issue();
      final b = clock.issue();
      final c = clock.issue();
      expect(b > a, isTrue);
      expect(c > b, isTrue);
    });

    test('is monotonic when wall clock jumps backwards', () {
      var t = 10000;
      final clock = HlcClock(deviceId: 1, now: () => t);
      final a = clock.issue();
      t = 5000; // NTP correction
      final b = clock.issue();
      expect(b > a, isTrue, reason: 'clock going back must not break order');
    });

    test('observing a remote timestamp makes later local events sort after', () {
      const t = 1000;
      final clock = HlcClock(deviceId: 1, now: () => t);
      const remote = Hlc(5000, 3, 99);
      clock.observe(remote);
      final local = clock.issue();
      expect(local > remote, isTrue);
    });

    test('ignores implausible future timestamps', () {
      const t = 1000;
      final clock = HlcClock(deviceId: 1, now: () => t);
      const bogus = Hlc(t + HlcClock.maxDriftMs * 10, 0, 99);
      clock.observe(bogus);
      final local = clock.issue();
      expect(
        local.physical,
        lessThan(bogus.physical),
        reason: 'must not adopt a poisoned clock',
      );
    });

    test('distinct devices never collide', () {
      const t = 1000;
      final a = HlcClock(deviceId: 1, now: () => t);
      final b = HlcClock(deviceId: 2, now: () => t);
      expect(a.issue() == b.issue(), isFalse);
    });
  });

  group('Crc32c', () {
    test('matches known vectors', () {
      // Castagnoli check value for "123456789" is 0xE3069283.
      expect(
        Crc32c.compute(Uint8List.fromList('123456789'.codeUnits)),
        0xE3069283,
      );
      expect(Crc32c.compute(Uint8List(0)), 0);
    });

    test('detects single-bit flips', () {
      final data = Uint8List.fromList(List.generate(200, (i) => i & 0xFF));
      final good = Crc32c.compute(data);
      for (var i = 0; i < data.length; i += 17) {
        final bad = Uint8List.fromList(data);
        bad[i] ^= 0x01;
        expect(Crc32c.compute(bad), isNot(good));
      }
    });
  });

  group('OpValue round-trip', () {
    test('covers every tag', () {
      final values = <OpValue>[
        const NullValue(),
        const BoolValue(true),
        const BoolValue(false),
        const IntValue(0),
        const IntValue(-42),
        const IntValue(1 << 40),
        const StringValue(''),
        const StringValue('hello 🎉'),
        const TimestampValue(1700000000000),
        UuidValue(uid(1)),
        UuidSetValue({uid(1), uid(2), uid(3)}),
        const DateSetValue({19000, 19001, 19050, 20000}),
        BlobValue(Uint8List.fromList([1, 2, 3, 250])),
      ];
      for (final v in values) {
        final w = ByteWriter();
        OpCodec.writeValue(w, v);
        final got = OpCodec.readValue(ByteReader(w.takeBytes()));
        expect(got.runtimeType, v.runtimeType);
        switch ((v, got)) {
          case (IntValue a, IntValue b):
            expect(b.value, a.value);
          case (StringValue a, StringValue b):
            expect(b.value, a.value);
          case (TimestampValue a, TimestampValue b):
            expect(b.millis, a.millis);
          case (UuidValue a, UuidValue b):
            expect(b.value, a.value);
          case (UuidSetValue a, UuidSetValue b):
            expect(b.values, a.values);
          case (DateSetValue a, DateSetValue b):
            expect(b.daysSinceEpoch, a.daysSinceEpoch);
          case (BlobValue a, BlobValue b):
            expect(b.bytes, a.bytes);
          case (BoolValue a, BoolValue b):
            expect(b.value, a.value);
          default:
            break;
        }
      }
    });

    test('date set delta encoding is compact for clustered dates', () {
      final dates = <int>{for (var i = 0; i < 100; i++) 19000 + i};
      final w = ByteWriter();
      OpCodec.writeValue(w, DateSetValue(dates));
      // 100 consecutive days: tag + count + 100 small deltas (first is
      // large). Well under the 400 bytes a naive u32-per-date would cost.
      expect(w.length, lessThan(115));
    });

    test('rejects unknown value tag', () {
      final r = ByteReader(Uint8List.fromList([200, 0, 0]));
      expect(() => OpCodec.readValue(r), throwsA(isA<CorruptDataException>()));
    });
  });

  group('Segment', () {
    List<Op> sampleOps() => [
      CreateEntityOp(const Hlc(100, 0, 1), EntityKind.task, uid(1)),
      SetFieldOp(
        const Hlc(100, 1, 1),
        EntityKind.task,
        uid(1),
        TaskField.title,
        const StringValue('Buy milk'),
      ),
      SetFieldOp(
        const Hlc(100, 2, 1),
        EntityKind.task,
        uid(1),
        TaskField.isCompleted,
        const BoolValue(false),
      ),
      DeleteEntityOp(const Hlc(101, 0, 1), EntityKind.tag, uid(9)),
      SetOrderOp(
        const Hlc(102, 0, 1),
        OrderScope(EntityKind.task, uid(5), 0),
        [uid(1), uid(2)],
      ),
      MoveWithinOrderOp(
        const Hlc(103, 0, 1),
        OrderScope(EntityKind.task, uid(5), 0),
        uid(2),
        uid(1),
      ),
    ];

    test('round-trips all op kinds', () {
      final seg = Segment.fromOps(sampleOps(), 1);
      final decoded = Segment.decode(seg.encode());
      expect(decoded.ops.length, seg.ops.length);
      expect(decoded.deviceId, 1);
      expect(decoded.minHlc, const Hlc(100, 0, 1));
      expect(decoded.maxHlc, const Hlc(103, 0, 1));

      final a = decoded.ops[1] as SetFieldOp;
      expect((a.value as StringValue).value, 'Buy milk');
      final order = decoded.ops[4] as SetOrderOp;
      expect(order.ids, [uid(1), uid(2)]);
      expect(order.scope.scopeId, uid(5));
      final move = decoded.ops[5] as MoveWithinOrderOp;
      expect(move.afterId, uid(1));
    });

    test('handles null afterId (move to head)', () {
      final seg = Segment.fromOps([
        MoveWithinOrderOp(
          const Hlc(1, 0, 1),
          OrderScope(EntityKind.task, uid(5), 0),
          uid(2),
          null,
        ),
      ], 1);
      final move = Segment.decode(seg.encode()).ops.first as MoveWithinOrderOp;
      expect(move.afterId, isNull);
    });

    test('empty segment round-trips', () {
      final decoded = Segment.decode(Segment.fromOps([], 7).encode());
      expect(decoded.ops, isEmpty);
      expect(decoded.deviceId, 7);
    });

    test('peek reads header without decoding ops', () {
      final bytes = Segment.fromOps(sampleOps(), 42).encode();
      final head = Segment.peek(bytes);
      expect(head.deviceId, 42);
      expect(head.opCount, 6);
      expect(head.maxHlc, const Hlc(103, 0, 1));
    });

    test('rejects corrupted bytes', () {
      final bytes = Segment.fromOps(sampleOps(), 1).encode();
      for (final i in [0, 5, bytes.length ~/ 2, bytes.length - 6]) {
        final bad = Uint8List.fromList(bytes);
        bad[i] ^= 0xFF;
        expect(
          () => Segment.decode(bad),
          throwsA(isA<CorruptDataException>()),
          reason: 'flip at $i',
        );
      }
    });

    test('rejects truncation', () {
      final bytes = Segment.fromOps(sampleOps(), 1).encode();
      expect(
        () => Segment.decode(Uint8List.sublistView(bytes, 0, bytes.length - 8)),
        throwsA(isA<CorruptDataException>()),
      );
    });
  });

  group('Chunk', () {
    Chunk sample() {
      final e1 =
          ReplicatedEntity(
            kind: EntityKind.task,
            id: uid(1),
            createdAt: const Hlc(10, 0, 1),
          )
            ..setField(
              TaskField.title,
              const StringValue('Shared Name'),
              const Hlc(11, 0, 1),
            )
            ..setField(
              TaskField.isCompleted,
              const BoolValue(true),
              const Hlc(12, 0, 1),
            )
            ..setField(
              TaskField.tagIds,
              UuidSetValue({uid(4)}),
              const Hlc(13, 0, 1),
            );
      final e2 =
          ReplicatedEntity(
            kind: EntityKind.list,
            id: uid(2),
            createdAt: const Hlc(10, 0, 1),
          )..setField(
            ListField.name,
            const StringValue('Shared Name'),
            const Hlc(14, 0, 1),
          );
      final e3 = ReplicatedEntity(
        kind: EntityKind.tag,
        id: uid(3),
        createdAt: const Hlc(9, 0, 1),
        deletedAt: const Hlc(20, 0, 2),
      );
      return Chunk.build([e1, e2, e3], {
        OrderScope(EntityKind.task, uid(2), 0): OrderSnapshot(
          baseline: [uid(1), uid(5)],
          baselineHlc: const Hlc(15, 0, 1),
          moves: const [],
        ),
      });
    }

    test('round-trips entities, tombstones and orders', () {
      final decoded = Chunk.decode(sample().encode());
      expect(decoded.entities.length, 3);
      expect(decoded.maxHlc, const Hlc(20, 0, 2));

      final t = decoded.entities.firstWhere((e) => e.id == uid(1));
      expect(t.stringField(TaskField.title), 'Shared Name');
      expect(t.boolField(TaskField.isCompleted), isTrue);
      expect(t.uuidSetField(TaskField.tagIds), {uid(4)});
      expect(t.fields[TaskField.title]!.hlc, const Hlc(11, 0, 1));

      final tag = decoded.entities.firstWhere((e) => e.id == uid(3));
      expect(tag.isDeleted, isTrue);
      expect(tag.deletedAt, const Hlc(20, 0, 2));

      final order =
          decoded.orderSnapshots[OrderScope(EntityKind.task, uid(2), 0)]!;
      expect(order.baseline, [uid(1), uid(5)]);
      expect(order.baselineHlc, const Hlc(15, 0, 1));
    });

    test('string pool deduplicates repeated strings', () {
      // Compare 200 entities sharing one name against 200 with distinct
      // names. The shared case must pay for the string once, so the
      // difference is ~199 copies of it.
      const name = 'A fairly long shared list name for pooling';
      int sizeFor({required bool distinct}) {
        final entities = List.generate(
          200,
          (i) =>
              ReplicatedEntity(
                kind: EntityKind.task,
                id: uid(i),
                createdAt: const Hlc(1, 0, 1),
              )..setField(
                TaskField.title,
                StringValue(distinct ? '$name $i' : name),
                const Hlc(2, 0, 1),
              ),
        );
        return Chunk.build(entities, {}).encode().length;
      }

      final pooled = sizeFor(distinct: false);
      final unpooled = sizeFor(distinct: true);
      expect(
        pooled,
        lessThan(unpooled ~/ 1.8),
        reason: 'pooling 200 copies of one string should roughly halve size',
      );
      // Irreducible per-entity cost is a 16-byte uuid, two 12-byte HLCs and
      // a few varints; anything near that means the pool is working.
      expect(pooled / 200, lessThan(50));
    });

    test('rejects corruption', () {
      final bytes = sample().encode();
      final bad = Uint8List.fromList(bytes);
      bad[bytes.length ~/ 2] ^= 0xFF;
      expect(() => Chunk.decode(bad), throwsA(isA<CorruptDataException>()));
    });

    test('empty chunk round-trips', () {
      final decoded = Chunk.decode(Chunk.build([], {}).encode());
      expect(decoded.entities, isEmpty);
      expect(decoded.orderSnapshots, isEmpty);
    });
  });

  group('Manifest', () {
    test('round-trips and stays small', () {
      const m = Manifest(
        baseGen: 3,
        nextSeq: 17,
        chunks: [
          ChunkRef(shard: 0, gen: 3, size: 4096, maxHlc: Hlc(99, 0, 1), crc: 0x1234),
          ChunkRef(shard: 5, gen: 3, size: 8192, maxHlc: Hlc(98, 0, 1), crc: 0xABCD),
        ],
        segments: [
          SegmentRef(
            seq: 15,
            size: 120,
            minHlc: Hlc(100, 0, 1),
            maxHlc: Hlc(101, 0, 1),
            deviceId: 7,
          ),
          SegmentRef(
            seq: 16,
            size: 64,
            minHlc: Hlc(102, 0, 2),
            maxHlc: Hlc(102, 5, 2),
            deviceId: 8,
          ),
        ],
      );
      final bytes = m.encode();
      expect(
        bytes.length,
        lessThan(200),
        reason: 'manifest is read on every sync; keep it tiny',
      );

      final d = Manifest.decode(bytes);
      expect(d.baseGen, 3);
      expect(d.nextSeq, 17);
      expect(d.chunks.length, 2);
      expect(d.chunks[1].shard, 5);
      expect(d.chunks[1].path, '/base/5.3.tc');
      expect(d.chunks[1].crc, 0xABCD);
      expect(d.segments[0].deviceId, 7);
      expect(d.segments[0].path, '/seg/00000015-00000007.ts');
      expect(d.coldDownloadBytes, 4096 + 8192 + 120 + 64);
    });

    test('empty manifest round-trips', () {
      final d = Manifest.decode(Manifest.empty().encode());
      expect(d.baseGen, 0);
      expect(d.nextSeq, 0);
      expect(d.chunks, isEmpty);
    });

    test('rejects corruption', () {
      final bytes = Manifest.empty().encode();
      final bad = Uint8List.fromList(bytes);
      bad[4] ^= 0xFF;
      expect(() => Manifest.decode(bad), throwsA(isA<CorruptDataException>()));
    });
  });

  group('fuzz', () {
    test('random ops survive a segment round-trip', () {
      final rnd = Random(0xC0FFEE);
      OpValue randomValue() {
        switch (rnd.nextInt(9)) {
          case 0:
            return const NullValue();
          case 1:
            return BoolValue(rnd.nextBool());
          case 2:
            return IntValue(rnd.nextInt(1 << 32) - (1 << 31));
          case 3:
            return StringValue(
              String.fromCharCodes(
                List.generate(rnd.nextInt(40), (_) => 32 + rnd.nextInt(2000)),
              ),
            );
          case 4:
            return TimestampValue(rnd.nextInt(1 << 31) * 1000);
          case 5:
            return UuidValue(uid(rnd.nextInt(1000)));
          case 6:
            return UuidSetValue({
              for (var i = 0; i < rnd.nextInt(6); i++) uid(rnd.nextInt(1000)),
            });
          case 7:
            return DateSetValue({
              for (var i = 0; i < rnd.nextInt(10); i++) rnd.nextInt(30000),
            });
          default:
            return BlobValue(
              Uint8List.fromList(
                List.generate(rnd.nextInt(20), (_) => rnd.nextInt(256)),
              ),
            );
        }
      }

      for (var iter = 0; iter < 300; iter++) {
        final ops = <Op>[];
        for (var i = 0; i < 1 + rnd.nextInt(25); i++) {
          // nextInt caps at 2^32, so build a 48-bit physical from parts.
          final hlc = Hlc(
            rnd.nextInt(0xFFFFFF) * 0x1000000 + rnd.nextInt(0xFFFFFF),
            rnd.nextInt(0xFFFF),
            rnd.nextInt(0xFFFFFFF),
          );
          final kind = EntityKind.values[rnd.nextInt(EntityKind.values.length)];
          switch (rnd.nextInt(5)) {
            case 0:
              ops.add(CreateEntityOp(hlc, kind, uid(rnd.nextInt(500))));
            case 1:
              ops.add(
                SetFieldOp(
                  hlc,
                  kind,
                  uid(rnd.nextInt(500)),
                  rnd.nextInt(9),
                  randomValue(),
                ),
              );
            case 2:
              ops.add(DeleteEntityOp(hlc, kind, uid(rnd.nextInt(500))));
            case 3:
              ops.add(
                SetOrderOp(
                  hlc,
                  OrderScope(kind, uid(rnd.nextInt(10)), rnd.nextInt(2)),
                  List.generate(
                    rnd.nextInt(30),
                    (_) => uid(rnd.nextInt(500)),
                  ),
                ),
              );
            default:
              ops.add(
                MoveWithinOrderOp(
                  hlc,
                  OrderScope(kind, uid(rnd.nextInt(10)), rnd.nextInt(2)),
                  uid(rnd.nextInt(500)),
                  rnd.nextBool() ? uid(rnd.nextInt(500)) : null,
                ),
              );
          }
        }
        final decoded = Segment.decode(Segment.fromOps(ops, iter).encode());
        expect(decoded.ops.length, ops.length, reason: 'iteration $iter');
        for (var i = 0; i < ops.length; i++) {
          expect(decoded.ops[i].hlc, ops[i].hlc, reason: 'iter $iter op $i');
          expect(decoded.ops[i].runtimeType, ops[i].runtimeType);
        }
      }
    });

    test('random truncation never yields a wrong-but-valid decode', () {
      final rnd = Random(7);
      final ops = List<Op>.generate(
        20,
        (i) => SetFieldOp(
          Hlc(1000 + i, 0, 1),
          EntityKind.task,
          uid(i),
          TaskField.title,
          StringValue('task $i'),
        ),
      );
      final bytes = Segment.fromOps(ops, 1).encode();
      for (var t = 0; t < 100; t++) {
        final cut = 1 + rnd.nextInt(bytes.length - 1);
        expect(
          () => Segment.decode(Uint8List.sublistView(bytes, 0, cut)),
          throwsA(
            anyOf(
              isA<CorruptDataException>(),
              isA<ArgumentError>(),
              isA<RangeError>(),
            ),
          ),
          reason: 'truncated to $cut bytes must not decode cleanly',
        );
      }
    });
  });
}

/// Values in these tests exceed 32 bits on purpose.
///
/// This app ships to the web, where Dart ints are JavaScript doubles and the
/// bitwise operators are defined only over the low 32 bits. Any encoder
/// written with shifts silently corrupts large values there while passing
/// every test on the VM, so the wire format is exercised specifically at
/// realistic timestamp magnitudes.
void _largeValueTests() {
  group('large values (web/dart2js safety)', () {
    test('varint round-trips values far beyond 32 bits', () {
      final values = [
        0xFFFFFFFF, // 2^32-1
        0x100000000, // 2^32
        1789983327766, // a real ms timestamp
        DateTime.now().millisecondsSinceEpoch,
        DateTime.now().microsecondsSinceEpoch,
        (1 << 48) - 1,
        (1 << 52) - 1,
      ];
      final w = ByteWriter();
      for (final v in values) {
        w.varint(v);
      }
      final r = ByteReader(w.takeBytes());
      for (final v in values) {
        expect(r.varint(), v, reason: 'varint $v');
      }
    });

    test('signed varint round-trips large magnitudes both ways', () {
      final values = [
        1789983327766,
        -1789983327766,
        0x100000000,
        -0x100000000,
        (1 << 48) - 1,
        -((1 << 48) - 1),
      ];
      final w = ByteWriter();
      for (final v in values) {
        w.svarint(v);
      }
      final r = ByteReader(w.takeBytes());
      for (final v in values) {
        expect(r.svarint(), v, reason: 'svarint $v');
      }
    });

    test('Hlc round-trips real wall-clock timestamps', () {
      // 41+ bits: the exact range a shift-based encoder gets wrong.
      final values = [
        Hlc(DateTime.now().millisecondsSinceEpoch, 0, 1),
        Hlc(DateTime.now().millisecondsSinceEpoch, 0xFFFF, 0xFFFFFFFF),
        const Hlc(1789983327766, 42, 7),
        Hlc.max,
      ];
      for (final h in values) {
        final buf = Uint8List(Hlc.encodedSize);
        h.writeTo(buf, 0);
        final back = Hlc.readFrom(buf, 0);
        expect(back.physical, h.physical, reason: 'physical of $h');
        expect(back.counter, h.counter);
        expect(back.deviceId, h.deviceId);
      }
    });

    test('Hlc byte order still matches numeric order at real timestamps', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final a = Uint8List(12), b = Uint8List(12);
      Hlc(now, 0, 0).writeTo(a, 0);
      Hlc(now + 1, 0, 0).writeTo(b, 0);
      var cmp = 0;
      for (var i = 0; i < 12 && cmp == 0; i++) {
        cmp = a[i].compareTo(b[i]);
      }
      expect(cmp, lessThan(0));
    });

    test('timestamps survive a full op round-trip', () {
      final ms = DateTime.now().millisecondsSinceEpoch;
      final seg = Segment.fromOps([
        SetFieldOp(
          Hlc(ms, 1, 2),
          EntityKind.task,
          uid(1),
          TaskField.scheduledDate,
          TimestampValue(ms),
        ),
      ], 1);
      final op = Segment.decode(seg.encode()).ops.first as SetFieldOp;
      expect((op.value as TimestampValue).millis, ms);
      expect(op.hlc.physical, ms);
    });
  });
}
