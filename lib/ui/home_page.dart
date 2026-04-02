import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/task_list.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';
import '../utils/uuid128.dart';
import 'task_list_view.dart';
import 'smart_list_view.dart';
import 'list_editor_dialog.dart';
import 'folder_editor_dialog.dart';
import '../models/smart_list.dart';
import 'smart_list_editor_dialog.dart';
import 'tag_manager_dialog.dart';
import 'sync_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uuid128? _selectedListId;
  Uuid128? _selectedSmartListId;
  Set<Uuid128> _expandedFolderIds = {};
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUiState();
  }

  Future<void> _loadUiState() async {
    final results = await Future.wait([
      _storageService.loadExpandedFolderIds(),
      _storageService.loadSelectedListId(),
      _storageService.loadSelectedSmartListId(),
    ]);
    final ids = results[0] as Set<Uuid128>;
    final listId = results[1] as Uuid128?;
    final smartListId = results[2] as Uuid128?;
    setState(() {
      _expandedFolderIds = ids;
      _selectedListId = listId;
      _selectedSmartListId = smartListId;
    });
    // If nothing was saved before, fall back to the first list.
    if (_selectedListId == null && _selectedSmartListId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.read<AppState>();
        if (state.lists.isNotEmpty) {
          setState(() => _selectedListId = state.lists.first.id);
        }
      });
    }
  }

  Future<void> _saveExpandedFolders() async {
    await _storageService.saveExpandedFolderIds(_expandedFolderIds);
  }

  void _selectList(Uuid128 id) {
    setState(() {
      _selectedListId = id;
      _selectedSmartListId = null;
    });
    _storageService.saveSelectedListId(id);
    _storageService.saveSelectedSmartListId(null);
    if (_isNarrow) Navigator.pop(context);
  }

  void _selectSmartList(Uuid128 id) {
    setState(() {
      _selectedSmartListId = id;
      _selectedListId = null;
    });
    _storageService.saveSelectedSmartListId(id);
    _storageService.saveSelectedListId(null);
    if (_isNarrow) Navigator.pop(context);
  }

  bool get _isNarrow => MediaQuery.of(context).size.width < 600;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Auto‑select first list.
    if (_selectedListId == null &&
        _selectedSmartListId == null &&
        state.lists.isNotEmpty) {
      _selectedListId = state.lists.first.id;
    }

    final drawer = _buildDrawer(state);
    final body = _buildBody(state);

    if (_isNarrow) {
      return Scaffold(
        appBar: _buildAppBar(state),
        drawer: Drawer(child: drawer),
        body: body,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 280, child: drawer),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildWideAppBar(state),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppState state) {
    String title = _getAppBarTitle(state);
    return AppBar(
      title: Text(title),
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        if (state.syncing)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.isSignedIn)
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => state.sync(),
            tooltip: 'Sync',
          ),
      ],
    );
  }

  Widget _buildWideAppBar(AppState state) {
    String title = _getAppBarTitle(state);
    return Container(
      height: 56,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (state.syncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (state.isSignedIn)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => state.sync(),
              tooltip: 'Sync',
            ),
        ],
      ),
    );
  }

  String _getAppBarTitle(AppState state) {
    String defaultTitle = 'todopen';
    if (_selectedSmartListId != null) {
      return state.smartListById(_selectedSmartListId!)?.name ?? defaultTitle;
    }
    if (_selectedListId != null) {
      return state.listById(_selectedListId!)?.name ?? defaultTitle;
    }
    return defaultTitle;
  }

  Widget _buildDrawer(AppState state) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Smart lists
                const _SectionHeader('SMART LISTS'),
                // Built-in smart lists (always shown, not editable)
                ...builtInSmartLists.map((sl) {
                  final count = sl.filter.countTasks(state.tasks);
                  return ListTile(
                    leading: Icon(sl.icon, color: sl.color),
                    title: Text(sl.name),
                    trailing: count > 0
                        ? SizedBox(
                            width: 32,
                            child: Text(
                              '$count',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : null,
                    selected: _selectedSmartListId == sl.id,
                    onTap: () => _selectSmartList(sl.id),
                    dense: true,
                  );
                }),
                // User-created smart lists
                ...state.smartLists.map((sl) {
                  final count = sl.filter.countTasks(state.tasks);
                  return _HoverTrailingTile(
                    child: (isHovered) => ListTile(
                      leading: Icon(sl.icon, color: sl.color),
                      title: Text(sl.name),
                      trailing: SizedBox(
                        width: 32,
                        height: 32,
                        child: isHovered
                            ? IconButton(
                                icon: const Icon(Icons.more_horiz, size: 18),
                                onPressed: () =>
                                    _showSmartListMenu(context, state, sl),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 32,
                                  height: 32,
                                ),
                                visualDensity: VisualDensity.compact,
                              )
                            : count > 0
                            ? Text(
                                '$count',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              )
                            : const SizedBox.shrink(),
                      ),
                      selected: _selectedSmartListId == sl.id,
                      onTap: () => _selectSmartList(sl.id),
                      dense: true,
                    ),
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add, size: 20),
                  title: const Text('Add Smart List'),
                  dense: true,
                  onTap: () => _showSmartListEditor(context, state),
                ),
                const Divider(),

                // Folders and lists
                const _SectionHeader('LISTS'),
                ..._buildFolderAndListItems(state),
                ListTile(
                  leading: const Icon(Icons.add, size: 20),
                  title: const Text('Add List'),
                  dense: true,
                  onTap: () => _showListEditor(context, state, null),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.create_new_folder_outlined,
                    size: 20,
                  ),
                  title: const Text('Add Folder'),
                  dense: true,
                  onTap: () => _showFolderEditor(context, state, null),
                ),
                const Divider(),

                // Bottom actions
                ListTile(
                  leading: const Icon(Icons.label_outline, size: 20),
                  title: const Text('Manage Tags'),
                  dense: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const TagManagerDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    state.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                    size: 20,
                  ),
                  title: Text(state.isSignedIn ? 'Sync Settings' : 'Sign In'),
                  dense: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SyncSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFolderAndListItems(AppState state) {
    // Interleave orphan lists and folders sorted by their order field.
    final orphanLists = state.lists.where((l) => l.folderId == null).toList();
    final folders = state.folders.toList();
    final combined = <dynamic>[...orphanLists, ...folders]
      ..sort((a, b) {
        final aOrder = a is TaskList ? a.order : (a as Folder).order;
        final bOrder = b is TaskList ? b.order : (b as Folder).order;
        return aOrder.compareTo(bOrder);
      });

    Widget buildFolderWidget(Folder folder) {
      final folderLists =
          state.lists.where((l) => l.folderId == folder.id).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      final folderListCount = state.tasks
          .where(
            (t) => folderLists.any((l) => l.id == t.listId) && !t.isCompleted,
          )
          .length;
      return _HoverTrailingTile(
        key: ValueKey('folder_${folder.id}'),
        child: (isHovered) => _SwipeToEdit(
          onEdit: () => _showFolderMenu(context, state, folder),
          child: ExpansionTile(
            initiallyExpanded: _expandedFolderIds.contains(folder.id),
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedFolderIds.add(folder.id);
                } else {
                  _expandedFolderIds.remove(folder.id);
                }
              });
              _saveExpandedFolders();
            },
            leading: const Icon(Icons.folder_outlined, size: 20),
            title: Text(folder.name),
            dense: true,
            shape: const Border(),
            collapsedShape: const Border(),
            trailing: SizedBox(
              width: 32,
              height: 32,
              child: isHovered
                  ? IconButton(
                      icon: const Icon(Icons.more_horiz, size: 18),
                      onPressed: () => _showFolderMenu(context, state, folder),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                    )
                  : folderListCount > 0
                  ? Text(
                      '$folderListCount',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
            ),
            children: [
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  _reorderListsInFolder(
                    state,
                    folder.id,
                    folderLists,
                    oldIndex,
                    newIndex,
                  );
                },
                children: folderLists.asMap().entries.map((e) {
                  final key = ValueKey('list_${e.value.id}_in_folder');
                  final tile = _SwipeToEdit(
                    onEdit: () => _showListMenu(context, state, e.value),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildListTile(state, e.value, enableSwipe: false),
                    ),
                  );
                  return _isMobile
                      ? ReorderableDelayedDragStartListener(
                          key: key,
                          index: e.key,
                          child: tile,
                        )
                      : ReorderableDragStartListener(
                          key: key,
                          index: e.key,
                          child: tile,
                        );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    // Build combined widgets in interleaved order.
    final combinedWidgets = combined.map((item) {
      if (item is TaskList) {
        return _buildListTile(state, item, key: ValueKey('list_${item.id}'));
      } else {
        return buildFolderWidget(item as Folder);
      }
    }).toList();

    return [
      ReorderableListView(
        key: const ValueKey('reorderable_folders_lists'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) =>
            _reorderFoldersAndLists(state, combined, oldIndex, newIndex),
        children: combinedWidgets.asMap().entries.map(
          (e) => _isMobile
              ? ReorderableDelayedDragStartListener(
                  key: e.value.key!,
                  index: e.key,
                  child: e.value,
                )
              : ReorderableDragStartListener(
                  key: e.value.key!,
                  index: e.key,
                  child: e.value,
                ),
        ).toList(),
      ),
    ];
  }

  void _reorderFoldersAndLists(
    AppState state,
    List<dynamic> combined,
    int oldIndex,
    int newIndex,
  ) {
    final items = List<dynamic>.from(combined);
    if (oldIndex < newIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state.reorderMixed(items);
  }

  void _reorderListsInFolder(
    AppState state,
    Uuid128 folderId,
    List<TaskList> folderLists,
    int oldIndex,
    int newIndex,
  ) {
    // Perform reorder
    if (oldIndex < newIndex) newIndex--;
    final item = folderLists.removeAt(oldIndex);
    folderLists.insert(newIndex, item);

    // Update state with reordered lists in this folder
    state.reorderLists(folderLists);
  }

  Widget _buildListTile(AppState state, TaskList list, {Key? key, bool enableSwipe = true}) {
    final count = state.tasks
        .where((t) => t.listId == list.id && !t.isCompleted)
        .length;
    return _HoverTrailingTile(
      key: key,
      child: (isHovered) {
        final tile = ListTile(
          leading: Icon(Icons.list, color: list.color, size: 20),
          title: Text(list.name),
          trailing: SizedBox(
            width: 32,
            height: 32,
            child: isHovered
                ? IconButton(
                    icon: const Icon(Icons.more_horiz, size: 18),
                    onPressed: () => _showListMenu(context, state, list),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                : count > 0
                ? Text(
                    '$count',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink(),
          ),
          selected: _selectedListId == list.id,
          dense: true,
          onTap: () => _selectList(list.id),
        );
        if (!enableSwipe) return tile;
        return _SwipeToEdit(
          onEdit: () => _showListMenu(context, state, list),
          child: tile,
        );
      },
    );
  }

  Widget _buildBody(AppState state) {
    if (_selectedSmartListId != null) {
      final sl = state.smartListById(_selectedSmartListId!);
      if (sl != null) return SmartListView(smartList: sl);
    }
    if (_selectedListId != null) {
      return TaskListView(listId: _selectedListId!);
    }
    return const Center(child: Text('Select a list'));
  }

  // ───── Dialogs ─────

  void _showListEditor(BuildContext ctx, AppState state, TaskList? list) {
    showDialog(
      context: ctx,
      builder: (_) => ListEditorDialog(taskList: list),
    );
  }

  void _showFolderEditor(BuildContext ctx, AppState state, Folder? folder) {
    showDialog(
      context: ctx,
      builder: (_) => FolderEditorDialog(folder: folder),
    );
  }

  void _showSmartListEditor(BuildContext ctx, AppState state) {
    showDialog(context: ctx, builder: (_) => const SmartListEditorDialog());
  }

  void _showSmartListMenu(BuildContext ctx, AppState state, SmartList sl) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: ctx,
                  builder: (_) => SmartListEditorDialog(smartList: sl),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                state.deleteSmartList(sl.id);
                if (_selectedSmartListId == sl.id) {
                  setState(() {
                    _selectedSmartListId = builtInSmartLists.first.id;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showListMenu(BuildContext ctx, AppState state, TaskList list) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _showListEditor(ctx, state, list);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                state.deleteList(list.id);
                if (_selectedListId == list.id) {
                  setState(() {
                    _selectedListId = state.lists.isNotEmpty
                        ? state.lists.first.id
                        : null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderMenu(BuildContext ctx, AppState state, Folder folder) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showFolderEditor(ctx, state, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                state.deleteFolder(folder.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _HoverTrailingTile extends StatefulWidget {
  final Widget Function(bool isHovered) child;
  const _HoverTrailingTile({super.key, required this.child});

  @override
  State<_HoverTrailingTile> createState() => _HoverTrailingTileState();
}

class _HoverTrailingTileState extends State<_HoverTrailingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.child(_isHovered),
    );
  }
}

class _SwipeToEdit extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;

  const _SwipeToEdit({required this.child, required this.onEdit});

  @override
  State<_SwipeToEdit> createState() => _SwipeToEditState();
}

class _SwipeToEditState extends State<_SwipeToEdit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragOffset = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_animating) return;
    final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, double.infinity);
    setState(() => _dragOffset = newOffset);
  }

  void _onDragEnd(DragEndDetails details, double maxWidth) {
    if (_animating) return;
    final triggered = _dragOffset > maxWidth * 0.5;
    _snapBack(andThen: triggered ? widget.onEdit : null);
  }

  void _snapBack({VoidCallback? andThen}) {
    _animating = true;
    final start = _dragOffset;
    _animation = Tween<Offset>(
      begin: Offset(start, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
          _animating = false;
        });
      }
      andThen?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final offset = _animating ? _animation.value.dx : _dragOffset;
        final progress = (offset / maxWidth).clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (d) => _onDragEnd(d, maxWidth),
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  color: Color.lerp(
                    Colors.transparent,
                    Theme.of(context).colorScheme.primary,
                    progress,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              // Foreground sliding tile
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final dx = _animating ? _animation.value.dx : _dragOffset;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}
