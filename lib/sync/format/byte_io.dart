import 'dart:convert';
import 'dart:typed_data';

/// Thrown when a buffer is malformed, truncated, or fails a checksum.
class CorruptDataException implements Exception {
  final String message;
  final int? offset;
  const CorruptDataException(this.message, [this.offset]);
  @override
  String toString() =>
      'CorruptDataException: $message${offset != null ? ' at $offset' : ''}';
}

/// Growable little-endian byte sink.
///
/// Little-endian throughout (except HLC, which is big-endian so that byte
/// order matches sort order) because every platform we target is LE, so
/// fixed-width reads are free.
class ByteWriter {
  Uint8List _buf;
  int _len = 0;

  ByteWriter([int initialCapacity = 256])
    : _buf = Uint8List(initialCapacity < 16 ? 16 : initialCapacity);

  int get length => _len;

  void _ensure(int extra) {
    final needed = _len + extra;
    if (needed <= _buf.length) return;
    var cap = _buf.length;
    while (cap < needed) {
      cap *= 2;
    }
    final next = Uint8List(cap);
    next.setRange(0, _len, _buf);
    _buf = next;
  }

  void u8(int v) {
    _ensure(1);
    _buf[_len++] = v & 0xFF;
  }

  void u16(int v) {
    _ensure(2);
    _buf[_len++] = v & 0xFF;
    _buf[_len++] = (v >> 8) & 0xFF;
  }

  void u32(int v) {
    _ensure(4);
    _buf[_len++] = v & 0xFF;
    _buf[_len++] = (v >> 8) & 0xFF;
    _buf[_len++] = (v >> 16) & 0xFF;
    _buf[_len++] = (v >> 24) & 0xFF;
  }

  /// LEB128 unsigned varint. Values below 128 cost a single byte, which is
  /// the common case for lengths, counts and indices.
  ///
  /// Uses division rather than `>>= 7` so values above 2^32 survive on
  /// dart2js, where bitwise operators truncate to 32 bits.
  void varint(int v) {
    if (v < 0) {
      throw ArgumentError('varint requires non-negative, got $v');
    }
    while (v >= 0x80) {
      u8((v % 0x80) | 0x80);
      v = v ~/ 0x80;
    }
    u8(v);
  }

  /// Zigzag-encoded signed varint: small magnitudes stay small either sign.
  ///
  /// Written arithmetically rather than as `(v << 1) ^ (v >> 63)`: on
  /// dart2js ints are doubles and bitwise operators only cover the low 32
  /// bits, so the shift-based form corrupts any value beyond 32 bits —
  /// which includes every millisecond timestamp we store.
  void svarint(int v) => varint(v < 0 ? (-v * 2) - 1 : v * 2);

  void bytes(Uint8List src) {
    _ensure(src.length);
    _buf.setRange(_len, _len + src.length, src);
    _len += src.length;
  }

  /// Length-prefixed UTF-8.
  void str(String s) {
    if (s.isEmpty) {
      varint(0);
      return;
    }
    final encoded = utf8.encode(s);
    varint(encoded.length);
    bytes(encoded);
  }

  /// Overwrite 4 bytes at an earlier position — used to backfill lengths and
  /// offsets once the size of a section is known.
  void patchU32(int position, int v) {
    if (position + 4 > _len) {
      throw StateError('patchU32 out of range');
    }
    _buf[position] = v & 0xFF;
    _buf[position + 1] = (v >> 8) & 0xFF;
    _buf[position + 2] = (v >> 16) & 0xFF;
    _buf[position + 3] = (v >> 24) & 0xFF;
  }

  /// Reserve 4 bytes and return the position, for later [patchU32].
  int reserveU32() {
    final pos = _len;
    u32(0);
    return pos;
  }

  /// View of written bytes without copying. Invalid after further writes.
  Uint8List viewBytes() => Uint8List.sublistView(_buf, 0, _len);

  Uint8List takeBytes() => Uint8List.sublistView(_buf, 0, _len);
}

/// Bounds-checked little-endian byte source.
class ByteReader {
  final Uint8List buf;
  int _pos;
  final int _end;

  ByteReader(this.buf, [int start = 0, int? end])
    : _pos = start,
      _end = end ?? buf.length;

  int get position => _pos;
  set position(int v) {
    if (v < 0 || v > _end) {
      throw CorruptDataException('seek out of range: $v');
    }
    _pos = v;
  }

  int get remaining => _end - _pos;
  bool get isAtEnd => _pos >= _end;

  void _need(int n) {
    if (_pos + n > _end) {
      throw CorruptDataException(
        'truncated: need $n byte(s), have $remaining',
        _pos,
      );
    }
  }

  int u8() {
    _need(1);
    return buf[_pos++];
  }

  int u16() {
    _need(2);
    return buf[_pos++] | (buf[_pos++] << 8);
  }

  int u32() {
    _need(4);
    return (buf[_pos++] |
            (buf[_pos++] << 8) |
            (buf[_pos++] << 16) |
            (buf[_pos++] << 24)) &
        0xFFFFFFFF;
  }

  /// Mirrors [ByteWriter.varint]; accumulates by multiplication so values
  /// wider than 32 bits decode correctly on dart2js.
  int varint() {
    var result = 0;
    var scale = 1;
    var bytes = 0;
    while (true) {
      _need(1);
      final b = buf[_pos++];
      result += (b & 0x7F) * scale;
      if (b < 0x80) return result;
      scale *= 0x80;
      if (++bytes > 8) {
        throw CorruptDataException('varint too long', _pos);
      }
    }
  }

  int svarint() {
    final v = varint();
    return v.isOdd ? -((v + 1) ~/ 2) : v ~/ 2;
  }

  Uint8List bytesView(int n) {
    _need(n);
    final view = Uint8List.sublistView(buf, _pos, _pos + n);
    _pos += n;
    return view;
  }

  Uint8List bytesCopy(int n) {
    _need(n);
    final copy = Uint8List.fromList(Uint8List.sublistView(buf, _pos, _pos + n));
    _pos += n;
    return copy;
  }

  String str() {
    final n = varint();
    if (n == 0) return '';
    _need(n);
    final s = utf8.decode(
      Uint8List.sublistView(buf, _pos, _pos + n),
      allowMalformed: true,
    );
    _pos += n;
    return s;
  }

  void skip(int n) {
    _need(n);
    _pos += n;
  }
}
