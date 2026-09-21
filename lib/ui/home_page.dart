import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/task_list.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';
import '../utils/uuid128.dart';
import '../models/task.dart';
import 'task_list_view.dart';
import 'smart_list_view.dart';
import 'task_notes_panel.dart';
import 'list_editor_dialog.dart';
import 'folder_editor_dialog.dart';
import '../models/smart_list.dart';
import 'smart_list_editor_dialog.dart';
import 'tag_manager_dialog.dart';
import 'sync_settings_page.dart';
import 'search_view.dart';
import 'accent_theme.dart';
import 'side_panel.dart';

/// Whether a search covers every task or only the selected list.
enum SearchScope { global, list }

// ───── Side panel geometry ─────

const double _defaultSidePanelWidth = 280;
const double _minSidePanelWidth = 200;
const double _maxSidePanelWidth = 520;

/// The content area never shrinks below this, however wide the panel is
/// dragged, so a narrow window cannot squeeze the task list out of existence.
const double _minContentWidth = 320;

const double _defaultSmartListsHeight = 220;
const double _defaultListsHeight = 280;

/// A scrollable section always keeps enough room for roughly one row, so a
/// collapsed section stays visible and can be dragged back open.
const double _minSectionHeight = 44;

/// Storage keys for the geometry above.
const _sidePanelWidthKey = 'side_panel_width';
const _smartListsHeightKey = 'side_panel_smart_lists_height';
const _listsHeightKey = 'side_panel_lists_height';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uuid128? _selectedListId;
  Uuid128? _selectedSmartListId;
  Task? _selectedTask;
  double _notesPanelWidth = 360;
  double _overflow = 0.0;
  bool _isLockedLeft = false;
  bool _isLockedRight = false;
  Set<Uuid128> _expandedFolderIds = {};
  final _storageService = StorageService();

  /// Side panel geometry on wide layouts. The two scrollable sections are
  /// sized explicitly; the remaining sections are as tall as their content, so
  /// dragging a divider trades height between the two scrollers around it.
  double _sidePanelWidth = _defaultSidePanelWidth;
  double _smartListsHeight = _defaultSmartListsHeight;
  double _listsHeight = _defaultListsHeight;

  /// Search state. [_searchScope] decides whether the query runs over every
  /// task or only the list that was selected when search was opened.
  bool _searchActive = false;
  SearchScope _searchScope = SearchScope.global;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

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
      _storageService.loadDouble(_sidePanelWidthKey),
      _storageService.loadDouble(_smartListsHeightKey),
      _storageService.loadDouble(_listsHeightKey),
    ]);
    final ids = results[0] as Set<Uuid128>;
    final listId = results[1] as Uuid128?;
    final smartListId = results[2] as Uuid128?;
    final width = results[3] as double?;
    final smartListsHeight = results[4] as double?;
    final listsHeight = results[5] as double?;
    setState(() {
      _expandedFolderIds = ids;
      _selectedListId = listId;
      _selectedSmartListId = smartListId;
      _sidePanelWidth = (width ?? _defaultSidePanelWidth).clamp(
        _minSidePanelWidth,
        _maxSidePanelWidth,
      );
      _smartListsHeight = smartListsHeight ?? _defaultSmartListsHeight;
      _listsHeight = listsHeight ?? _defaultListsHeight;
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

  /// Written on drag end rather than on every frame of a drag.
  Future<void> _savePanelGeometry() async {
    await Future.wait([
      _storageService.saveDouble(_sidePanelWidthKey, _sidePanelWidth),
      _storageService.saveDouble(_smartListsHeightKey, _smartListsHeight),
      _storageService.saveDouble(_listsHeightKey, _listsHeight),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Opens the search field. A list-scoped search keeps the current list
  /// selected so closing search returns to exactly where the user was.
  void _openSearch(SearchScope scope, {bool closeDrawer = false}) {
    setState(() {
      _searchActive = true;
      _searchScope = scope;
      _searchController.clear();
      _searchQuery = '';
      _selectedTask = null;
    });
    if (closeDrawer && _isNarrow) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  /// Clears search state. Call inside an existing setState.
  void _exitSearch() {
    if (!_searchActive) return;
    _searchActive = false;
    _searchQuery = '';
    _searchController.clear();
    _searchFocus.unfocus();
  }

  void _closeSearch() {
    setState(() {
      _searchActive = false;
      _searchQuery = '';
      _searchController.clear();
      _selectedTask = null;
    });
    _searchFocus.unfocus();
  }

  /// The list a scoped search runs against, or null when searching globally.
  /// Smart lists have no single backing list, and a list deleted while search
  /// is open no longer resolves, so both fall back to a global search.
  Uuid128? _searchListId(AppState state) {
    if (_searchScope != SearchScope.list) return null;
    final id = _selectedListId;
    if (id == null || state.listById(id) == null) return null;
    return id;
  }

  /// The color the content area is themed around: the selected list's own
  /// color, or the smart list's. Null means "leave the app theme alone".
  Color? _accentColor(AppState state) {
    if (_selectedSmartListId != null) {
      return state.smartListById(_selectedSmartListId!)?.color;
    }
    if (_selectedListId != null) {
      return state.listById(_selectedListId!)?.color;
    }
    return null;
  }

  void _selectList(Uuid128 id) {
    setState(() {
      _selectedListId = id;
      _selectedSmartListId = null;
      _selectedTask = null;
      _exitSearch();
    });
    _storageService.saveSelectedListId(id);
    _storageService.saveSelectedSmartListId(null);
    if (_isNarrow) Navigator.pop(context);
  }

  void _selectSmartList(Uuid128 id) {
    setState(() {
      _selectedSmartListId = id;
      _selectedListId = null;
      _selectedTask = null;
      _exitSearch();
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
    // Only the content area picks up the accent; the drawer shows every list
    // at once, so tinting it to one of them would be misleading.
    final accent = _accentColor(state);

    if (_isNarrow) {
      // The drawer is built under the app theme and handed in from outside the
      // accented subtree, so it keeps the app's own colors.
      final appTheme = Theme.of(context);
      return AccentTheme(
        accent: accent,
        child: Builder(
          builder: (context) => Scaffold(
            appBar: _buildAppBar(context, state),
            drawer: Drawer(
              child: Theme(data: appTheme, child: drawer),
            ),
            body: _buildBody(context, state),
          ),
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _clampSidePanelWidth(constraints.maxWidth);
          return Row(
            children: [
              SizedBox(width: _sidePanelWidth, child: _buildSidePanel(state)),
              PanelResizeHandle(
                onDrag: (d) => _resizeSidePanel(d, constraints.maxWidth),
                onDragEnd: _savePanelGeometry,
              ),
              Expanded(
                child: AccentTheme(
                  accent: accent,
                  child: Builder(
                    builder: (context) => Column(
                      children: [
                        _buildWideAppBar(context, state),
                        Expanded(child: _buildBody(context, state)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Keeps the panel inside its own bounds and leaves the content area at
  /// least [_minContentWidth], which matters when the window is narrowed
  /// after the panel was dragged wide.
  void _clampSidePanelWidth(double available) {
    final maxWidth = (available - _minContentWidth).clamp(
      _minSidePanelWidth,
      _maxSidePanelWidth,
    );
    final clamped = _sidePanelWidth.clamp(_minSidePanelWidth, maxWidth);
    // Layout-time correction consumed later in this same build, so it is
    // applied directly rather than through setState.
    if (clamped != _sidePanelWidth) _sidePanelWidth = clamped;
  }

  /// Widens or narrows the panel by [delta], returning the travel that did
  /// not fit.
  double _resizeSidePanel(double delta, double available) {
    final maxWidth = (available - _minContentWidth).clamp(
      _minSidePanelWidth,
      _maxSidePanelWidth,
    );
    final before = _sidePanelWidth;
    setState(() {
      _sidePanelWidth = (_sidePanelWidth + delta).clamp(
        _minSidePanelWidth,
        maxWidth,
      );
    });
    return delta - (_sidePanelWidth - before);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppState state) {
    if (_searchActive) {
      return AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeSearch,
          tooltip: 'Close search',
        ),
        title: _buildSearchField(state),
      );
    }

    String title = _getAppBarTitle(state);
    return AppBar(
      title: Text(title),
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _openSearch(
            _selectedListId != null ? SearchScope.list : SearchScope.global,
          ),
          tooltip: _selectedListId != null ? 'Search this list' : 'Search',
        ),
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

  Widget _buildWideAppBar(BuildContext context, AppState state) {
    if (_searchActive) {
      return Container(
        height: 56,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _buildSearchField(state)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeSearch,
              tooltip: 'Close search',
            ),
          ],
        ),
      );
    }

    String title = _getAppBarTitle(state);
    return Container(
      height: 56,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(
              _selectedListId != null ? SearchScope.list : SearchScope.global,
            ),
            tooltip: _selectedListId != null ? 'Search this list' : 'Search',
          ),
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

  /// The search input, plus a chip to switch between searching the current
  /// list and searching everything.
  Widget _buildSearchField(AppState state) {
    final theme = Theme.of(context);
    final listName = _selectedListId != null
        ? state.listById(_selectedListId!)?.name
        : null;
    final scopedAvailable = listName != null;
    final scoped = _searchScope == SearchScope.list && scopedAvailable;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: scoped
                  ? 'Search in $listName...'
                  : 'Search all tasks...',
              border: InputBorder.none,
              isDense: true,
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _searchFocus.requestFocus();
                      },
                      tooltip: 'Clear',
                    ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        if (scopedAvailable) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: scoped
                ? 'Searching in $listName - tap to search everywhere'
                : 'Searching everywhere - tap to search in $listName',
            child: FilterChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  scoped ? listName : 'All',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              selected: scoped,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() {
                _searchScope = scoped ? SearchScope.global : SearchScope.list;
              }),
            ),
          ),
        ],
      ],
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

  /// The narrow-layout drawer: one plain scroller, since a phone has no room
  /// to give each section its own viewport.
  Widget _buildDrawer(AppState state) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Global search across every list.
                _buildSearchTile(closeDrawer: true),
                const Divider(),

                // Smart lists
                const _SectionHeader('SMART LISTS'),
                ..._buildSmartListItems(state),
                _buildAddSmartListTile(state),
                const Divider(),

                // Folders and lists
                const _SectionHeader('LISTS'),
                ..._buildFolderAndListItems(state),
                ..._buildAddListTiles(state),
                const Divider(),

                // Bottom actions
                ..._buildManagementTiles(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The wide-layout side panel: the same items, split into sections the user
  /// can resize against each other, with smart lists and lists each scrolling
  /// independently.
  Widget _buildSidePanel(AppState state) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Sections whose height follows their content. Measured from the
          // real row metrics so the two scrollers get exactly what is left.
          final tileHeight = _denseTileHeight(context);
          final searchHeight = tileHeight;
          final addListsHeight = tileHeight * 2;
          final managementHeight = tileHeight * 2;
          const headerHeight = 26.0; // section label
          const handleHeight = 9.0; // SectionResizeHandle

          final fixed =
              searchHeight +
              addListsHeight +
              managementHeight +
              headerHeight * 2 +
              handleHeight * 4;
          final flexible = constraints.maxHeight - fixed;

          // Too short to honour both minimums: fall back to a single scroller
          // so nothing overflows.
          if (flexible < _minSectionHeight * 2) {
            return _buildDrawer(state);
          }

          _clampSectionHeights(flexible);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: searchHeight,
                child: _buildSearchTile(closeDrawer: false),
              ),
              SectionResizeHandle(
                // Nothing above smart lists can resize, so this handle moves
                // the boundary the same way the one below it does.
                onDrag: (d) => _resizeSections(-d, flexible),
                onDragEnd: _savePanelGeometry,
              ),
              SizedBox(
                height: _smartListsHeight + headerHeight,
                child: PanelSection(
                  header: 'SMART LISTS',
                  headerActions: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'Add Smart List',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showSmartListEditor(context, state),
                    ),
                  ],
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _buildSmartListItems(state),
                  ),
                ),
              ),
              SectionResizeHandle(
                onDrag: (d) => _resizeSections(d, flexible),
                onDragEnd: _savePanelGeometry,
              ),
              SizedBox(
                height: _listsHeight + headerHeight,
                child: PanelSection(
                  header: 'LISTS',
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _buildFolderAndListItems(state),
                  ),
                ),
              ),
              SectionResizeHandle(
                // Below the lists section: dragging down grows LISTS at the
                // expense of SMART LISTS above it.
                onDrag: (d) => _resizeSections(-d, flexible),
                onDragEnd: _savePanelGeometry,
              ),
              SizedBox(
                height: addListsHeight,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _buildAddListTiles(state),
                ),
              ),
              SectionResizeHandle(
                // Same boundary again: the sections below it are sized by
                // their content, so this is the only height there is to give.
                onDrag: (d) => _resizeSections(-d, flexible),
                onDragEnd: _savePanelGeometry,
              ),
              SizedBox(
                height: managementHeight,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _buildManagementTiles(state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A dense [ListTile]'s height, which drives how tall the fixed sections
  /// need to be. Text scaling makes this larger, so it is measured rather
  /// than hard-coded.
  double _denseTileHeight(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(14);
    return (40.0 + (scaled - 14) * 1.5).clamp(40.0, 88.0);
  }

  /// Moves the smart-lists/lists boundary by [delta] and returns the travel
  /// that did not fit, so the handle knows how far past the end it went.
  double _resizeSections(double delta, double available) {
    final before = _smartListsHeight;
    setState(() {
      _smartListsHeight = (_smartListsHeight + delta).clamp(
        _minSectionHeight,
        available - _minSectionHeight,
      );
      _listsHeight = available - _smartListsHeight;
    });
    return delta - (_smartListsHeight - before);
  }

  /// Fits the stored section heights to the space actually available, which
  /// changes when the window is resized or the geometry is first restored.
  void _clampSectionHeights(double available) {
    final maxHeight = available - _minSectionHeight;
    var smart = _smartListsHeight;
    var lists = _listsHeight;

    if (smart + lists != available) {
      // Share the difference in proportion to the current split so a window
      // resize does not collapse one section into the other.
      final total = smart + lists;
      if (total <= 0) {
        smart = available / 2;
      } else {
        smart = available * (smart / total);
      }
    }
    smart = smart.clamp(_minSectionHeight, maxHeight);
    lists = available - smart;

    if (smart != _smartListsHeight || lists != _listsHeight) {
      // Layout-time correction, so apply it directly rather than via
      // setState; the values are consumed later in this same build.
      _smartListsHeight = smart;
      _listsHeight = lists;
    }
  }

  // ───── Side panel items, shared by the drawer and the wide panel ─────

  Widget _buildSearchTile({required bool closeDrawer}) {
    return ListTile(
      leading: const Icon(Icons.search, size: 20),
      title: const Text('Search'),
      selected: _searchActive && _searchScope == SearchScope.global,
      dense: true,
      onTap: () => _openSearch(SearchScope.global, closeDrawer: closeDrawer),
    );
  }

  List<Widget> _buildSmartListItems(AppState state) {
    return [
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
                      onPressed: () => _showSmartListMenu(context, state, sl),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                    )
                  : count > 0
                  ? Center(
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            selected: _selectedSmartListId == sl.id,
            onTap: () => _selectSmartList(sl.id),
            dense: true,
          ),
        );
      }),
    ];
  }

  Widget _buildAddSmartListTile(AppState state) {
    return ListTile(
      leading: const Icon(Icons.add, size: 20),
      title: const Text('Add Smart List'),
      dense: true,
      onTap: () => _showSmartListEditor(context, state),
    );
  }

  List<Widget> _buildAddListTiles(AppState state) {
    return [
      ListTile(
        leading: const Icon(Icons.add, size: 20),
        title: const Text('Add List'),
        dense: true,
        onTap: () => _showListEditor(context, state, null),
      ),
      ListTile(
        leading: const Icon(Icons.create_new_folder_outlined, size: 20),
        title: const Text('Add Folder'),
        dense: true,
        onTap: () => _showFolderEditor(context, state, null),
      ),
    ];
  }

  List<Widget> _buildManagementTiles(AppState state) {
    return [
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
            MaterialPageRoute(builder: (_) => const SyncSettingsPage()),
          );
        },
      ),
    ];
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
                  ? Center(
                      child: Text(
                        '$folderListCount',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
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
                    child: _buildListTile(
                      state,
                      e.value,
                      enableSwipe: false,
                      leadingIndent: 16,
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
        children: combinedWidgets
            .asMap()
            .entries
            .map(
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
            )
            .toList(),
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

  Widget _buildListTile(
    AppState state,
    TaskList list, {
    Key? key,
    bool enableSwipe = true,
    double leadingIndent = 0,
  }) {
    final count = state.tasks
        .where((t) => t.listId == list.id && !t.isCompleted)
        .length;
    return _HoverTrailingTile(
      key: key,
      child: (isHovered) {
        final tile = ListTile(
          contentPadding: EdgeInsets.only(left: 16 + leadingIndent, right: 24),
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
                ? Center(
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
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

  Widget _buildBody(BuildContext context, AppState state) {
    Widget listView;
    if (_searchActive) {
      listView = SearchView(
        query: _searchQuery,
        listId: _searchListId(state),
        selectedTaskId: _selectedTask?.id.toString(),
        onTaskSelected: (t) {
          setState(() => _selectedTask = t);
          if (_isNarrow) _showNotesPanelSheet(state, t);
        },
      );
    } else if (_selectedSmartListId != null) {
      final sl = state.smartListById(_selectedSmartListId!);
      if (sl != null) {
        listView = SmartListView(
          smartList: sl,
          selectedTaskId: _selectedTask?.id.toString(),
          onTaskSelected: (t) {
            setState(() => _selectedTask = t);
            if (_isNarrow) _showNotesPanelSheet(state, t);
          },
        );
      } else {
        listView = const Center(child: Text('Select a list'));
      }
    } else if (_selectedListId != null) {
      listView = TaskListView(
        listId: _selectedListId!,
        selectedTaskId: _selectedTask?.id.toString(),
        onTaskSelected: (t) {
          setState(() => _selectedTask = t);
          if (_isNarrow) _showNotesPanelSheet(state, t);
        },
      );
    } else {
      listView = const Center(child: Text('Select a list'));
    }

    final selectedTask = _selectedTask;
    if (!_isNarrow && selectedTask != null) {
      final freshTask = state.taskById(selectedTask.id);
      return LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: Row(
              children: [
                Expanded(child: listView),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      final minWidth = 300.0;
                      final maxWidth = constraints.maxWidth - 300.0;

                      double delta = -details.delta.dx;

                      // If locked, accumulate overflow instead of resizing
                      if (_isLockedLeft) {
                        _overflow += delta;

                        // Unlock only when cursor comes back
                        if (_overflow > 0) {
                          _isLockedLeft = false;
                          delta = _overflow;
                          _overflow = 0;
                        } else {
                          return; // Still outside → do nothing
                        }
                      }

                      if (_isLockedRight) {
                        _overflow += delta;

                        if (_overflow < 0) {
                          _isLockedRight = false;
                          delta = _overflow;
                          _overflow = 0;
                        } else {
                          return;
                        }
                      }

                      final newWidth = _notesPanelWidth + delta;

                      if (newWidth <= minWidth) {
                        _notesPanelWidth = minWidth;
                        _isLockedLeft = true;
                        _overflow = newWidth - minWidth; // negative overflow
                      } else if (newWidth >= maxWidth) {
                        _notesPanelWidth = maxWidth;
                        _isLockedRight = true;
                        _overflow = newWidth - maxWidth; // positive overflow
                      } else {
                        _notesPanelWidth = newWidth;
                      }
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: SizedBox(
                      width: 8,
                      child: VerticalDivider(
                        width: 2,
                        thickness: 2,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _notesPanelWidth,
                  child: freshTask != null
                      ? TaskNotesPanel(
                          key: ValueKey(freshTask.id),
                          task: freshTask,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      );
    }

    return listView;
  }

  void _showNotesPanelSheet(AppState state, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // The editor and preview scroll themselves, so a DraggableScrollableSheet
      // has nothing to drive its controller with; a tall fixed sheet plus the
      // handle gives the same reach with a drag target that actually works.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (ctx) => Padding(
        // Keep the editor above the on-screen keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: TaskNotesPanel(
            key: ValueKey(task.id),
            task: state.taskById(task.id) ?? task,
          ),
        ),
      ),
    );
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
    final newOffset = (_dragOffset + details.delta.dx).clamp(
      0.0,
      double.infinity,
    );
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

        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (d) => _onDragEnd(d, maxWidth),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = _animating ? _animation.value.dx : _dragOffset;
              final prog = ((dx / maxWidth) / 0.5).clamp(0.0, 1.0);
              return Stack(
                children: [
                  // Background — width and opacity track the drag offset
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: dx,
                    child: Container(
                      color: Theme.of(context).colorScheme.primary,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: Opacity(
                        opacity: prog,
                        child: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Foreground sliding tile
                  Transform.translate(offset: Offset(dx, 0), child: child),
                ],
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
