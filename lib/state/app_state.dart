import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../models/smart_list.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/dropbox_service.dart';
import '../sync/domain_mapper.dart';
import '../sync/dropbox_store.dart';
import '../sync/engine/replica.dart';
import '../sync/engine/sync_engine.dart';
import '../sync/local_store.dart';
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
  final _appLinks = AppLinks();

  late SyncEngine _engine;
  late HlcClock _clock;

  bool _loading = true;
  bool _syncing = false;
  bool _initialised = false;

  /// Debounce so a burst of edits becomes one segment upload.
  Timer? _pushTimer;
  static const _pushDebounce = Duration(milliseconds: 600);

  /// Serialises sync cycles; two overlapping syncs would fight over the CAS.
  Future<void> _syncChain = Future.value();

  Timer? _pollTimer;
  bool _polling = false;
  String? _longpollCursor;

  bool get loading => _loading;
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

  void _invalidate() {
    _tasksCache = null;
    _listsCache = null;
    _foldersCache = null;
    _tagsCache = null;
    _smartListsCache = null;
  }

  Replica get _replica => _engine.replica;

  List<Task> get tasks => _tasksCache ??= DomainMapper.allTasks(_replica);

  List<TaskList> get lists =>
      _listsCache ??= DomainMapper.allLists(_replica)
        ..sort(_bySidebarOrder);

  List<Folder> get folders =>
      _foldersCache ??= DomainMapper.allFolders(_replica)
        ..sort(_bySidebarOrder);

  List<Tag> get tags => _tagsCache ??= DomainMapper.allTags(_replica);

  List<SmartList> get smartLists =>
      _smartListsCache ??= DomainMapper.allSmartLists(_replica);

  /// Lists and folders share one ordering array, so both sort by their
  /// position in it.
  int _bySidebarOrder(Object a, Object b) {
    final order = _replica.orders[DomainMapper.sidebarScope]?.value ?? const [];
    final ia = order.indexOf(_idOf(a));
    final ib = order.indexOf(_idOf(b));
    if (ia == ib) return 0;
    // Anything absent from the array sorts last, deterministically.
    if (ia < 0) return 1;
    if (ib < 0) return -1;
    return ia.compareTo(ib);
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

    final replica = await _local.loadReplica();
    _engine = SyncEngine(
      store: DropboxStore(dropboxService),
      clock: _clock,
      deviceId: deviceId,
      replica: replica,
    );
    _engine.restoreProgress(
      baseGen: savedState.baseGen,
      chunks: savedState.loadedChunks,
      segments: savedState.appliedSegments,
    );
    _engine.restorePending(await _local.loadPending());

    _initialised = true;
    _invalidate();
    _ensureDefaults();
    _loading = false;
    notifyListeners();

    dropboxService.onAuthLost = _handleAuthLost;
    await dropboxService.init();
    _initDeepLinks();
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.removeObserver(this);
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
    unawaited(_persistLocal());
    _schedulePush();
  }

  Future<void> _persistLocal() async {
    try {
      await _local.saveReplica(_replica);
      await _local.savePending(_pendingOps(), _engine.deviceId);
    } catch (e) {
      debugPrint('Local persist failed: $e');
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
        final report = await _engine.sync();
        if (report.opsPulled > 0 || report.opsPushed > 0 || report.compacted) {
          _invalidate();
          _ensureDefaults();
          notifyListeners();
        }
        await _persistLocal();
        await _saveSyncState();
      } on DropboxAuthException catch (e) {
        // Auth is gone; _handleAuthLost has already paused sync. Pending ops
        // stay queued and upload once the user signs in again.
        debugPrint('Sync stopped: $e');
      } catch (e) {
        debugPrint('Sync failed: $e');
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

  /// Tasks of one list in their stored order.
  ///
  /// Order comes from the dense array for the (list, lane) scope; membership
  /// comes from the tasks themselves, so a task can never be orphaned by a
  /// stale ordering entry.
  List<Task> tasksForListOrdered(
    Uuid128 listId, {
    required bool completedSection,
  }) {
    final members = <Uuid128, Task>{
      for (final t in tasks)
        if (t.listId == listId && t.isCompleted == completedSection) t.id: t,
    };
    if (members.isEmpty) return const [];

    final scope = DomainMapper.taskScope(
      listId,
      completed: completedSection,
    );
    final ordered = _replica.orderedIds(scope, members.keys.toSet());
    return [
      for (final id in ordered)
        if (members[id] case final t?) t,
    ];
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
      if (current.isEmpty)
        SetOrderOp(_clock.issue(), scope, [task.id]),
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
      SetOrderOp(
        _clock.issue(),
        scope,
        orderedTasks.map((t) => t.id).toList(),
      ),
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
    final members = {
      ...lists.map((l) => l.id),
      ...folders.map((f) => f.id),
    };
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

  /// Re-upload everything by compacting a fresh base from local state.
  Future<void> forceUpload() async {
    if (!dropboxService.isSignedIn) return;
    _syncing = true;
    notifyListeners();
    try {
      await _engine.sync();
      await _saveSyncState();
    } on DropboxAuthException catch (e) {
      debugPrint('Force upload stopped: $e');
    } catch (e) {
      debugPrint('Force upload failed: $e');
    }
    _syncing = false;
    notifyListeners();
  }

  /// Discard local state and rebuild it from the server.
  Future<void> forceDownload() async {
    if (!dropboxService.isSignedIn) return;
    _syncing = true;
    notifyListeners();
    try {
      final deviceId = _engine.deviceId;
      _engine = SyncEngine(
        store: DropboxStore(dropboxService),
        clock: _clock,
        deviceId: deviceId,
      );
      await _engine.hydrate();
      _invalidate();
      _ensureDefaults();
      await _persistLocal();
      await _saveSyncState();
    } on DropboxAuthException catch (e) {
      debugPrint('Force download stopped: $e');
    } catch (e) {
      debugPrint('Force download failed: $e');
    }
    _syncing = false;
    notifyListeners();
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
