import 'dart:typed_data';

import '../../utils/uuid128.dart';
import 'hlc.dart';
import 'ops.dart';

/// A value together with the HLC of the write that produced it.
///
/// Per-field stamping is what allows two devices to edit two different
/// fields of one task and both keep their change.
class Stamped<T> {
  final T value;
  final Hlc hlc;
  const Stamped(this.value, this.hlc);

  /// Keep whichever write is later in HLC order.
  Stamped<T> mergeWith(Stamped<T> other) =>
      other.hlc > hlc ? other : this;
}

/// A replicated entity: a bag of stamped fields plus lifecycle stamps.
///
/// Storing fields generically (rather than as typed Dart members) keeps the
/// merge engine schema-agnostic — adding a field later needs no engine
/// change, only a new field id.
class ReplicatedEntity {
  final EntityKind kind;
  final Uuid128 id;

  /// field id → stamped value.
  final Map<int, Stamped<OpValue>> fields;

  /// Earliest creation stamp seen, and the latest explicit re-create.
  ///
  /// Both are tracked because liveness is decided by comparing the newest
  /// create against the newest delete. Clearing the tombstone on the spot
  /// instead would make the result depend on which op arrived first.
  Hlc createdAt;
  Hlc _lastCreate;

  /// Latest delete stamp, or null if never deleted.
  Hlc? _deletedAt;

  ReplicatedEntity({
    required this.kind,
    required this.id,
    Map<int, Stamped<OpValue>>? fields,
    required this.createdAt,
    Hlc? deletedAt,
    Hlc? lastCreate,
  }) : fields = fields ?? {},
       _deletedAt = deletedAt,
       _lastCreate = lastCreate ?? createdAt;

  /// The tombstone stamp, or null when the entity is live.
  ///
  /// A delete is in force only while no *later* create has been seen, so
  /// this is derived rather than stored directly.
  Hlc? get deletedAt {
    final d = _deletedAt;
    if (d == null) return null;
    return _lastCreate > d ? null : d;
  }

  /// Raw delete stamp regardless of any later re-create; persistence needs
  /// it so the tombstone is not silently dropped on reload.
  Hlc? get rawDeletedAt => _deletedAt;
  Hlc get lastCreate => _lastCreate;

  bool get isDeleted => deletedAt != null;

  /// Apply a field write, keeping the later of the two.
  void setField(int field, OpValue value, Hlc hlc) {
    final existing = fields[field];
    if (existing == null || hlc > existing.hlc) {
      fields[field] = Stamped(value, hlc);
    }
  }

  /// Record a delete. Keeps the newest one seen.
  void delete(Hlc hlc) {
    final d = _deletedAt;
    if (d == null || hlc > d) _deletedAt = hlc;
  }

  /// Record a create. Keeps the earliest for [createdAt] and the newest for
  /// deciding whether it outranks a tombstone.
  void create(Hlc hlc) {
    if (hlc < createdAt) createdAt = hlc;
    if (hlc > _lastCreate) _lastCreate = hlc;
  }

  // ───── Typed accessors ─────

  OpValue? raw(int field) => fields[field]?.value;

  String stringField(int field, [String fallback = '']) {
    final v = raw(field);
    return v is StringValue ? v.value : fallback;
  }

  bool boolField(int field, [bool fallback = false]) {
    final v = raw(field);
    return v is BoolValue ? v.value : fallback;
  }

  int? intFieldOrNull(int field) {
    final v = raw(field);
    return v is IntValue ? v.value : null;
  }

  int intField(int field, [int fallback = 0]) =>
      intFieldOrNull(field) ?? fallback;

  DateTime? dateField(int field) {
    final v = raw(field);
    return v is TimestampValue
        ? DateTime.fromMillisecondsSinceEpoch(v.millis)
        : null;
  }

  Uuid128? uuidField(int field) {
    final v = raw(field);
    return v is UuidValue ? v.value : null;
  }

  Set<Uuid128> uuidSetField(int field) {
    final v = raw(field);
    return v is UuidSetValue ? v.values : const {};
  }

  Set<int> dateSetField(int field) {
    final v = raw(field);
    return v is DateSetValue ? v.daysSinceEpoch : const {};
  }

  Uint8List? blobField(int field) {
    final v = raw(field);
    return v is BlobValue ? v.bytes : null;
  }

  /// Largest HLC anywhere in this entity — used to compute a chunk's
  /// high-water mark cheaply.
  Hlc get maxHlc {
    var hi = createdAt;
    if (_lastCreate > hi) hi = _lastCreate;
    final d = _deletedAt;
    if (d != null && d > hi) hi = d;
    for (final s in fields.values) {
      if (s.hlc > hi) hi = s.hlc;
    }
    return hi;
  }
}
