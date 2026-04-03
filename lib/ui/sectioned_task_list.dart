import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/smart_list.dart';
import '../state/app_state.dart';
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

  const SectionedTaskList({
    super.key,
    required this.sections,
    this.showListName = false,
    this.inputHint,
    this.onAddTask,
    this.onReorder,
    this.toggleDate,
  });

  @override
  State<SectionedTaskList> createState() => _SectionedTaskListState();
}

class _SectionedTaskListState extends State<SectionedTaskList> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _handleAddTask() {
    final title = _inputController.text.trim();
    if (title.isEmpty) return;
    widget.onAddTask?.call(title);
    _inputController.clear();
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final allEmpty = widget.sections.every((s) => s.tasks.isEmpty);

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
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks',
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
        Expanded(
          child: CustomScrollView(
            slivers: [
              for (var i = 0; i < widget.sections.length; i++)
                ..._buildSectionSlivers(i),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        ),
      ],
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
              ),
              onSubmitted: (_) => _handleAddTask(),
              onTapOutside: (_) => _inputFocus.unfocus(),
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

  List<Widget> _buildSectionSlivers(int sectionIndex) {
    final section = widget.sections[sectionIndex];
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

    if (widget.onReorder != null) {
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

  const TaskTile({
    required super.key,
    required this.task,
    required this.index,
    this.reorderable = false,
    this.showListName = false,
    this.toggleDate,
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
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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
                    child: Text(
                      key: _titleTextKey,
                      task.title,
                      style: TextStyle(
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                        color: completed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
            subtitle: _buildSubtitle(context, state),
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
            onTap: _startEditing,
          ),
        ),
      ),
    ),
    );
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
