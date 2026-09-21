import 'byte_io.dart';

/// Deduplicating string table.
///
/// List names, tag names and repeated notes recur across thousands of
/// entities. Interning them turns each repeat into a 1-2 byte index.
class StringPoolBuilder {
  final Map<String, int> _index = {};
  final List<String> _strings = [];

  /// Intern [s] and return its index.
  int intern(String s) {
    final existing = _index[s];
    if (existing != null) return existing;
    final id = _strings.length;
    _index[s] = id;
    _strings.add(s);
    return id;
  }

  int get length => _strings.length;

  void writeTo(ByteWriter w) {
    w.varint(_strings.length);
    for (final s in _strings) {
      w.str(s);
    }
  }
}

class StringPool {
  final List<String> strings;
  const StringPool(this.strings);

  String operator [](int i) {
    if (i < 0 || i >= strings.length) {
      throw CorruptDataException('string pool index $i out of range');
    }
    return strings[i];
  }

  static StringPool readFrom(ByteReader r) {
    final n = r.varint();
    // A corrupt count must not make us preallocate gigabytes; the reader's
    // bounds checks will trip first because each entry consumes >=1 byte.
    if (n > r.remaining) {
      throw CorruptDataException('string pool count $n exceeds buffer');
    }
    final out = List<String>.generate(n, (_) => r.str(), growable: false);
    return StringPool(out);
  }
}
