import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/smart_list.dart';
import '../models/task_search.dart';
import '../state/app_state.dart';
import 'highlighted_text.dart';
import 'task_editor_dialog.dart';

/// A common task list component that displays tasks organized in sections.
class SectionedTaskList extends StatefulWidget {
  /// The sections of tasks to display.
  final List<TaskSection> sections;

  /// Whether to show the list name in each task tile's subtitle.
  final bool showListName;

  /// Hint text for the input field. If null, no input field is shown.
  final String? inputHint;

  /// Callback when a new task is created via the input field.
  final void Function(String title)? onAddTask;

  /// Callback when tasks in a section are reordered. If null, reordering is disabled.
  final void Function(int sectionIndex, int oldIndex, int newIndex)? onReorder;

  /// The date to use for recurring task completion toggle.
  final DateTime? toggleDate;

  /// The currently selected task id (for highlighting).
  final String? selectedTaskId;

  /// Callback when a task is selected (tapped).
  final void Function(Task task)? onTaskSelected;

  /// Message shown when there are no tasks to display.
  final String emptyMessage;

  /// Icon shown alongside [emptyMessage].
  final IconData emptyIcon;

  /// Builds the tile subtitle. Falls back to the default subtitle when null.
  final Widget? Function(BuildContext context, Task task)? subtitleBuilder;

  /// Builds the tile title. Falls back to plain text when null.
  final Widget? Function(BuildContext context, Task task, TextStyle? style)?
  titleBuilder;

  /// Whether typing in the add-task field filters the list as you type.
  ///
  /// This is how you find a task inside a list: rather than a separate search
  /// mode, the box you would type a new task into narrows the list to what
  /// already matches, so an existing duplicate shows up before you add a
  /// second copy of it. Only meaningful alongside [inputHint].
  final bool filterWhileTyping;

  const SectionedTaskList({
    super.key,
    required this.sections,
    this.showListName = false,
    this.inputHint,
    this.onAddTask,
    this.onReorder,
    this.toggleDate,
    this.selectedTaskId,
    this.onTaskSelected,
    this.emptyMessage = 'No tasks',
    this.emptyIcon = Icons.inbox_outlined,
    this.subtitleBuilder,
    this.titleBuilder,
    this.filterWhileTyping = false,
  });

  @override
  State<SectionedTaskList> createState() => _SectionedTaskListState();
}

class _SectionedTaskListState extends State<SectionedTaskList> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  /// What is currently typed in the add-task field, when that field filters.
  String _filter = '';

  /// The terms [_filter] tokenizes to. Empty means "not filtering".
  List<String> _terms = const [];

  /// The sections actually rendered: [widget.sections] when idle, the matching
  /// subset while the user is typing.
  late List<TaskSection> _visibleSections = widget.sections;

  bool get _filtering => _terms.isNotEmpty;

  @override
  void didUpdateWidget(SectionedTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tasks themselves changed under us (an edit, a sync, a toggle), so
    // the filtered view has to be recomputed against the new data.
    if (!identical(oldWidget.sections, widget.sections) ||
        oldWidget.filterWhileTyping != widget.filterWhileTyping) {
      _recomputeSections();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    if (!widget.filterWhileTyping) return;
    if (value == _filter) return;
    _filter = value;
    _terms = TaskSearch.tokenize(value);
    setState(_recomputeSections);
  }

  /// Rebuilds [_visibleSections] from the current filter.
  ///
  /// Matching runs per section rather than over one flat list so a section's
  /// meaning (Completed, or a smart list's own grouping) survives filtering:
  /// an already-done duplicate still shows up, under its own header.
  void _recomputeSections() {
    if (!widget.filterWhileTyping || !_filtering) {
      _visibleSections = widget.sections;
      return;
    }

    final state = context.read<AppState>();
    final filtered = <TaskSection>[];
    for (final section in widget.sections) {
      if (section.tasks.isEmpty) continue;
      final results = TaskSearch.search(
        _filter,
        tasks: section.tasks,
        tags: state.tags,
        lists: state.lists,
        includeListNames: widget.showListName,
      );
      if (results.isEmpty) continue;
      filtered.add(
        TaskSection(
          header: section.header,
          tasks: [for (final r in results) r.task],
        ),
      );
    }
    _visibleSections = filtered;
  }

  void _handleAddTask() {
    final title = _inputController.text.trim();
    if (title.isEmpty) return;
    widget.onAddTask?.call(title);
    _inputController.clear();
    _onInputChanged('');
    _inputFocus.requestFocus();
  }

  void _clearFilter() {
    _inputController.clear();
    _onInputChanged('');
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections;
    final allEmpty = sections.every((s) => s.tasks.isEmpty);

    if (allEmpty) {
      return Column(
        children: [
          if (widget.inputHint != null) _buildInputField(context),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filtering ? Icons.search_off : widget.emptyIcon,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _filtering
                        ? 'No task matches - press Add to create it'
                        : widget.emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (widget.inputHint != null) _buildInputField(context),
        if (_filtering) _buildMatchBanner(context, sections),
        Expanded(
          child: CustomScrollView(
            slivers: [
              for (var i = 0; i < sections.length; i++)
                ..._buildSectionSlivers(i, sections[i]),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        ),
      ],
    );
  }

  /// Tells the user why the list shrank, and that these are existing tasks
  /// rather than a preview of what Add would create.
  Widget _buildMatchBanner(BuildContext context, List<TaskSection> sections) {
    final theme = Theme.of(context);
    final count = sections.fold<int>(0, (sum, s) => sum + s.tasks.length);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              count == 1
                  ? '1 existing task matches'
                  : '$count existing tasks match',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              decoration: InputDecoration(
                hintText: widget.inputHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: widget.filterWhileTyping && _filtering
                    ? const Icon(Icons.search, size: 18)
                    : null,
                suffixIcon: widget.filterWhileTyping && _filtering
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearFilter,
                        tooltip: 'Clear',
                      )
                    : null,
              ),
              onChanged: _onInputChanged,
              onSubmitted: (_) => _handleAddTask(),
              // Not unfocus-on-tap-outside while filtering: tapping a matching
              // task is how the user acts on what the filter found, and
              // dropping focus there would clear the field under them.
              onTapOutside: (_) {
                if (!_filtering) _inputFocus.unfocus();
              },
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _handleAddTask,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }

  /// Highlights the matched terms while filtering, otherwise defers to the
  /// caller's own title builder.
  Widget? Function(BuildContext, Task, TextStyle?)? get _titleBuilder {
    if (!_filtering) return widget.titleBuilder;
    return (context, task, style) =>
        HighlightedText(text: task.title, terms: _terms, style: style);
  }

  List<Widget> _buildSectionSlivers(int sectionIndex, TaskSection section) {
    if (section.tasks.isEmpty) return [];

    final slivers = <Widget>[];

    if (section.header != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              section.header!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Dragging is disabled while filtering: the visible indices address a
    // subset, so a drop position means nothing in the underlying order.
    if (widget.onReorder != null && !_filtering) {
      slivers.add(
        SliverReorderableList(
          itemCount: section.tasks.length,
          findChildIndexCallback: (key) {
            if (key is! ValueKey<String>) return null;
            final idx = section.tasks.indexWhere(
              (t) => '${sectionIndex}_${t.id}' == key.value,
            );
            return idx == -1 ? null : idx;
          },
          onReorder: (oldIndex, newIndex) =>
              widget.onReorder!.call(sectionIndex, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final task = section.tasks[index];
            return TaskTile(
              key: ValueKey('${sectionIndex}_${task.id}'),
              task: task,
              index: index,
              reorderable: true,
              showListName: widget.showListName,
              toggleDate: widget.toggleDate,
              selected: widget.selectedTaskId == task.id.toString(),
              onSelected: widget.onTaskSelected,
              subtitleBuilder: widget.subtitleBuilder,
              titleBuilder: _titleBuilder,
            );
          },
        ),
      );
    } else {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = section.tasks[index];
              return TaskTile(
                key: ValueKey('${sectionIndex}_${task.id}'),
                task: task,
                index: index,
                reorderable: false,
                showListName: widget.showListName,
                toggleDate: widget.toggleDate,
                selected: widget.selectedTaskId == task.id.toString(),
                onSelected: widget.onTaskSelected,
                subtitleBuilder: widget.subtitleBuilder,
                titleBuilder: _titleBuilder,
              );
            },
            childCount: section.tasks.length,
            findChildIndexCallback: (key) {
              if (key is! ValueKey<String>) return null;
              final idx = section.tasks.indexWhere(
                (t) => '${sectionIndex}_${t.id}' == key.value,
              );
              return idx == -1 ? null : idx;
            },
          ),
        ),
      );
    }

    return slivers;
  }
}

// ───── Common task tile ─────

class TaskTile extends StatefulWidget {
  final Task task;
  final int index;
  final bool reorderable;
  final bool showListName;
  final DateTime? toggleDate;
  final bool selected;
  final void Function(Task task)? onSelected;

  /// Overrides the tile subtitle when it returns a non-null widget.
  final Widget? Function(BuildContext context, Task task)? subtitleBuilder;

  /// Overrides the tile title when it returns a non-null widget.
  final Widget? Function(BuildContext context, Task task, TextStyle? style)?
  titleBuilder;

  const TaskTile({
    required super.key,
    required this.task,
    required this.index,
    this.reorderable = false,
    this.showListName = false,
    this.toggleDate,
    this.selected = false,
    this.onSelected,
    this.subtitleBuilder,
    this.titleBuilder,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _titleTextKey = GlobalKey();
  Offset? _tapDownPosition;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveTitle();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    int cursorOffset = _controller.text.length;
    final tapPos = _tapDownPosition;
    if (tapPos != null) {
      final ro = _titleTextKey.currentContext?.findRenderObject();
      if (ro is RenderParagraph) {
        final localOffset = ro.globalToLocal(tapPos);
        cursorOffset = ro.getPositionForOffset(localOffset).offset;
      }
      _tapDownPosition = null;
    }
    _controller.selection = TextSelection.collapsed(offset: cursorOffset);
    setState(() => _isEditing = true);
  }

  void _saveTitle() {
    if (!mounted) return;
    _focusNode.unfocus();

    final state = context.read<AppState>();
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.task.title) {
      final updated = state.copyTask(
        widget.task,
        previousTaskId: widget.task.previousTaskId,
        nextTaskId: widget.task.nextTaskId,
      );
      updated.title = newTitle;
      state.updateTask(updated);
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _showEditDialog(BuildContext context, Offset position) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return TaskEditorDialog(
          listId: widget.task.listId,
          existingTask: widget.task,
          clickPosition: position,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final task = widget.task;
    final isRecurring = task.recurrence != null;
    final completed = isRecurring && widget.toggleDate != null
        ? task.isCompletedOn(widget.toggleDate!)
        : task.isCompleted;

    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey(task.id),
        // Swipe-to-delete is disabled: horizontal drags interfere with
        // selecting the task title text.
        direction: DismissDirection.none,
        onDismissed: (_) => state.deleteTask(task.id),
        child: Listener(
          onPointerDown: (event) {
            if (event.buttons == 2) {
              _showEditDialog(context, event.position);
            }
          },
          child: GestureDetector(
            onSecondaryTapDown: (details) {},
            onSecondaryTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.reorderable) ...[
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Checkbox(
                    value: completed,
                    onChanged: (_) =>
                        state.toggleTask(task, onDate: widget.toggleDate),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              title: _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _saveTitle(),
                      onTapOutside: (_) => _saveTitle(),
                    )
                  : Listener(
                      onPointerDown: (event) {
                        _tapDownPosition = event.position;
                      },
                      child: _buildTitle(context, completed),
                    ),
              subtitle:
                  widget.subtitleBuilder?.call(context, task) ??
                  _buildSubtitle(context, state),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.scheduledDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        DateFormat.MMMd().format(task.scheduledDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  IconButton(
                    key: _moreButtonKey,
                    icon: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final RenderBox button =
                          _moreButtonKey.currentContext!.findRenderObject()
                              as RenderBox;
                      final Offset buttonPosition = button.localToGlobal(
                        Offset.zero,
                      );
                      _showEditDialog(
                        context,
                        Offset(
                          buttonPosition.dx,
                          buttonPosition.dy + button.size.height,
                        ),
                      );
                    },
                  ),
                ],
              ),
              selected: widget.selected,
              onTap: () {
                widget.onSelected?.call(widget.task);
                _startEditing();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool completed) {
    final style = TextStyle(
      decoration: completed ? TextDecoration.lineThrough : null,
      color: completed ? Theme.of(context).colorScheme.onSurfaceVariant : null,
    );
    final custom = widget.titleBuilder?.call(context, widget.task, style);
    if (custom != null) return custom;
    return Text(key: _titleTextKey, widget.task.title, style: style);
  }

  Widget? _buildSubtitle(BuildContext context, AppState state) {
    final parts = <Widget>[];

    if (widget.showListName) {
      final listName = state.listById(widget.task.listId)?.name ?? '';
      if (listName.isNotEmpty) {
        parts.add(
          Text(
            listName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
    }

    final tagWidgets = widget.task.tagIds
        .map((id) => state.tagById(id))
        .where((t) => t != null)
        .map(
          (t) => Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: t!.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(t.name, style: TextStyle(fontSize: 11, color: t.color)),
          ),
        )
        .toList();

    if (tagWidgets.isNotEmpty) {
      parts.add(Row(mainAxisSize: MainAxisSize.min, children: tagWidgets));
    }

    if (parts.isEmpty) return null;
    return Wrap(spacing: 8, children: parts);
  }
}
