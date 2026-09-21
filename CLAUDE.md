## Commands

```bash
flutter pub get
flutter run -d web-server --web-port=8080   # web; also -d chrome / android
flutter test
flutter analyze
dart format lib test
```

Release builds (CI does these on push to `master`; see `.github/workflows/`):

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build web --release --base-href "/<repo-name>/"
```

Requires Flutter 3.9+. The web build deploys to GitHub Pages
(`https://reosfire.github.io/Todo/`); the APK is uploaded as a run artifact.

Code generation for drift (`lib/services/app_database.g.dart`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

`README.md` is user-facing only. Keep implementation detail out of it — it lives here.

## Sync design

Remote layout (Dropbox app folder):

```
/manifest                  tiny root pointer, the only mutable file
/base/<shard>.<gen>.tc     snapshot chunks, sharded by list
/seg/<seq>-<device>.ts     immutable operation-log segments
```

Base-plus-log is a deliberate compromise. Snapshot-only makes cold start cheap
and every edit expensive; file-per-entity (what v1 did) does the reverse and
needs one HTTP request per task. Here a cold start reads the base chunks while
a small edit appends a few hundred bytes. Once the log passes a threshold it is
folded into a new base generation, rewriting only the shards whose bytes
actually changed. `benchmark_test.dart` pins the resulting budgets:

| workload | cost |
|---|---|
| first download, 2000 tasks | ~13 requests, ~150 KB |
| tick one checkbox | ~350 B, 2 writes |
| drag one task | ~230 B, 2 writes |
| 300 edits made offline | ~15 KB, 2 writes |

Correctness rests on five things:

- **Compare-and-swap.** `/manifest` is written with Dropbox's
  `WriteMode.update`, which only succeeds if the file's rev is unchanged. A
  device that loses the race re-reads, replays what it missed, rebases its own
  work and retries, so no write is silently dropped. Segments and base chunks
  are immutable, so nothing else can conflict.
- **Hybrid logical clocks.** Ordering uses `(physical, counter, deviceId)`
  rather than wall time, so clock skew cannot invert two edits and every device
  resolves a conflict the same way.
- **Per-field merging.** Each field carries its own timestamp, so a title edit
  on one device and a checkbox tick on another both survive.
- **Dense ordering arrays.** Order is an array plus replayed moves, so a
  reorder is one op and the ordering cannot corrupt.
- **Checksums.** Every stored block is CRC-32C protected; a truncated or
  corrupt download is rejected rather than replayed.

```
lib/sync/format/     binary codecs (byte_io, segment, chunk, manifest)
lib/sync/model/      HLC clocks, operations, replicated entities
lib/sync/engine/     replica (merge rules) and sync_engine (protocol)
lib/sync/            domain_mapper, dropbox_store, local_store
```

## Architecture

```
ui/          widgets; read + mutate only via AppState (Provider)
state/       AppState — the single ChangeNotifier for the whole app
sync/        CRDT replica, ops, binary codecs, Dropbox protocol
models/      plain domain objects the UI speaks (Task, TaskList, Tag, ...)
services/    Dropbox HTTP + OAuth, drift database, local UI prefs
```

### Everything is an op

There is no "save the task" path. `AppState` turns each edit into the minimal
set of `Op`s via `DomainMapper`, then `_record()` applies them to the local
`Replica` immediately (so the UI updates without waiting on the network),
persists, and debounces a push (600ms). Consequences worth internalising:

- **Never mutate a domain model and expect it to stick.** Models returned from
  `AppState` are projections of the replica, rebuilt from it. Mutating one
  changes a copy. Go through an `AppState` method, which emits ops.
- **Adding a syncable field** means touching `sync/model/entities.dart` (the
  field + its own timestamp), `sync/format/op_codec.dart` and `chunk.dart`
  (wire encoding), and `sync/domain_mapper.dart` (both directions, plus the
  diff that decides which ops an edit emits). Emit only changed fields —
  that is what keeps a one-character title edit a few hundred bytes.
- **`DomainMapper` diffs must be deterministic and normalised.** Two devices
  that encode the same logical value differently will ping-pong ops forever.
  See `_colorIn`/`_colorOut` for why sign-extended ARGB is masked.

### Ordering

Task order is *not* stored on the task. It lives in dense ordering arrays per
`OrderScope`, and a reorder is one `MoveWithinOrderOp`. Membership comes from
the entities themselves; the array is only a hint about sequence, so
`Replica.orderedIds(scope, candidates)` filters it against the real members and
appends anything unordered. Lists and folders share one `sidebarScope`; tasks
use `(listId, completed)` — completed and pending are separate lanes.

`Task.previousTaskId` / `nextTaskId` are dead fields from the v1 linked-list
ordering, still present on the model and the drift schema. Do not build on them.

### AppState's projection cache

`tasks`, `lists`, `folders`, `tags`, `smartLists` are cached projections,
invalidated by `_invalidate()`. Any code path that changes the replica must
invalidate before `notifyListeners()`, or the UI will render stale data.

Sync cycles are serialised through `_syncChain` — two overlapping syncs would
fight over the manifest CAS.

### Persistence split

Two different stores, deliberately:

- `sync/local_store.dart` — the replica as **one encoded chunk blob**, plus an
  append-only pending-op segment. Synced data. Hot path is a single blob write.
- `services/storage_service.dart` — local-only UI preferences (expanded
  folders, current selection). Never synced: which list is open on your phone
  should not move the selection on your desktop.

Both sit on the same drift database (`services/app_database.dart`). Its
relational task/tag tables are v1 leftovers; live data is in the blob.

### Smart lists

`models/smart_list.dart` holds a sealed `SmartListFilter` hierarchy. A filter
both *organises* tasks into `TaskSection`s and *counts* them, and may declare
`newTaskScheduledDate` so adding a task from inside "Today" dates it correctly.
Adding a built-in filter means extending the sealed set and its codec in
`DomainMapper`.

### Web vs mobile

OAuth differs per platform. `services/web_auth.dart` is a conditional export
(`dart.library.js_interop`) over `web_auth_web.dart` / `web_auth_stub.dart`;
mobile uses `app_links` deep links instead. Anything touching `dart:html`/`web`
must go behind that seam.

Sharding arithmetic in `sync_engine.dart` is **deliberately 32-bit**: Dart ints
are JS doubles on web, so a 64-bit mix would assign entities to different shards
on web and native and split one dataset across two layouts. Keep it 32-bit.

## Testing

`test/sync/` is the load-bearing suite and its style is worth matching: binary
round-trips including fuzzed and truncated input, convergence under randomised
op orderings, and two engines racing against `FakeStore` (an in-memory
`RemoteStore` with real CAS semantics and a `beforeCas` hook to commit from
another device at the worst moment).

`benchmark_test.dart` asserts per-workload **size budgets** (request counts and
bytes for cold start, one checkbox, one drag, 300 offline edits). These are
design constraints, not micro-benchmarks — if a change trips one, the layout
regressed; do not just raise the bound.

Widget tests drive real widgets rather than extracted helpers where the
behaviour only emerges from the gesture lifecycle (see `side_panel_test.dart`).

`lib/global_constants.dart` holds the public Dropbox app key — this is a PKCE
public client, so the key is not a secret.
