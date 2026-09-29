import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/utils/uuid128.dart';

void main() {
  group('Uuid128', () {
    test('bytes round-trip, including halves with the sign bit set', () {
      // 0x80.. and 0xFF.. make both Int64 halves negative, which is where a
      // byte extraction that mishandles two's complement would go wrong.
      for (final first in [0x00, 0x7F, 0x80, 0xFF]) {
        final bytes = Uint8List.fromList([
          first,
          ...List.generate(7, (i) => 0x11 * (i + 1)),
          first ^ 0x80,
          ...List.generate(7, (i) => 0xF0 - i * 3),
        ]);
        final id = Uuid128.fromBytes(bytes);
        expect(id.toBytes(), bytes);
        final hex = [
          for (final b in bytes) b.toRadixString(16).padLeft(2, '0'),
        ].join();
        expect(
          id.toString(),
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
          '${hex.substring(20)}',
        );
        expect(Uuid128.fromCompactString(id.toCompactString()), id);
      }
    });

    test('toBytes hands out a copy the caller may modify', () {
      final id = Uuid128.generateV4();
      final expected = Uint8List.fromList(id.toBytes());
      id.toBytes().fillRange(0, 16, 0);
      expect(id.toBytes(), expected);
    });

    test('equal ids hash equally', () {
      final a = Uuid128.generateV4();
      final b = Uuid128.fromBytes(a.toBytes());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
      expect({a: 1}[b], 1);
    });
  });
}
