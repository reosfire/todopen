A todo app written with flutter supporting web and mobile platforms. Supports free cloud sync via dropbox.

## Features

- **Tasks** — create, edit, reorder, and complete tasks with drag-and-drop support
- **Lists & Folders** — organize tasks into lists, group lists into collapsible folders
- **Tags** — label tasks with colored tags for quick filtering
- **Recurring Tasks** — set daily, weekly, monthly, or yearly recurrence rules
- **Smart Lists** — auto-filtered views like *Today*, *Upcoming*, and *All Tasks*
- **Search** — across titles, notes, tags and list names
- **Dropbox Sync** — offline-first CRDT sync with conflict-free merging
- **Dark Mode** — follows system theme automatically

## Sync architecture

Sync is offline-first and conflict-free. Every edit becomes an operation
applied locally straight away and pushed in the background; two devices that
have seen the same operations always end up in exactly the same state,
regardless of the order those operations arrived.

### Remote layout

```
/manifest                  tiny root pointer, the only mutable file
/base/<shard>.<gen>.tc     snapshot chunks, sharded by list
/seg/<seq>-<device>.ts     immutable operation-log segments
```

The layout balances three workloads that pull in opposite directions:

| workload | cost |
|---|---|
| first download, 2000 tasks | ~13 requests, ~150 KB |
| tick one checkbox | ~350 B, 2 writes |
| drag one task | ~230 B, 2 writes |
| 300 edits made offline | ~15 KB, 2 writes |

A snapshot-only layout would make the first row cheap and the rest
expensive; a file-per-entity layout (what this app used previously) does the
reverse and needs one HTTP request per task. Base plus log gets both: a
cold start reads the base chunks, while a small edit appends a segment of a
few hundred bytes. When the log grows past a threshold it is folded back
into a new base generation, and only the shards whose bytes actually changed
are rewritten.

### Correctness

- **Compare-and-swap.** `/manifest` is written with Dropbox's
  `WriteMode.update`, which only succeeds if the file's rev is unchanged.
  A device that loses the race re-reads, replays what it missed, rebases its
  own work and retries, so no write is silently dropped. Segments and base
  chunks are immutable, so nothing else can conflict.
- **Hybrid logical clocks.** Ordering uses `(physical, counter, deviceId)`
  rather than wall time, so clock skew between devices cannot invert two
  edits, and every device resolves a conflict the same way.
- **Per-field merging.** Each field carries its own timestamp. Editing a
  task's title on one device while ticking its checkbox on another keeps
  both changes.
- **Dense ordering arrays.** Task order is an array plus replayed moves, so
  a reorder is one operation and the ordering cannot corrupt.
- **Checksums.** Every stored block is CRC-32C protected; a truncated or
  corrupt download is rejected rather than replayed.

### Code map

```
lib/sync/format/     binary codecs (byte_io, segment, chunk, manifest)
lib/sync/model/      HLC clocks, operations, replicated entities
lib/sync/engine/     replica (merge rules) and sync_engine (protocol)
lib/sync/            domain_mapper, dropbox_store, local_store
```

## Getting Started

### Prerequisites

- Flutter SDK 3.9+
- A Dropbox app key (optional, for sync)

### Run locally

```bash
flutter pub get
flutter run -d web-server --web-port=8080
```

### Tests

```bash
flutter test
```

The sync suite covers binary round-trips, fuzzed and truncated input,
convergence under randomised operation orderings, compare-and-swap races
between two devices, and per-workload size budgets.

### Build android APK (optimized)

```bash
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
```

## Migrating from the v1 sync format

Earlier versions stored one Dropbox file per entity plus an `/index.bin`.
`tool/migrate_v2.dart` converts that tree in place. It needs a short-lived
access token from
[the Dropbox app console](https://www.dropbox.com/developers/apps) →
your app → *Generated access token*.

```bash
# 1. Dry run: reports what it would write and verifies the round-trip.
dart run tool/migrate_v2.dart --token <token>

# 2. Upload the v2 store. The old files are left in place.
dart run tool/migrate_v2.dart --token <token> --commit

# 3. Once the app has been running against it happily, drop the v1 files.
dart run tool/migrate_v2.dart --token <token> --commit --delete-old
```

The migration rebuilds task ordering from the old intrusive linked list,
repairing any cycles or orphaned tasks it finds. Run it while no device is
writing. Afterwards each device re-downloads from scratch on first launch.

Once the migration is done, `lib/proto/`, `lib/builders.dart`, `proto/` and
the `protobuf` dependency are no longer used by anything and can be removed.

### Compiling protobuf (v1 format only)

Only needed while the migration tool is still around:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## License

This project is provided as-is for personal use.
