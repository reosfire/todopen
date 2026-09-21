import 'dart:typed_data';

/// Hybrid Logical Clock.
///
/// Wall clocks disagree between devices; pure logical clocks cannot be
/// compared to real time. An HLC keeps a physical component that tracks
/// wall time when it can, and a logical counter that guarantees strict
/// monotonicity when it cannot.
///
/// Packed into 12 bytes:
///   [0..5]  physical  – 48-bit ms since epoch (good until year 10889)
///   [6..7]  counter   – 16-bit logical tiebreak
///   [8..11] deviceId  – 32-bit, breaks remaining ties deterministically
///
/// Total order is (physical, counter, deviceId) lexicographically. Two
/// distinct devices can never produce the same HLC, so "last writer wins"
/// is always decidable and always agrees on every device.
class Hlc implements Comparable<Hlc> {
  static const encodedSize = 12;

  /// Milliseconds since epoch, clamped to 48 bits.
  final int physical;

  /// Logical counter, incremented when physical time does not advance.
  final int counter;

  /// Stable per-installation id.
  final int deviceId;

  const Hlc(this.physical, this.counter, this.deviceId);

  static const zero = Hlc(0, 0, 0);

  /// Largest representable value; used as a "not yet seen" sentinel for mins.
  static const max = Hlc(0xFFFFFFFFFFFF, 0xFFFF, 0xFFFFFFFF);

  @override
  int compareTo(Hlc other) {
    if (physical != other.physical) {
      return physical < other.physical ? -1 : 1;
    }
    if (counter != other.counter) {
      return counter < other.counter ? -1 : 1;
    }
    if (deviceId != other.deviceId) {
      return deviceId < other.deviceId ? -1 : 1;
    }
    return 0;
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
  bool operator <=(Hlc other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      physical == other.physical &&
      counter == other.counter &&
      deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(physical, counter, deviceId);

  DateTime get wallTime => DateTime.fromMillisecondsSinceEpoch(physical);

  void writeTo(Uint8List out, int offset) {
    // 48-bit physical, big-endian so byte order matches numeric order.
    //
    // Split into two 24-bit halves via division rather than shifting: on
    // dart2js an int is a double and bitwise ops are defined only on the low
    // 32 bits, so `physical >> 40` silently yields garbage for any real
    // millisecond timestamp (which needs 41 bits).
    final hi = physical ~/ 0x1000000; // top 24 bits
    final lo = physical % 0x1000000; // bottom 24 bits
    out[offset] = (hi >> 16) & 0xFF;
    out[offset + 1] = (hi >> 8) & 0xFF;
    out[offset + 2] = hi & 0xFF;
    out[offset + 3] = (lo >> 16) & 0xFF;
    out[offset + 4] = (lo >> 8) & 0xFF;
    out[offset + 5] = lo & 0xFF;
    out[offset + 6] = (counter >> 8) & 0xFF;
    out[offset + 7] = counter & 0xFF;
    out[offset + 8] = (deviceId >> 24) & 0xFF;
    out[offset + 9] = (deviceId >> 16) & 0xFF;
    out[offset + 10] = (deviceId >> 8) & 0xFF;
    out[offset + 11] = deviceId & 0xFF;
  }

  static Hlc readFrom(Uint8List src, int offset) {
    // Reassemble the two 24-bit halves with multiplication, for the same
    // reason writeTo splits them: shifts past bit 31 are not portable.
    final hi =
        (src[offset] << 16) | (src[offset + 1] << 8) | src[offset + 2];
    final lo =
        (src[offset + 3] << 16) | (src[offset + 4] << 8) | src[offset + 5];
    final physical = hi * 0x1000000 + lo;
    final counter = (src[offset + 6] << 8) | src[offset + 7];
    final deviceId =
        ((src[offset + 8] << 24) |
                (src[offset + 9] << 16) |
                (src[offset + 10] << 8) |
                src[offset + 11]) &
            0xFFFFFFFF;
    return Hlc(physical, counter, deviceId);
  }

  @override
  String toString() =>
      'Hlc($physical.$counter@${deviceId.toRadixString(16)})';
}

/// Generates HLC timestamps for one device.
///
/// [now] is injectable so tests can simulate clock skew and jumps.
class HlcClock {
  final int deviceId;
  final int Function() _now;

  int _lastPhysical = 0;
  int _counter = 0;

  /// Rejects remote timestamps that claim to be absurdly far in the future,
  /// which would otherwise drag this device's clock forward permanently.
  static const maxDriftMs = 24 * 60 * 60 * 1000;

  HlcClock({required this.deviceId, int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Issue a new timestamp for a locally originated event.
  Hlc issue() {
    final wall = _now();
    if (wall > _lastPhysical) {
      _lastPhysical = wall;
      _counter = 0;
    } else {
      // Clock went backwards or did not tick; stay monotonic via counter.
      _counter++;
      if (_counter > 0xFFFF) {
        _lastPhysical++;
        _counter = 0;
      }
    }
    return Hlc(_lastPhysical, _counter, deviceId);
  }

  /// Fold an observed remote timestamp into this clock so that any event
  /// we issue afterwards sorts strictly after it (causality).
  void observe(Hlc remote) {
    final wall = _now();
    if (remote.physical > wall + maxDriftMs) {
      // Implausible future timestamp – do not let it poison our clock.
      return;
    }
    if (remote.physical > _lastPhysical) {
      _lastPhysical = remote.physical;
      _counter = remote.counter;
    } else if (remote.physical == _lastPhysical && remote.counter > _counter) {
      _counter = remote.counter;
    }
  }
}
