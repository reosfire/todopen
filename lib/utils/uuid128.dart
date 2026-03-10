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
      throw FormatException('Compact UUID string must be exactly 22 characters long');
    }

    return Uuid128.fromBytes(base64Url.decode("$compactString=="));
  }

  static Uuid128 generateV4() {
    final uuid = _uuid.v4buffer(Uint8List(16));
    return Uuid128.fromBytes(Uint8List.fromList(uuid));
  }

  Uint8List toBytes() {
    final bytes = Uint8List(16);

    for (int i = 0; i < 8; i++) {
      bytes[i] = ((high >> (56 - 8 * i)) & 0xFF).toInt();
    }

    for (int i = 0; i < 8; i++) {
      bytes[i + 8] = ((low >> (56 - 8 * i)) & 0xFF).toInt();
    }

    return bytes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Uuid128) return false;
    return high == other.high && low == other.low;
  }

  @override
  int get hashCode => high.hashCode ^ low.hashCode;

  String toCompactString() {
    return base64Url.encode(toBytes()).substring(0, 22);
  }

  @override
  String toString() {
    return Uuid.unparse(toBytes());
  }
}
