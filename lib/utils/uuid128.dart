import 'dart:typed_data';
import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Uuid128 {
  final Int64 high;
  final Int64 low;

  Uuid128(this.high, this.low);

  factory Uuid128.fromBytes(Uint8List bytes) {
    if (bytes.length != 16) {
      throw ArgumentError('UUID byte array must be 16 bytes long');
    }

    Int64 h = Int64.ZERO;
    Int64 l = Int64.ZERO;

    for (int i = 0; i < 8; i++) {
      h = (h << 8) | Int64(bytes[i]);
    }

    for (int i = 0; i < 8; i++) {
      l = (l << 8) | Int64(bytes[i + 8]);
    }

    return Uuid128(h, l);
  }

  factory Uuid128.fromString(String uuidString) {
    return Uuid128.fromBytes(Uuid.parseAsByteList(uuidString));
  }

  factory Uuid128.fromCompactString(String compactString) {
    if (compactString.length != 22) {
      throw FormatException(
        'Compact UUID string must be exactly 22 characters long',
      );
    }

    return Uuid128.fromBytes(base64Url.decode("$compactString=="));
  }

  static Uuid128 generateV4() {
    final uuid = _uuid.v4buffer(Uint8List(16));
    return Uuid128.fromBytes(Uint8List.fromList(uuid));
  }

  /// Big-endian bytes, computed once. [Int64] shifts allocate on the web,
  /// and ids are encoded on every local save, so this is on a hot path.
  late final Uint8List _bytes = _computeBytes();

  Uint8List _computeBytes() {
    final bytes = Uint8List(16);
    // Int64.toBytes is little-endian and works on the limbs directly, which
    // is far cheaper than eight shift-and-mask Int64 ops per half.
    final h = high.toBytes();
    final l = low.toBytes();
    for (int i = 0; i < 8; i++) {
      bytes[i] = h[7 - i];
      bytes[i + 8] = l[7 - i];
    }
    return bytes;
  }

  /// A fresh copy, so a caller writing into it cannot corrupt the cache.
  Uint8List toBytes() => Uint8List.fromList(_bytes);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Uuid128) return false;
    return high == other.high && low == other.low;
  }

  // Ids key most maps in the app; Int64.hashCode is not free on the web.
  @override
  late final int hashCode = high.hashCode ^ low.hashCode;

  String toCompactString() {
    return base64Url.encode(_bytes).substring(0, 22);
  }

  /// Cached: widgets compare ids by string while building every row.
  late final String _string = Uuid.unparse(_bytes);

  @override
  String toString() => _string;
}
