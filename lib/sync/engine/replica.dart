import '../../utils/uuid128.dart';
import '../format/chunk.dart';
import '../model/entities.dart';
import '../model/hlc.dart';
import '../model/ops.dart';

/// In-memory replicated state: every entity plus every ordering array.
///
/// [apply] is the single entry point for mutation, and it is commutative,
/// associative and idempotent over ops. That is the property the whole sync
/// design rests on: two devices that have seen the same set of ops end up
/// byte-identical regardless of the order the ops arrived in, so there is no
/// "who synced last" and no clobbering.
class Replica {
  /// (kind, id) → entity. Includes tombstones; callers filter.
  final Map<(EntityKind, Uuid128), ReplicatedEntity> entities = {};

  /// Ordering state per scope.
  ///
  /// Exposed as a plain stamped array for persistence; [_orderState] holds
  /// the baseline plus the moves layered on top of it.
  Map<OrderScope, Stamped<List<Uuid128>>> get orders => {
    for (final e in _orderState.entries)
      e.key: Stamped(e.value.resolve(), e.value.stamp),
  };

  /// Ordering scopes with their baseline and outstanding moves, for
  /// persistence. Flattening to a resolved array would lose the distinction
  /// between "folded into the baseline" and "still a pending move", which
  /// peers need in order to agree on what a later move applies to.
  Map<OrderScope, OrderSnapshot> get orderSnapshots => {
    for (final e in _orderState.entries) e.key: e.value.toSnapshot(),
  };

  void loadOrderSnapshot(OrderScope scope, OrderSnapshot snap) {
    (_orderState[scope] ??= _OrderState()).mergeSnapshot(snap);
  }

  final Map<OrderScope, _OrderState> _orderState = {};

  /// Highest HLC ever applied — the replica's logical high-water mark.
  Hlc maxHlc = Hlc.zero;

  Replica();

  // ───── Queries ─────

  ReplicatedEntity? get(EntityKind kind, Uuid128 id) => entities[(kind, id)];

  /// Live (non-tombstoned) entities of one kind.
  Iterable<ReplicatedEntity> live(EntityKind kind) => entities.values
      .where((e) => e.kind == kind && !e.isDeleted);

  /// The dense ordering array for [scope], filtered to ids that still exist
  /// and are live, with any live-but-unordered ids appended.
  ///
  /// [candidates] is the authoritative membership set; the stored array is
  /// only a hint about sequence. This keeps ordering correct even when a
  /// device applies a reorder that references tasks it has not yet seen, or
  /// misses one that was added elsewhere.
  List<Uuid128> orderedIds(OrderScope scope, Set<Uuid128> candidates) {
    final stored = _orderState[scope]?.resolve() ?? const <Uuid128>[];
    final seen = <Uuid128>{};
    final out = <Uuid128>[];
    for (final id in stored) {
      if (candidates.contains(id) && seen.add(id)) {
        out.add(id);
      }
    }
    // Anything in the scope that the array does not mention goes to the end,
    // in a deterministic order so every device agrees.
    final missing = candidates.where((id) => !seen.contains(id)).toList()
      ..sort(_compareUuid);
    out.addAll(missing);
    return out;
  }

  static int _compareUuid(Uuid128 a, Uuid128 b) {
    final h = a.high.compareTo(b.high);
    return h != 0 ? h : a.low.compareTo(b.low);
  }

  // ───── Mutation ─────

  /// Apply one op. Safe to call with the same op any number of times.
  void apply(Op op) {
    if (op.hlc > maxHlc) maxHlc = op.hlc;

    switch (op) {
      case CreateEntityOp(:final kind, :final id):
        _implicit(kind, id, op.hlc).create(op.hlc);

      case SetFieldOp(:final kind, :final id, :final field, :final value):
        // A field write for an entity we have not seen creates it. Ops can
        // arrive out of order, and dropping the write would lose data.
        _implicit(kind, id, op.hlc).setField(field, value, op.hlc);

      case DeleteEntityOp(:final kind, :final id):
        _implicit(kind, id, op.hlc).delete(op.hlc);

      case SetOrderOp(:final scope, :final ids):
        (_orderState[scope] ??= _OrderState()).setBaseline(ids, op.hlc);

      case MoveWithinOrderOp(:final scope, :final id, :final afterId):
        (_orderState[scope] ??= _OrderState()).addMove(id, afterId, op.hlc);
    }
  }

  void applyAll(Iterable<Op> ops) {
    for (final op in ops) {
      apply(op);
    }
  }

  /// Fetch an entity, creating a placeholder if an op references one we have
  /// not seen yet.
  ///
  /// `createdAt` is pinned to the *smallest* HLC ever observed for the
  /// entity. Taking the first-seen HLC instead would make the field depend
  /// on delivery order, and two devices receiving the same ops by different
  /// routes would disagree — breaking convergence.
  ReplicatedEntity _implicit(EntityKind kind, Uuid128 id, Hlc hlc) {
    final key = (kind, id);
    final existing = entities[key];
    if (existing == null) {
      // Seed both lifecycle stamps at the bottom of the range. Seeding
      // `lastCreate` from this op instead would let an ordinary field write
      // or a delete masquerade as a re-create and resurrect a tombstoned
      // entity, with the outcome depending on arrival order.
      final created = ReplicatedEntity(
        kind: kind,
        id: id,
        createdAt: hlc,
        lastCreate: Hlc.zero,
      );
      entities[key] = created;
      return created;
    }
    if (hlc < existing.createdAt) existing.createdAt = hlc;
    return existing;
  }

  // ───── Snapshot / restore ─────

  /// Load a decoded [Chunk] into this replica, merging with what is here.
  void loadChunk(Chunk chunk) {
    for (final e in chunk.entities) {
      final key = (e.kind, e.id);
      final existing = entities[key];
      if (existing == null) {
        entities[key] = e;
      } else {
        // Merge field-by-field so a chunk never blindly overwrites newer
        // state already applied from a segment.
        for (final entry in e.fields.entries) {
          existing.setField(entry.key, entry.value.value, entry.value.hlc);
        }
        // Merge the raw lifecycle stamps, not the derived ones: passing the
        // derived `deletedAt` would drop a tombstone that a later re-create
        // is currently masking, and losing it would resurrect the entity on
        // any device that has not seen that re-create.
        existing.create(e.createdAt);
        existing.create(e.lastCreate);
        final d = e.rawDeletedAt;
        if (d != null) existing.delete(d);
      }
    }
    for (final entry in chunk.orderSnapshots.entries) {
      loadOrderSnapshot(entry.key, entry.value);
    }
    if (chunk.maxHlc > maxHlc) maxHlc = chunk.maxHlc;
  }

  /// Number of live entities, for diagnostics.
  int get liveCount => entities.values.where((e) => !e.isDeleted).length;
  int get tombstoneCount => entities.values.where((e) => e.isDeleted).length;
}

/// Persistable ordering state: a stamped baseline plus its unfolded moves.
class OrderSnapshot {
  final List<Uuid128> baseline;
  final Hlc baselineHlc;
  final List<({Uuid128 id, Uuid128? after, Hlc hlc})> moves;

  const OrderSnapshot({
    required this.baseline,
    required this.baselineHlc,
    required this.moves,
  });
}

/// One ordering scope: a stamped baseline array plus the moves applied over
/// it, kept so the resolved order is a pure function of the op set.
///
/// Mutating the array in place instead would make the result depend on the
/// order ops arrived in: an old move delivered late would be applied on top
/// of newer state on one device but not on another, and the two would
/// permanently disagree about the sequence.
class _OrderState {
  List<Uuid128> _baseline = const [];
  Hlc _baselineHlc = Hlc.zero;

  /// Moves newer than the baseline, keyed by the moved id so a later move of
  /// the same item supersedes an earlier one.
  final Map<Uuid128, ({Uuid128? after, Hlc hlc})> _moves = {};

  List<Uuid128>? _cache;

  Hlc get stamp {
    var hi = _baselineHlc;
    for (final m in _moves.values) {
      if (m.hlc > hi) hi = m.hlc;
    }
    return hi;
  }

  void setBaseline(List<Uuid128> ids, Hlc hlc) {
    if (hlc < _baselineHlc) return;
    _baseline = List<Uuid128>.from(ids);
    _baselineHlc = hlc;
    // Moves at or before the new baseline are already folded into it.
    _moves.removeWhere((_, m) => m.hlc <= hlc);
    _cache = null;
  }

  void addMove(Uuid128 id, Uuid128? after, Hlc hlc) {
    if (hlc <= _baselineHlc) return; // superseded by the baseline
    final existing = _moves[id];
    if (existing != null && existing.hlc >= hlc) return;
    _moves[id] = (after: after, hlc: hlc);
    _cache = null;
  }

  OrderSnapshot toSnapshot() => OrderSnapshot(
    baseline: List<Uuid128>.from(_baseline),
    baselineHlc: _baselineHlc,
    moves: [
      for (final e in _moves.entries)
        (id: e.key, after: e.value.after, hlc: e.value.hlc),
    ]..sort((a, b) => a.hlc.compareTo(b.hlc)),
  );

  void mergeSnapshot(OrderSnapshot snap) {
    setBaseline(snap.baseline, snap.baselineHlc);
    for (final m in snap.moves) {
      addMove(m.id, m.after, m.hlc);
    }
  }

  /// Baseline with every retained move replayed in HLC order.
  List<Uuid128> resolve() {
    final cached = _cache;
    if (cached != null) return cached;

    final out = List<Uuid128>.from(_baseline);
    final pending = _moves.entries.toList()
      ..sort((a, b) => a.value.hlc.compareTo(b.value.hlc));

    for (final entry in pending) {
      final id = entry.key;
      final after = entry.value.after;
      out.remove(id);
      if (after == null) {
        out.insert(0, id);
      } else {
        final idx = out.indexOf(after);
        // Anchor missing (not synced yet, or deleted): append rather than
        // drop, so a move can never lose the item.
        out.insert(idx < 0 ? out.length : idx + 1, id);
      }
    }

    _cache = out;
    return out;
  }
}
