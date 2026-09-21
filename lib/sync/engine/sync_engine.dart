import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../../utils/uuid128.dart';
import '../format/chunk.dart';
import '../format/crc32c.dart';
import '../format/manifest.dart';
import '../format/segment.dart';
import '../model/entities.dart';
import '../model/hlc.dart';
import '../model/ops.dart';
import 'remote_store.dart';
import 'replica.dart';

/// Tuning knobs for the base+log layout.
class SyncPolicy {
  /// Compact once the log has at least this many segments. Keeps the cold
  /// download from turning into "one request per segment".
  final int maxSegments;

  /// Compact once log bytes exceed this fraction of base bytes. Bounds the
  /// wasted bandwidth a fresh client pays to replay the log.
  final double maxLogRatio;

  /// Compact once the log exceeds this many bytes, regardless of ratio.
  /// Matters when the base is tiny but the log is churning.
  final int maxLogBytes;

  /// Target size for a base chunk. Shards that grow past this are split so
  /// a small edit never rewrites a huge file.
  final int targetChunkBytes;

  /// Number of shards tasks are hashed across.
  final int shardCount;

  /// Tombstones older than this (by wall time) are dropped at compaction.
  /// Must comfortably exceed how long a device can stay offline, or a stale
  /// device could resurrect a deleted task.
  final Duration tombstoneRetention;

  const SyncPolicy({
    this.maxSegments = 48,
    this.maxLogRatio = 0.25,
    this.maxLogBytes = 256 * 1024,
    this.targetChunkBytes = 192 * 1024,
    this.shardCount = 16,
    this.tombstoneRetention = const Duration(days: 180),
  });
}

/// Outcome of a [SyncEngine.sync] call, for UI and diagnostics.
class SyncReport {
  final int opsPushed;
  final int opsPulled;
  final int bytesDown;
  final int bytesUp;
  final int requests;
  final bool compacted;
  final bool casRetries;

  const SyncReport({
    this.opsPushed = 0,
    this.opsPulled = 0,
    this.bytesDown = 0,
    this.bytesUp = 0,
    this.requests = 0,
    this.compacted = false,
    this.casRetries = false,
  });

  @override
  String toString() =>
      'SyncReport(push=$opsPushed pull=$opsPulled '
      'down=${bytesDown}B up=${bytesUp}B req=$requests '
      'compacted=$compacted)';
}

/// Drives the base+segment-log protocol against a [RemoteStore].
///
/// Invariants:
/// - `/manifest` is the only mutable file, always written via CAS.
/// - Segments and base chunks are immutable once written.
/// - A segment is uploaded *before* the manifest that references it, so a
///   reader never sees a dangling reference. An orphaned segment (written
///   then CAS lost) is harmless garbage, collected later.
class SyncEngine {
  static const manifestPath = '/manifest';

  final RemoteStore store;
  final SyncPolicy policy;
  final HlcClock clock;
  final int deviceId;

  /// Segments already merged into [replica], keyed by path.
  ///
  /// Keyed by path rather than by `seq`: two devices that read the same
  /// manifest concurrently both allocate the same sequence number, so `seq`
  /// alone is not unique and would make one device silently skip the
  /// other's segment.
  final Set<String> _appliedSegments = {};

  /// Base generation currently loaded into [replica].
  int _loadedBaseGen = -1;

  /// Shards loaded into [replica], by shard → chunk identity.
  ///
  /// The identity is the exact file a shard was served from. Compaction
  /// carries unchanged shards over at their original generation, so the
  /// manifest's `baseGen` says nothing about whether a given shard's bytes
  /// changed; only this per-shard identity does.
  final Map<int, String> _loadedChunks = {};

  /// Ops made locally that are not yet on the server.
  final List<Op> _pending = [];

  /// Last manifest observed, with its rev, so the next write can CAS.
  Manifest? _manifest;
  String? _manifestRev;

  final Replica replica;

  SyncEngine({
    required this.store,
    required this.clock,
    required this.deviceId,
    Replica? replica,
    this.policy = const SyncPolicy(),
  }) : replica = replica ?? Replica();

  int get pendingOpCount => _pending.length;

  /// Ops queued for the next push, so the caller can persist them and
  /// survive a crash before the upload lands.
  List<Op> get pendingOps => List<Op>.unmodifiable(_pending);
  Manifest? get lastManifest => _manifest;

  /// Record a locally originated op: apply it immediately for a responsive
  /// UI, and queue it for the next push.
  void record(Op op) {
    replica.apply(op);
    _pending.add(op);
  }

  void recordAll(Iterable<Op> ops) {
    for (final op in ops) {
      record(op);
    }
  }

  /// Which shard an entity belongs to.
  ///
  /// Tasks are sharded by their owning list so that everything shown in one
  /// view lives in one chunk; everything else shares shard 0, which stays
  /// small and is always fetched.
  int shardFor(EntityKind kind, ReplicatedEntity? entity) {
    if (kind != EntityKind.task) return 0;
    final listId = entity?.uuidField(TaskField.listId);
    if (listId == null) return 0;
    return _shardOfUuid(listId);
  }

  /// Identity of the bytes backing a chunk ref.
  static String _chunkIdentity(ChunkRef c) => '${c.gen}:${c.crc}';

  /// Map a uuid to a shard bucket.
  ///
  /// Avalanches the id before taking it modulo the shard count. A plain
  /// modulo depends only on the low bits, so any id source whose trailing
  /// bytes are patterned — sequential ids, or anything not a true random
  /// v4 — collapses every entity into one shard and defeats the sharding.
  ///
  /// Deliberately 32-bit throughout: this app also runs on the web, where
  /// Dart ints are JavaScript doubles and 64-bit constants cannot be
  /// represented. A 64-bit mix would give different shard assignments on
  /// web and native and split one dataset across two layouts.
  int _shardOfUuid(Uuid128 id) => shardOfUuid(id, policy.shardCount);

  /// Exposed so the migration tool can reproduce the identical assignment.
  static int shardOfUuid(Uuid128 id, int shardCount) {
    final hi = id.high.toInt();
    final lo = id.low.toInt();
    // Fold all 128 bits into 32, then avalanche with murmur3's finaliser.
    var h = _mix32(hi & 0xFFFFFFFF);
    h = _mix32(h ^ ((hi >> 32) & 0xFFFFFFFF));
    h = _mix32(h ^ (lo & 0xFFFFFFFF));
    h = _mix32(h ^ ((lo >> 32) & 0xFFFFFFFF));
    return h % shardCount;
  }

  /// murmur3 fmix32.
  static int _mix32(int x) {
    var h = x & 0xFFFFFFFF;
    h ^= h >>> 16;
    h = _mul32(h, 0x85EBCA6B);
    h ^= h >>> 13;
    h = _mul32(h, 0xC2B2AE35);
    h ^= h >>> 16;
    return h;
  }

  /// 32×32 → low 32 bits, computed in 16-bit halves.
  ///
  /// A direct `a * b & 0xFFFFFFFF` overflows 2^53 for large operands, and on
  /// dart2js (where ints are doubles) the low bits are then silently wrong —
  /// giving a different shard on web than on native for the same id, which
  /// would tear one dataset across two incompatible layouts.
  static int _mul32(int a, int b) {
    final aLo = a & 0xFFFF;
    final aHi = (a >>> 16) & 0xFFFF;
    // aHi * bLo only needs its low 16 bits; they land in the high half.
    return (((aHi * (b & 0xFFFF) + aLo * ((b >>> 16) & 0xFFFF)) << 16) +
            aLo * (b & 0xFFFF)) &
        0xFFFFFFFF;
  }

  // ───────────────────────── Sync ─────────────────────────

  /// One full sync cycle: pull remote changes, push local ones, compact if
  /// the log has grown too long.
  ///
  /// Safe to call concurrently with itself only in the sense that the CAS
  /// will reject the loser; callers should serialise.
  Future<SyncReport> sync({bool allowCompaction = true}) async {
    var requests = 0;
    var bytesDown = 0;
    var bytesUp = 0;
    var pulled = 0;
    var retried = false;

    // Retry loop: losing the manifest CAS means someone else committed
    // between our read and our write, so we rebase and try again.
    for (var attempt = 0; attempt < 6; attempt++) {
      final head = await store.read(manifestPath);
      requests++;
      bytesDown += head?.bytes.length ?? 0;

      final manifest = head == null
          ? Manifest.empty()
          : Manifest.decode(head.bytes);
      _manifest = manifest;
      _manifestRev = head?.rev;

      final pullStats = await _pullInto(manifest);
      requests += pullStats.requests;
      bytesDown += pullStats.bytes;
      pulled += pullStats.ops;

      if (_pending.isEmpty) {
        // Nothing to push. Compaction may still be worthwhile.
        if (allowCompaction && _shouldCompact(manifest)) {
          final c = await _compact(manifest);
          requests += c.requests;
          bytesUp += c.bytes;
          if (c.committed) {
            return SyncReport(
              opsPulled: pulled,
              bytesDown: bytesDown,
              bytesUp: bytesUp,
              requests: requests,
              compacted: true,
              casRetries: retried,
            );
          }
          retried = true;
          continue; // lost the CAS; re-read and retry
        }
        return SyncReport(
          opsPulled: pulled,
          bytesDown: bytesDown,
          bytesUp: bytesUp,
          requests: requests,
          casRetries: retried,
        );
      }

      // Push pending ops as one new segment.
      final seq = manifest.nextSeq;
      final segment = Segment.fromOps(List<Op>.from(_pending), deviceId);
      final segBytes = segment.encode();
      final ref = SegmentRef(
        seq: seq,
        size: segBytes.length,
        minHlc: segment.minHlc,
        maxHlc: segment.maxHlc,
        deviceId: deviceId,
      );

      // Write the segment first. If the CAS below fails, this file is
      // orphaned garbage rather than a dangling manifest reference.
      await store.writeNew(ref.path, segBytes);
      requests++;
      bytesUp += segBytes.length;

      final next = manifest.copyWith(
        nextSeq: seq + 1,
        segments: [...manifest.segments, ref],
      );

      try {
        _manifestRev = await store.compareAndSwap(
          manifestPath,
          next.encode(),
          _manifestRev,
        );
        requests++;
        bytesUp += next.encode().length;
      } on CasConflict {
        // Someone committed first. Our segment is orphaned under a sequence
        // number the winner may now have claimed, so it must be gone before
        // the retry writes there again — await rather than fire-and-forget.
        retried = true;
        try {
          await store.delete(ref.path);
        } catch (_) {
          // Leaving garbage behind is survivable; a later compaction GCs it.
        }
        continue;
      }

      _manifest = next;
      _appliedSegments.add(ref.path);
      final pushed = _pending.length;
      _pending.clear();

      var compacted = false;
      if (allowCompaction && _shouldCompact(next)) {
        final c = await _compact(next);
        requests += c.requests;
        bytesUp += c.bytes;
        compacted = c.committed;
      }

      return SyncReport(
        opsPushed: pushed,
        opsPulled: pulled,
        bytesDown: bytesDown,
        bytesUp: bytesUp,
        requests: requests,
        compacted: compacted,
        casRetries: retried,
      );
    }

    throw StateError('sync: exceeded CAS retry budget');
  }

  /// Download whatever of [manifest] this replica has not yet seen and merge
  /// it in, in HLC order.
  Future<({int requests, int bytes, int ops})> _pullInto(
    Manifest manifest,
  ) async {
    var requests = 0;
    var bytes = 0;
    var ops = 0;

    // A new base generation means compaction folded log history into the
    // base, so the segments we had applied are now represented there.
    //
    // Chunk state is NOT cleared here: compaction carries unchanged shards
    // over by reference, keeping their old gen, so a per-shard check below
    // decides what actually needs refetching.
    if (manifest.baseGen != _loadedBaseGen) {
      _appliedSegments.clear();
      _loadedBaseGen = manifest.baseGen;
    }

    // Refetch a shard when the exact file backing it changed. Comparing the
    // (gen, size) pair rather than gen alone matters because a carried-over
    // chunk keeps its original gen while a rewritten one gets the new gen —
    // and a shard can be rewritten at a gen we have already seen for a
    // *different* shard.
    final wanted = <ChunkRef>[];
    for (final c in manifest.chunks) {
      if (_loadedChunks[c.shard] != _chunkIdentity(c)) wanted.add(c);
    }
    if (wanted.isNotEmpty) {
      final blobs = await store.readMany(wanted.map((c) => c.path).toList());
      requests += wanted.length;
      for (var i = 0; i < wanted.length; i++) {
        final b = blobs[i];
        if (b == null) continue;
        bytes += b.length;
        replica.loadChunk(Chunk.decode(b));
        _loadedChunks[wanted[i].shard] = _chunkIdentity(wanted[i]);
      }
    }

    // Fetch segments we have not applied.
    final missing =
        manifest.segments
            .where((s) => !_appliedSegments.contains(s.path))
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    if (missing.isNotEmpty) {
      final blobs = await store.readMany(missing.map((s) => s.path).toList());
      requests += missing.length;

      // Collect every op first, then apply in HLC order. Applying segment by
      // segment would be wrong: two devices' segments interleave in time.
      final incoming = <Op>[];
      for (var i = 0; i < missing.length; i++) {
        final b = blobs[i];
        if (b == null) continue; // GC'd mid-flight; manifest will catch up
        bytes += b.length;
        final seg = Segment.decode(b);
        incoming.addAll(seg.ops);
        _appliedSegments.add(missing[i].path);
      }
      incoming.sort((a, b) => a.hlc.compareTo(b.hlc));
      for (final op in incoming) {
        clock.observe(op.hlc);
        replica.apply(op);
      }
      ops = incoming.length;
    }

    return (requests: requests, bytes: bytes, ops: ops);
  }

  bool _shouldCompact(Manifest m) {
    if (m.segments.length >= policy.maxSegments) return true;
    final logBytes = m.segmentBytes;
    if (logBytes >= policy.maxLogBytes) return true;
    final base = m.baseBytes;
    if (base > 0 && logBytes / base >= policy.maxLogRatio) return true;
    // A store with no base at all should get one as soon as there is
    // anything to write.
    if (base == 0 && m.segments.isNotEmpty) return true;
    return false;
  }

  // ───────────────────── Compaction ─────────────────────

  /// Fold the log into a fresh base generation.
  ///
  /// Only shards whose content actually changed are rewritten; the rest are
  /// carried over by reference. That is what keeps compaction affordable at
  /// 20k+ tasks — a day of edits to one list rewrites one chunk, not the
  /// whole dataset.
  Future<({bool committed, int requests, int bytes})> _compact(
    Manifest manifest,
  ) async {
    var requests = 0;
    var bytesUp = 0;
    final newGen = manifest.baseGen + 1;

    // Group current live state by shard.
    final byShard = <int, List<ReplicatedEntity>>{};
    final cutoff = DateTime.now().subtract(policy.tombstoneRetention);
    for (final e in replica.entities.values) {
      // Only a tombstone that is actually in force (no later re-create) and
      // older than the retention window may be forgotten.
      final tomb = e.deletedAt;
      if (tomb != null && tomb.wallTime.isBefore(cutoff)) {
        continue;
      }
      final shard = shardFor(e.kind, e);
      (byShard[shard] ??= []).add(e);
    }

    // Orders live with the shard of their scope so a reorder rewrites only
    // the chunk it belongs to.
    final ordersByShard = <int, Map<OrderScope, OrderSnapshot>>{};
    for (final entry in replica.orderSnapshots.entries) {
      final scope = entry.key;
      final shard = scope.kind == EntityKind.task && scope.scopeId != _zeroUuid
          ? _shardOfUuid(scope.scopeId)
          : 0;
      (ordersByShard[shard] ??= {})[scope] = entry.value;
    }

    final shards = {...byShard.keys, ...ordersByShard.keys};
    final previous = {for (final c in manifest.chunks) c.shard: c};

    final newChunks = <ChunkRef>[];
    final writes = <Future<void>>[];

    for (final shard in shards) {
      final chunk = Chunk.build(
        byShard[shard] ?? const [],
        ordersByShard[shard] ?? const {},
      );
      final prev = previous[shard];
      final bytes = chunk.encode();
      final digest = Crc32c.compute(bytes);

      // Carry a shard over untouched only when its encoded bytes are
      // identical to what is already published.
      //
      // Comparing high-water marks instead would be wrong: an op that is new
      // to this chunk can carry an HLC *below* the chunk's existing maximum
      // (authored earlier on a device that synced later), leaving maxHlc
      // unchanged while the content differs — silently dropping the edit for
      // every other device.
      if (prev != null && prev.size == bytes.length && prev.crc == digest) {
        newChunks.add(prev);
        continue;
      }

      final ref = ChunkRef(
        shard: shard,
        gen: newGen,
        size: bytes.length,
        maxHlc: chunk.maxHlc,
        crc: digest,
      );
      newChunks.add(ref);
      bytesUp += bytes.length;
      requests++;
      writes.add(store.overwrite(ref.path, bytes));
    }

    await Future.wait(writes);

    final next = Manifest(
      baseGen: newGen,
      nextSeq: manifest.nextSeq,
      chunks: newChunks,
      segments: const [],
    );

    try {
      final encoded = next.encode();
      _manifestRev = await store.compareAndSwap(
        manifestPath,
        encoded,
        _manifestRev,
      );
      requests++;
      bytesUp += encoded.length;
    } on CasConflict {
      // Another device committed while we compacted. The chunks we just
      // wrote are under a generation nobody references — harmless garbage.
      return (committed: false, requests: requests, bytes: bytesUp);
    }

    _manifest = next;
    _loadedBaseGen = newGen;
    _loadedChunks
      ..clear()
      ..addEntries(
        newChunks.map((c) => MapEntry(c.shard, _chunkIdentity(c))),
      );
    _appliedSegments.clear();

    // Garbage-collect superseded files. Best effort: a failure here costs
    // storage, never correctness.
    final garbage = <String>[
      ...manifest.segments.map((s) => s.path),
      for (final old in manifest.chunks)
        if (!newChunks.any((n) => n.shard == old.shard && n.gen == old.gen))
          old.path,
    ];
    if (garbage.isNotEmpty) {
      // Awaited rather than fire-and-forget: the manifest no longer
      // references these files, so failing to remove them leaks storage
      // forever, and an app backgrounded mid-compaction would never retry.
      // A failure here is logged by the caller, never fatal.
      try {
        await store.deleteMany(garbage);
      } catch (_) {
        // Superseded files are unreachable; a later compaction retries.
      }
    }

    return (committed: true, requests: requests, bytes: bytesUp);
  }

  static final _zeroUuid = Uuid128.fromBytes(Uint8List(16));

  /// Cold start: load everything from scratch into an empty replica.
  Future<SyncReport> hydrate() async {
    final head = await store.read(manifestPath);
    if (head == null) {
      _manifest = Manifest.empty();
      _manifestRev = null;
      return const SyncReport(requests: 1);
    }
    final manifest = Manifest.decode(head.bytes);
    _manifest = manifest;
    _manifestRev = head.rev;
    _loadedBaseGen = -1;
    _loadedChunks.clear();
    _appliedSegments.clear();

    final stats = await _pullInto(manifest);
    return SyncReport(
      opsPulled: stats.ops,
      bytesDown: head.bytes.length + stats.bytes,
      requests: 1 + stats.requests,
    );
  }

  /// Snapshot of what has been merged, for persisting across restarts.
  ({int baseGen, Map<int, String> chunks, Set<String> segments})
  exportProgress() => (
    baseGen: _loadedBaseGen,
    chunks: Map<int, String>.from(_loadedChunks),
    segments: Set<String>.from(_appliedSegments),
  );

  /// Restore merge progress saved by [exportProgress].
  ///
  /// Without this a restart would re-download and re-apply the whole log.
  /// Re-applying is harmless (ops are idempotent) but wastes bandwidth on
  /// every launch.
  void restoreProgress({
    required int baseGen,
    required Map<int, String> chunks,
    required Set<String> segments,
  }) {
    _loadedBaseGen = baseGen;
    _loadedChunks
      ..clear()
      ..addAll(chunks);
    _appliedSegments
      ..clear()
      ..addAll(segments);
  }

  /// Seed the pending queue from ops that were persisted while offline.
  ///
  /// They are already reflected in the restored replica, so they are queued
  /// for upload without being re-applied.
  void restorePending(List<Op> ops) {
    _pending.addAll(ops);
  }

  /// Estimated cost of a cold start, for the settings screen.
  ({int files, int bytes}) coldStartCost() {
    final m = _manifest;
    if (m == null) return (files: 1, bytes: 0);
    return (
      files: 1 + m.chunks.length + m.segments.length,
      bytes: m.coldDownloadBytes,
    );
  }
}

/// Jittered exponential backoff shared by callers that retry network work.
Duration backoffDelay(int attempt, {Random? rng}) {
  final r = rng ?? Random();
  final base = min(500 * (1 << attempt), 30000);
  final jitter = (base * 0.25 * (2 * r.nextDouble() - 1)).round();
  return Duration(milliseconds: max(0, base + jitter));
}
