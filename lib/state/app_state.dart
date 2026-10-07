import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../models/smart_list.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/dropbox_service.dart';
import '../sync/activity_store.dart';
import '../sync/backup.dart';
import '../sync/domain_mapper.dart';
import '../sync/dropbox_store.dart';
import '../sync/engine/replica.dart';
import '../sync/engine/sync_engine.dart';
import '../sync/local_store.dart';
import '../sync/model/entities.dart';
import '../sync/model/hlc.dart';
import '../sync/model/ops.dart';
import '../utils/uuid128.dart';

/// Application state backed by the CRDT sync engine.
///
/// Every mutation becomes one or more [Op]s, which are applied locally for an
/// immediate UI update and queued for the next push. Reads project the
/// replica into the app's domain models, cached so a rebuild does not
/// re-decode the world.
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final DropboxService dropboxService = DropboxService();
  final LocalStore _local = LocalStore();

  /// Every engine talks to Dropbox through this, so the UI can show when a
  /// transfer is in flight.
  late final ActivityStore _remote = ActivityStore(
    DropboxStore(dropboxService),
  );
  final _appLinks = AppLinks();

  late SyncEngine _engine;
  late HlcClock _clock;

  bool _loading = true;
  bool _syncing = false;
  bool _initialised = false;

  /// Whether this device's replica has ever been merged with the server.
  /// Until it has, an empty replica means "not downloaded yet", not "the
  /// user has no lists".
  bool _hasSynced = false;

  /// Debounce so a burst of edits becomes one segment upload.
  Timer? _pushTimer;
  static const _pushDebounce = Duration(milliseconds: 600);

  /// Serialises sync cycles; two overlapping syncs would fight over the CAS.
  Future<void> _syncChain = Future.value();

  Timer? _pollTimer;
  bool _polling = false;
  String? _longpollCursor;

  bool get loading => _loading;

  // ───── Local backups ─────

  List<BackupInfo> _backups = const [];
  int _backupKeep = LocalStore.defaultBackupKeep;
  bool _backedUpThisSession = false;

  /// Syncs happen after nearly every edit; a backup at most this often keeps
  /// the retained ones spread over hours rather than minutes.
  static const _backupInterval = Duration(hours: 1);

  /// Local full backups, newest first.
  List<BackupInfo> get backups => _backups;

  /// How many unpinned backups are kept.
  int get backupKeep => _backupKeep;

  /// Whether data is going up or coming down right now. A separate
  /// listenable so a request starting does not rebuild the whole app.
  ValueListenable<SyncActivity> get syncActivity => _remote.activity;
  bool get syncing => _syncing;
  bool get isSignedIn => dropboxService.isSignedIn;

  /// True when the Dropbox session expired and could not be renewed. Local
  /// edits are safe and still queued; they will upload after a new sign-in.
  bool get authExpired => dropboxService.authExpired;

  /// Ops made locally but not yet accepted by the server.
  int get pendingChanges => _initialised ? _engine.pendingOpCount : 0;

  // ───── Projection cache ─────
  //
  // The replica is the source of truth, but the UI asks for these lists on
  // every build. Rebuilding them is O(entities), so they are cached and
  // invalidated whenever the replica changes.

  List<Task>? _tasksCache;
  List<TaskList>? _listsCache;
  List<Folder>? _foldersCache;
  List<Tag>? _tagsCache;
  List<SmartList>? _smartListsCache;

  /// Tasks grouped by (list, completed) lane, and each lane in its stored
  /// order. The sidebar and the open list ask for these on every build, and
  /// each used to be its own scan over every task.
  Map<(Uuid128, bool), List<Task>>? _laneMembersCache;
  final Map<(Uuid128, bool), List<Task>> _orderedLaneCache = {};

  /// Smart-list badge counts, keyed by smart list id. Date filters depend on
  /// the day as well as the data, so the cache also drops at midnight.
  final Map<Uuid128, int> _smartListCountCache = {};
  DateTime? _smartListCountDay;

  void _invalidate() {
    _tasksCache = null;
    _listsCache = null;
    _foldersCache = null;
    _tagsCache = null;
    _smartListsCache = null;
    _laneMembersCache = null;
    _orderedLaneCache.clear();
    _smartListCountCache.clear();
  }

  Replica get _replica => _engine.replica;

  final _taskProjection = _Projection<Task>(
    EntityKind.task,
    DomainMapper.taskFrom,
  );
  final _listProjection = _Projection<TaskList>(
    EntityKind.list,
    DomainMapper.listFrom,
  );
  final _folderProjection = _Projection<Folder>(
    EntityKind.folder,
    DomainMapper.folderFrom,
  );
  final _tagProjection = _Projection<Tag>(EntityKind.tag, DomainMapper.tagFrom);
  final _smartListProjection = _Projection<SmartList>(
    EntityKind.smartList,
    DomainMapper.smartListFrom,
  );

  List<Task> get tasks => _tasksCache ??= _taskProjection.project(_replica);

  List<TaskList> get lists =>
      _listsCache ??= _sortedBySidebar(_listProjection.project(_replica));

  List<Folder> get folders =>
      _foldersCache ??= _sortedBySidebar(_folderProjection.project(_replica));

  List<Tag> get tags => _tagsCache ??= _tagProjection.project(_replica);

  List<SmartList> get smartLists =>
      _smartListsCache ??= _smartListProjection.project(_replica);

  /// Lists and folders share one ordering array, so both sort by their
  /// position in it.
  ///
  /// Positions are looked up once up front: resolving the array inside the
  /// comparator made every comparison rebuild every ordering scope.
  List<T> _sortedBySidebar<T extends Object>(List<T> items) {
    final order = _replica.resolvedOrder(DomainMapper.sidebarScope);
    final position = <Uuid128, int>{};
    for (var i = 0; i < order.length; i++) {
      position.putIfAbsent(order[i], () => i);
    }
    return items..sort((a, b) {
      final ia = position[_idOf(a)] ?? -1;
      final ib = position[_idOf(b)] ?? -1;
      if (ia == ib) return 0;
      // Anything absent from the array sorts last, deterministically.
      if (ia < 0) return 1;
      if (ib < 0) return -1;
      return ia.compareTo(ib);
    });
  }

  static Uuid128 _idOf(Object o) => switch (o) {
    TaskList(:final id) => id,
    Folder(:final id) => id,
    _ => throw ArgumentError('not a sidebar item: $o'),
  };

  // ───── Initialisation ─────

  Future<void> init() async {
    final deviceId = await _local.deviceId();
    final savedState = await _local.loadSyncState();

    _clock = HlcClock(deviceId: deviceId);
    // Resume from the highest timestamp this device ever issued or saw, so
    // restarting cannot produce an op that sorts before earlier work.
    _clock.observe(savedState.lastHlc);

    final (:replica, :restored) = await _local.loadReplica();
    _engine = SyncEngine(
      store: _remote,
      clock: _clock,
      deviceId: deviceId,
      replica: replica,
    );
    // Progress is only meaningful alongside the replica it was saved with.
    // Without one, everything remote must be fetched again.
    if (restored) {
      _engine.restoreProgress(
        baseGen: savedState.baseGen,
        chunks: savedState.loadedChunks,
        segments: savedState.appliedSegments,
      );
    }
    _hasSynced =
        restored &&
        (savedState.baseGen >= 0 || savedState.appliedSegments.isNotEmpty);
    // The replica snapshot is written lazily, so it can trail the pending
    // log by the last few edits. Replaying the log is always safe (applying
    // an op twice is a no-op) and brings the snapshot back up to date.
    final pending = await _local.loadPending();
    replica.applyAll(pending);
    _clock.observe(replica.maxHlc);
    _engine.restorePending(pending);

    _backupKeep = await _local.backupKeep();
    _backups = await _local.listBackups();

    _initialised = true;
    _invalidate();
    _loading = false;
    notifyListeners();

    dropboxService.onAuthLost = _handleAuthLost;
    await dropboxService.init();
    _initDeepLinks();
    WidgetsBinding.instance.addObserver(this);

    // A device that has never synced gets its default list after the first
    // pull. Creating it now would give every fresh install its own "Inbox"
    // alongside the real one, and new tasks could land in the wrong copy.
    if (_hasSynced || !dropboxService.isSignedIn) _ensureDefaults();

    if (dropboxService.isSignedIn) {
      unawaited(_syncNow());
      _startPolling();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    _pushTimer?.cancel();
    if (_snapshotTimer != null) unawaited(_persistLocal());
    WidgetsBinding.instance.removeObserver(this);
    _remote.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (dropboxService.isSignedIn) {
        unawaited(_syncNow());
        _startPolling();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
      // Flush anything buffered before the OS can freeze or kill us.
      unawaited(_flushNow());
    }
    // A stale snapshot only costs a replay on the next launch, but there is
    // no reason to leave one pending while the app is going away.
    if (state != AppLifecycleState.resumed && _snapshotTimer != null) {
      unawaited(_persistLocal());
    }
  }

  void _ensureDefaults() {
    if (DomainMapper.allLists(_replica).isEmpty) {
      final inbox = TaskList(id: Uuid128.generateV4(), name: 'Inbox');
      _record(DomainMapper.createList(inbox, _clock));
    }
  }

  // ───── Mutation plumbing ─────

  /// Apply ops locally, persist, and schedule a push.
  void _record(List<Op> ops) {
    if (ops.isEmpty) return;
    _engine.recordAll(ops);
    _invalidate();
    notifyListeners();
    // The pending log is the durable record of this edit and costs only the
    // new ops, so it is written now. The full snapshot is O(everything) and
    // is batched: a burst of edits (typing, dragging, ticking a column of
    // boxes) pays for it once instead of once per edit.
    unawaited(_savePending());
    _scheduleSnapshot();
    _schedulePush();
  }

  Timer? _snapshotTimer;
  static const _snapshotDebounce = Duration(milliseconds: 800);

  void _scheduleSnapshot() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer(_snapshotDebounce, () => unawaited(_persistLocal()));
  }

  Future<void> _savePending() async {
    try {
      await _local.savePending(_pendingOps(), _engine.deviceId);
    } catch (e) {
      debugPrint('Local persist failed: $e');
    }
  }

  /// Save the replica and pending log. Returns whether both reached disk.
  Future<bool> _persistLocal() async {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    try {
      await _local.saveReplica(_replica);
      await _local.savePending(_pendingOps(), _engine.deviceId);
      return true;
    } catch (e) {
      debugPrint('Local persist failed: $e');
      return false;
    }
  }

  /// The engine owns the pending list; this mirrors it for persistence.
  List<Op> _pendingOps() => _engine.pendingOps;

  void _schedulePush() {
    if (!dropboxService.isSignedIn) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDebounce, () => unawaited(_syncNow()));
  }

  Future<void> _flushNow() async {
    _pushTimer?.cancel();
    if (!dropboxService.isSignedIn) return;
    await _syncNow();
  }

  /// Run a sync cycle, serialised against any other in flight.
  Future<void> _syncNow({bool showSpinner = false}) {
    final next = _syncChain.then((_) async {
      if (!dropboxService.isSignedIn) return;
      if (showSpinner) {
        _syncing = true;
        notifyListeners();
      }
      try {
        // Taken before the pull, so it holds this device's own view in case
        // what comes down from the server turns out to be wrong.
        await _backup('Before sync');
        final report = await _engine.sync();
        _hasSynced = true;
        if (report.opsPulled > 0 || report.opsPushed > 0 || report.compacted) {
          _invalidate();
          notifyListeners();
        }
        _ensureDefaults();
        // Progress is saved only once the replica it describes is on disk.
        // Saved ahead of it, a reload would skip files the replica never
        // received.
        if (await _persistLocal()) await _saveSyncState();
      } on DropboxAuthException catch (e) {
        // Auth is gone; _handleAuthLost has already paused sync. Pending ops
        // stay queued and upload once the user signs in again.
        debugPrint('Sync stopped: $e');
        _ensureDefaults();
      } catch (e) {
        debugPrint('Sync failed: $e');
        // Offline on first launch: give the user somewhere to put tasks.
        _ensureDefaults();
      } finally {
        if (showSpinner) {
          _syncing = false;
          notifyListeners();
        }
      }
    });
    // Keep the chain alive even if this link threw.
    _syncChain = next.catchError((Object e) {
      debugPrint('Sync chain error: $e');
    });
    return next;
  }

  Future<void> _saveSyncState() async {
    final p = _engine.exportProgress();
    await _local.saveSyncState(
      SyncState(
        baseGen: p.baseGen,
        loadedChunks: p.chunks,
        appliedSegments: p.segments,
        lastHlc: _replica.maxHlc,
      ),
    );
  }

  // ───── Tasks ─────

  Task? taskById(Uuid128 id) {
    final e = _replica.get(EntityKind.task, id);
    return e == null ? null : DomainMapper.taskFrom(e);
  }

  List<Task> tasksForList(Uuid128 listId) =>
      tasks.where((t) => t.listId == listId).toList();

  Map<(Uuid128, bool), List<Task>> get _laneMembers =>
      _laneMembersCache ??= () {
        final lanes = <(Uuid128, bool), List<Task>>{};
        for (final t in tasks) {
          (lanes[(t.listId, t.isCompleted)] ??= []).add(t);
        }
        return lanes;
      }();

  /// Tasks of one list in their stored order.
  ///
  /// Order comes from the dense array for the (list, lane) scope; membership
  /// comes from the tasks themselves, so a task can never be orphaned by a
  /// stale ordering entry.
  ///
  /// The result is cached until the next change and must not be modified.
  List<Task> tasksForListOrdered(
    Uuid128 listId, {
    required bool completedSection,
  }) {
    final key = (listId, completedSection);
    return _orderedLaneCache[key] ??= () {
      final lane = _laneMembers[key];
      if (lane == null) return const <Task>[];
      final members = <Uuid128, Task>{for (final t in lane) t.id: t};
      final scope = DomainMapper.taskScope(listId, completed: completedSection);
      final ordered = _replica.orderedIds(scope, members.keys.toSet());
      return List<Task>.unmodifiable([
        for (final id in ordered)
          if (members[id] case final t?) t,
      ]);
    }();
  }

  /// Incomplete tasks in [listId], for the sidebar badge.
  int pendingCountForList(Uuid128 listId) =>
      _laneMembers[(listId, false)]?.length ?? 0;

  /// How many tasks [smartList] shows as outstanding, for its badge.
  int smartListCount(SmartList smartList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_smartListCountDay != today) {
      _smartListCountCache.clear();
      _smartListCountDay = today;
    }
    return _smartListCountCache[smartList.id] ??= smartList.filter.countTasks(
      tasks,
    );
  }

  Uuid128 newId() => Uuid128.generateV4();

  /// Add a task at the top of its list.
  Future<void> addTaskAsHead(Task task) async {
    final scope = DomainMapper.taskScope(
      task.listId,
      completed: task.isCompleted,
    );
    final current = tasksForListOrdered(
      task.listId,
      completedSection: task.isCompleted,
    ).map((t) => t.id).toList();

    _record([
      ...DomainMapper.createTask(task, _clock),
      // One move op rather than rewriting neighbours: this is the whole
      // reason the linked list is gone.
      MoveWithinOrderOp(_clock.issue(), scope, task.id, null),
      if (current.isEmpty) SetOrderOp(_clock.issue(), scope, [task.id]),
    ]);
  }

  Future<void> addTask(Task task) async => addTaskAsHead(task);

  Future<void> updateTask(Task task) async {
    _record(DomainMapper.updateTask(task, taskById(task.id), _clock));
  }

  Future<void> updateTasks(List<Task> updated) async {
    final ops = <Op>[];
    for (final t in updated) {
      ops.addAll(DomainMapper.updateTask(t, taskById(t.id), _clock));
    }
    _record(ops);
  }

  Future<void> deleteTask(Uuid128 id) async {
    _record([DeleteEntityOp(_clock.issue(), EntityKind.task, id)]);
  }

  Future<void> toggleTask(Task task, {DateTime? onDate}) async {
    if (task.recurrence != null && onDate != null) {
      // Recurring tasks record per-date completion instead of a flag.
      final day = DateTime(onDate.year, onDate.month, onDate.day);
      final dates = Set<DateTime>.from(task.completedDates);
      if (task.isCompletedOn(day)) {
        dates.removeWhere(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
      } else {
        dates.add(day);
      }
      _record([
        SetFieldOp(
          _clock.issue(),
          EntityKind.task,
          task.id,
          TaskField.completedDates,
          DateSetValue(dates.map(DomainMapper.toDays).toSet()),
        ),
      ]);
      return;
    }

    // Toggling moves the task between the pending and completed lanes.
    final nowCompleted = !task.isCompleted;
    final targetScope = DomainMapper.taskScope(
      task.listId,
      completed: nowCompleted,
    );
    _record([
      SetFieldOp(
        _clock.issue(),
        EntityKind.task,
        task.id,
        TaskField.isCompleted,
        BoolValue(nowCompleted),
      ),
      MoveWithinOrderOp(_clock.issue(), targetScope, task.id, null),
    ]);
  }

  /// Persist an explicit ordering for one section of a list.
  Future<void> rebuildLinkedListForTasks(List<Task> orderedTasks) async {
    if (orderedTasks.isEmpty) return;
    final first = orderedTasks.first;
    final scope = DomainMapper.taskScope(
      first.listId,
      completed: first.isCompleted,
    );
    _record([
      SetOrderOp(_clock.issue(), scope, orderedTasks.map((t) => t.id).toList()),
    ]);
  }

  /// Move [task] to sit between [newPrevious] and [newNext].
  Future<void> reorderTask(Task task, Task? newPrevious, Task? newNext) async {
    final scope = DomainMapper.taskScope(
      task.listId,
      completed: task.isCompleted,
    );
    _record([
      MoveWithinOrderOp(_clock.issue(), scope, task.id, newPrevious?.id),
    ]);
  }

  /// Kept for source compatibility with the previous linked-list API.
  Task copyTask(
    Task task, {
    required Uuid128? previousTaskId,
    required Uuid128? nextTaskId,
  }) => task;

  // ───── Lists ─────

  TaskList? listById(Uuid128 id) {
    final e = _replica.get(EntityKind.list, id);
    return e == null ? null : DomainMapper.listFrom(e);
  }

  Future<void> addList(TaskList list) async {
    final order = [...lists.map((l) => l.id), ...folders.map((f) => f.id)];
    _record([
      ...DomainMapper.createList(list, _clock),
      SetOrderOp(_clock.issue(), DomainMapper.sidebarScope, [
        ...order,
        list.id,
      ]),
    ]);
  }

  Future<void> updateList(TaskList list) async {
    _record(DomainMapper.updateList(list, listById(list.id), _clock));
  }

  Future<void> deleteList(Uuid128 id) async {
    final ops = <Op>[DeleteEntityOp(_clock.issue(), EntityKind.list, id)];
    for (final t in tasks.where((t) => t.listId == id)) {
      ops.add(DeleteEntityOp(_clock.issue(), EntityKind.task, t.id));
    }
    _record(ops);
  }

  Future<void> reorderLists(List<TaskList> reordered) async {
    // Lists inside a folder are a subsequence of the shared sidebar order;
    // splice them back into their existing slots so folders stay put.
    final current = _sidebarOrder();
    final moving = reordered.map((l) => l.id).toList();
    final slots = <int>[
      for (var i = 0; i < current.length; i++)
        if (moving.contains(current[i])) i,
    ];
    final next = List<Uuid128>.from(current);
    for (var i = 0; i < slots.length && i < moving.length; i++) {
      next[slots[i]] = moving[i];
    }
    _record([SetOrderOp(_clock.issue(), DomainMapper.sidebarScope, next)]);
  }

  /// Reorder a mixed sequence of lists and folders.
  Future<void> reorderMixed(List<dynamic> items) async {
    final ids = <Uuid128>[
      for (final it in items)
        if (it is TaskList) it.id else if (it is Folder) it.id,
    ];
    _record([SetOrderOp(_clock.issue(), DomainMapper.sidebarScope, ids)]);
  }

  List<Uuid128> _sidebarOrder() {
    final members = {...lists.map((l) => l.id), ...folders.map((f) => f.id)};
    return _replica.orderedIds(DomainMapper.sidebarScope, members);
  }

  // ───── Folders ─────

  Folder? folderById(Uuid128 id) {
    final e = _replica.get(EntityKind.folder, id);
    return e == null ? null : DomainMapper.folderFrom(e);
  }

  Future<void> addFolder(Folder folder) async {
    _record([
      ...DomainMapper.createFolder(folder, _clock),
      SetOrderOp(_clock.issue(), DomainMapper.sidebarScope, [
        ..._sidebarOrder(),
        folder.id,
      ]),
    ]);
  }

  Future<void> updateFolder(Folder folder) async {
    _record(DomainMapper.updateFolder(folder, folderById(folder.id), _clock));
  }

  Future<void> deleteFolder(Uuid128 id) async {
    final ops = <Op>[DeleteEntityOp(_clock.issue(), EntityKind.folder, id)];
    // Lists in the folder survive; they just lose their parent.
    for (final l in lists.where((l) => l.folderId == id)) {
      ops.add(
        SetFieldOp(
          _clock.issue(),
          EntityKind.list,
          l.id,
          ListField.folderId,
          const NullValue(),
        ),
      );
    }
    _record(ops);
  }

  Future<void> reorderFolders(List<Folder> reordered) async {
    final current = _sidebarOrder();
    final moving = reordered.map((f) => f.id).toList();
    final slots = <int>[
      for (var i = 0; i < current.length; i++)
        if (moving.contains(current[i])) i,
    ];
    final next = List<Uuid128>.from(current);
    for (var i = 0; i < slots.length && i < moving.length; i++) {
      next[slots[i]] = moving[i];
    }
    _record([SetOrderOp(_clock.issue(), DomainMapper.sidebarScope, next)]);
  }

  // ───── Tags ─────

  Tag? tagById(Uuid128 id) {
    final e = _replica.get(EntityKind.tag, id);
    return e == null ? null : DomainMapper.tagFrom(e);
  }

  Future<void> addTag(Tag tag) async {
    _record(DomainMapper.createTag(tag, _clock));
  }

  Future<void> updateTag(Tag tag) async {
    _record(DomainMapper.updateTag(tag, tagById(tag.id), _clock));
  }

  Future<void> deleteTag(Uuid128 id) async {
    final ops = <Op>[DeleteEntityOp(_clock.issue(), EntityKind.tag, id)];
    for (final t in tasks.where((t) => t.tagIds.contains(id))) {
      ops.add(
        SetFieldOp(
          _clock.issue(),
          EntityKind.task,
          t.id,
          TaskField.tagIds,
          UuidSetValue({...t.tagIds}..remove(id)),
        ),
      );
    }
    _record(ops);
  }

  // ───── Smart lists ─────

  SmartList? smartListById(Uuid128 id) {
    for (final sl in builtInSmartLists) {
      if (sl.id == id) return sl;
    }
    final e = _replica.get(EntityKind.smartList, id);
    return e == null ? null : DomainMapper.smartListFrom(e);
  }

  Future<void> addSmartList(SmartList smartList) async {
    _record(DomainMapper.createSmartList(smartList, _clock));
  }

  Future<void> updateSmartList(SmartList smartList) async {
    _record(
      DomainMapper.updateSmartList(
        smartList,
        smartListById(smartList.id),
        _clock,
      ),
    );
  }

  Future<void> deleteSmartList(Uuid128 id) async {
    _record([DeleteEntityOp(_clock.issue(), EntityKind.smartList, id)]);
  }

  // ───── Sync surface ─────

  Future<void> signIn() async {
    await dropboxService.signIn();
    if (dropboxService.isSignedIn) {
      notifyListeners();
      await _syncNow(showSpinner: true);
      _startPolling();
    }
  }

  /// Dropbox authentication is gone for good. Stop the retry loops and let
  /// the UI prompt for a new sign-in — previously this surfaced only as
  /// repeated console errors while sync sat dead.
  void _handleAuthLost() {
    debugPrint('Dropbox authentication lost — sync paused until re-sign-in.');
    _stopPolling();
    _pushTimer?.cancel();
    _syncing = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _stopPolling();
    await dropboxService.signOut();
    notifyListeners();
  }

  Future<void> sync() => _syncNow(showSpinner: true);

  /// Push local changes now.
  ///
  /// Runs through [_syncNow] like every other cycle. Calling the engine
  /// directly let it overlap a background sync on the same pending queue:
  /// both uploaded the same ops, and each then acknowledged its count from
  /// the front, dropping edits recorded in between.
  Future<void> forceUpload() => _syncNow(showSpinner: true);

  /// Discard local state and rebuild it from the server.
  Future<void> forceDownload() {
    final next = _syncChain.then((_) async {
      if (!dropboxService.isSignedIn) return;
      _syncing = true;
      notifyListeners();
      try {
        // Everything local, unsynced edits included, is about to be thrown
        // away.
        await _backup('Before force download', force: true);
        final deviceId = _engine.deviceId;
        final engine = SyncEngine(
          store: _remote,
          clock: _clock,
          deviceId: deviceId,
        );
        await engine.hydrate();
        _engine = engine;
        _hasSynced = true;
        _invalidate();
        _ensureDefaults();
        if (await _persistLocal()) await _saveSyncState();
      } on DropboxAuthException catch (e) {
        debugPrint('Force download stopped: $e');
      } catch (e) {
        debugPrint('Force download failed: $e');
      } finally {
        _syncing = false;
        notifyListeners();
      }
    });
    _syncChain = next.catchError((Object e) {
      debugPrint('Sync chain error: $e');
    });
    return next;
  }

  /// Back up the replica if one is due. [force] skips the interval check,
  /// but an unchanged or empty replica is never backed up: a backup of
  /// nothing would push a real one out of the retained set.
  Future<void> _backup(String reason, {bool force = false}) async {
    if (!force && _backedUpThisSession) {
      final last = _backups.firstOrNull;
      if (last != null &&
          DateTime.now().difference(last.createdAt) < _backupInterval) {
        return;
      }
    }
    if (!_replica.entities.values.any((e) => !e.isDeleted)) return;
    try {
      final saved = await _local.saveBackup(_replica, reason: reason);
      _backedUpThisSession = true;
      if (saved != null) await _local.pruneBackups(_backupKeep);
      await _reloadBackups();
    } catch (e) {
      debugPrint('Backup failed: $e');
    }
  }

  Future<void> _reloadBackups() async {
    _backups = await _local.listBackups();
    notifyListeners();
  }

  Future<void> backupNow() => _backup('Manual', force: true);

  Future<void> deleteBackup(int id) async {
    await _local.deleteBackup(id);
    await _reloadBackups();
  }

  Future<void> setBackupPinned(int id, bool pinned) async {
    await _local.setBackupPinned(id, pinned);
    await _reloadBackups();
  }

  Future<void> setBackupKeep(int keep) async {
    _backupKeep = keep;
    await _local.setBackupKeep(keep);
    await _local.pruneBackups(keep);
    await _reloadBackups();
  }

  /// Restore backup [id]. See [restoreOps] for what [replaceAll] means.
  ///
  /// Goes out as ordinary edits, so it syncs to every device. The current
  /// state is backed up first, so a restore can itself be undone. Returns
  /// the number of changes made.
  Future<int> restoreBackup(int id, {required bool replaceAll}) async {
    final backup = await _local.loadBackup(id);
    await _backup('Before restore', force: true);
    final ops = restoreOps(_replica, backup, _clock, replaceAll: replaceAll);
    _record(ops);
    return ops.length;
  }

  /// What a fresh device would have to download, for the settings screen.
  ({int files, int bytes}) get coldStartCost => _engine.coldStartCost();

  // ───── Remote change polling ─────

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    unawaited(_pollLoop());
  }

  void _stopPolling() {
    _polling = false;
    _pollTimer?.cancel();
  }

  /// Longpoll Dropbox and sync whenever it reports a change.
  Future<void> _pollLoop() async {
    while (_polling && dropboxService.isSignedIn) {
      if (dropboxService.authExpired) break;
      try {
        _longpollCursor ??= await dropboxService.getLatestCursor();
        if (_longpollCursor == null) {
          await Future.delayed(const Duration(seconds: 30));
          continue;
        }
        final changed = await dropboxService.longpollForChanges(
          _longpollCursor!,
          timeout: 120,
        );
        if (!_polling) break;
        if (changed == null) {
          _longpollCursor = null;
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
        _longpollCursor = await dropboxService.getLatestCursor();
        if (changed) await _syncNow();
      } on DropboxAuthException catch (e) {
        // Re-signing in is the only fix, so stop rather than retry forever.
        debugPrint('Poll loop stopped: $e');
        break;
      } catch (e) {
        debugPrint('Poll loop error: $e');
        _longpollCursor = null;
        if (_polling) await Future.delayed(const Duration(seconds: 10));
      }
    }
  }

  // ───── Deep links (OAuth redirect) ─────

  void _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleIncomingLink(initial);
    } catch (_) {
      // No initial link; nothing to do.
    }
    _appLinks.uriLinkStream.listen(_handleIncomingLink);
  }

  void _handleIncomingLink(Uri uri) async {
    if (uri.scheme != 'todopen' || uri.host != 'auth') return;
    final code = uri.queryParameters['code'];
    if (code == null) return;
    if (await dropboxService.handleRedirectCode(code)) {
      notifyListeners();
      await _syncNow(showSpinner: true);
      _startPolling();
    }
  }
}

/// Projects one entity kind into domain models, reusing the model made last
/// time for every entity whose version has not moved.
///
/// Same result as the matching `DomainMapper.all*`, but an edit re-decodes
/// only the entities it touched. Unchanged models also keep their identity
/// across rebuilds, which is what lets widgets tell cheaply that nothing they
/// show has changed.
class _Projection<T extends Object> {
  final EntityKind kind;
  final T? Function(ReplicatedEntity) decode;

  _Projection(this.kind, this.decode);

  /// Keyed by identity: a replica rebuilt from scratch holds new entity
  /// objects, which correctly miss.
  Map<ReplicatedEntity, (int, T?)> _last = Map.identity();

  List<T> project(Replica replica) {
    final previous = _last;
    final next = Map<ReplicatedEntity, (int, T?)>.identity();
    final out = <T>[];
    for (final e in replica.live(kind)) {
      final cached = previous[e];
      final model = cached != null && cached.$1 == e.version
          ? cached.$2
          : decode(e);
      next[e] = (e.version, model);
      if (model != null) out.add(model);
    }
    _last = next;
    return out;
  }
}
