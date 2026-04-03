import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';

enum _PanelMode { edit, preview, split }

class TaskNotesPanel extends StatefulWidget {
  final Task task;

  const TaskNotesPanel({super.key, required this.task});

  @override
  State<TaskNotesPanel> createState() => _TaskNotesPanelState();
}

class _TaskNotesPanelState extends State<TaskNotesPanel> {
  late TextEditingController _notesCtrl;
  late TextEditingController _titleCtrl;
  _PanelMode _mode = _PanelMode.edit;
  bool _dirty = false;
  double _leftPaneWidth = 300;
  double _splitOverflow = 0.0;
  bool _splitLockedLeft = false;
  bool _splitLockedRight = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.task.notes);
    _titleCtrl = TextEditingController(text: widget.task.title);
    _notesCtrl.addListener(_onNotesChanged);
    _titleCtrl.addListener(_onNotesChanged);
  }

  @override
  void didUpdateWidget(TaskNotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _debounceTimer?.cancel();
      _save(context.read<AppState>());
      _notesCtrl.removeListener(_onNotesChanged);
      _titleCtrl.removeListener(_onNotesChanged);
      _notesCtrl.dispose();
      _titleCtrl.dispose();
      _notesCtrl = TextEditingController(text: widget.task.notes);
      _titleCtrl = TextEditingController(text: widget.task.title);
      _notesCtrl.addListener(_onNotesChanged);
      _titleCtrl.addListener(_onNotesChanged);
      _dirty = false;
      _mode = _PanelMode.edit;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesCtrl.removeListener(_onNotesChanged);
    _titleCtrl.removeListener(_onNotesChanged);
    _notesCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    setState(() => _dirty = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _save(context.read<AppState>());
    });
  }

  void _save(AppState state) {
    _debounceTimer?.cancel();
    if (!_dirty) return;
    final newTitle = _titleCtrl.text.trim();
    final newNotes = _notesCtrl.text;
    if (newTitle.isEmpty) return;
    final updated = state.copyTask(
      widget.task,
      previousTaskId: widget.task.previousTaskId,
      nextTaskId: widget.task.nextTaskId,
    );
    updated.title = newTitle;
    updated.notes = newNotes;
    state.updateTask(updated);
    _dirty = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Task title',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _save(state),
                      onTapOutside: (_) => _save(state),
                    ),
                  ),
                  if (_dirty)
                    TextButton(
                      onPressed: () => _save(state),
                      child: const Text('Save'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _ToolbarButton(
                    label: 'Edit',
                    active: _mode == _PanelMode.edit,
                    onTap: () => setState(() => _mode = _PanelMode.edit),
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    label: 'Preview',
                    active: _mode == _PanelMode.preview,
                    onTap: () {
                      _save(state);
                      setState(() => _mode = _PanelMode.preview);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    label: 'Split',
                    active: _mode == _PanelMode.split,
                    onTap: () => setState(() => _mode = _PanelMode.split),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: switch (_mode) {
            _PanelMode.edit => _buildEditor(state),
            _PanelMode.preview => _buildPreview(),
            _PanelMode.split => _buildSplit(state),
          },
        ),
      ],
    );
  }

  Widget _buildEditor(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final text = _notesCtrl.text;
          final sel = _notesCtrl.selection;

          if (event.logicalKey == LogicalKeyboardKey.tab) {
            const indent = '    ';
            final newText = text.replaceRange(sel.start, sel.end, indent);
            _notesCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset: sel.start + indent.length),
            );
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              sel.isCollapsed &&
              sel.start >= 4 &&
              text.substring(sel.start - 4, sel.start) == '    ') {
            final newText = text.replaceRange(sel.start - 4, sel.start, '');
            _notesCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: sel.start - 4),
            );
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _notesCtrl,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Write notes in Markdown...',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          onTapOutside: (_) => _save(state),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final notes = _notesCtrl.text;
    if (notes.trim().isEmpty) {
      return Center(
        child: Text(
          'No notes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Markdown(
      data: notes,
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildSplit(AppState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = 80.0;
        final maxWidth = constraints.maxWidth - 80.0;
        final leftWidth = _leftPaneWidth.clamp(minWidth, maxWidth);

        return Row(
          children: [
            SizedBox(width: leftWidth, child: _buildEditor(state)),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  double delta = details.delta.dx;

                  if (_splitLockedLeft) {
                    _splitOverflow += delta;
                    if (_splitOverflow > 0) {
                      _splitLockedLeft = false;
                      delta = _splitOverflow;
                      _splitOverflow = 0;
                    } else {
                      return;
                    }
                  }

                  if (_splitLockedRight) {
                    _splitOverflow += delta;
                    if (_splitOverflow < 0) {
                      _splitLockedRight = false;
                      delta = _splitOverflow;
                      _splitOverflow = 0;
                    } else {
                      return;
                    }
                  }

                  final newWidth = _leftPaneWidth + delta;

                  if (newWidth <= minWidth) {
                    _leftPaneWidth = minWidth;
                    _splitLockedLeft = true;
                    _splitOverflow = newWidth - minWidth;
                  } else if (newWidth >= maxWidth) {
                    _leftPaneWidth = maxWidth;
                    _splitLockedRight = true;
                    _splitOverflow = newWidth - maxWidth;
                  } else {
                    _leftPaneWidth = newWidth;
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
            Expanded(child: _buildPreview()),
          ],
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
