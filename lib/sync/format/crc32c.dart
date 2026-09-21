import 'dart:typed_data';

/// CRC-32C (Castagnoli). Guards every stored block against truncation and
/// bit-rot; Dropbox can hand back a partial body on a flaky connection and
/// we must never replay a half-written segment as if it were valid.
class Crc32c {
  static final Uint32List _table = _buildTable();

  static Uint32List _buildTable() {
    final table = Uint32List(256);
    const poly = 0x82F63B78;
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ poly : crc >> 1;
      }
      table[i] = crc;
    }
    return table;
  }

  static int compute(Uint8List data, [int start = 0, int? end]) {
    final stop = end ?? data.length;
    var crc = 0xFFFFFFFF;
    for (var i = start; i < stop; i++) {
      crc = _table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
