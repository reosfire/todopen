import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import 'markdown_styles.dart';

enum _PanelMode { edit, preview, split }

class TaskNotesPanel extends StatefulWidget {
  final Task task;

  const TaskNotesPanel({super.key, required this.task});

  @override
  State<TaskNotesPanel> createState() => _TaskNotesPanelState();
}

class _TaskNotesPanelState extends State<TaskNotesPanel> {
  /// Below this there is no room for two readable columns, so the mode
  /// switcher drops Split instead of offering a view that cannot work.
  static const double _splitMinPanelWidth = 560;

  late TextEditingController _notesCtrl;
  final FocusNode _notesFocus = FocusNode();
  final ScrollController _previewScroll = ScrollController();

  /// Word count is the only header element that tracks every keystroke, so it
  /// listens to this instead of the panel calling `setState` on each one. A
  /// panel-wide rebuild mid-keystroke is what used to reset the IME composing
  /// region and throw the caret around on Android.
  final ValueNotifier<String> _notesWordCountText = ValueNotifier<String>('');

  /// Captured in `didChangeDependencies` so `dispose` can flush a pending
  /// edit without touching `context`, which is illegal by then.
  AppState? _savedState;

  /// The last text this panel itself wrote to the store. An incoming task
  /// carrying exactly this is our own save echoing back, and must not be
  /// pushed into the controller — doing so is what reset the selection.
  String? _lastSavedNotes;

  /// Ties the format bar to the notes field so toolbar presses do not read as
  /// taps outside it. Instance-scoped, so two panels never share a group.
  final Object _editorTapGroup = Object();
  _PanelMode _mode = _PanelMode.edit;
  bool _dirty = false;
  bool _showSaved = false;
  double _leftPaneWidth = 360;
  double _splitOverflow = 0.0;
  bool _splitLockedLeft = false;
  bool _splitLockedRight = false;
  Timer? _debounceTimer;
  Timer? _savedFlashTimer;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.task.notes);
    _lastSavedNotes = widget.task.notes;
    _notesWordCountText.value = widget.task.notes;
    _notesCtrl.addListener(_onNotesChanged);
    _notesFocus.addListener(_onFocusChanged);
  }

  /// Leaving the field commits immediately rather than waiting out the
  /// debounce — the edit is clearly finished at that point.
  void _onFocusChanged() {
    if (!_notesFocus.hasFocus && mounted) {
      _save(context.read<AppState>());
    }
  }

  /// Writes a pending edit during teardown.
  ///
  /// `dispose` cannot touch `context`, and `_save` reaches for `setState`, so
  /// this performs the store write directly and leaves the UI alone.
  void _flushPendingSave() {
    final state = _savedState;
    if (state == null) return;
    final notes = _notesCtrl.text;
    if (notes == widget.task.notes) return;
    // Teardown must not throw: an exception escaping `dispose` takes the whole
    // element tree down, and a failed last-moment save is not worth that.
    // `updateTask` is async, so its failure arrives on the future rather than
    // here — both paths need swallowing.
    try {
      final updated = state.copyTask(
        widget.task,
        previousTaskId: widget.task.previousTaskId,
        nextTaskId: widget.task.nextTaskId,
      );
      updated.notes = notes;
      unawaited(state.updateTask(updated).catchError((Object _) {}));
    } catch (_) {
      // Store unavailable (not yet initialised, or already torn down).
    }
    _dirty = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _savedState = context.read<AppState>();
  }

  @override
  void didUpdateWidget(TaskNotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      // A different task entirely: flush the old one, then start clean.
      _debounceTimer?.cancel();
      _save(context.read<AppState>(), task: oldWidget.task);
      _notesCtrl.removeListener(_onNotesChanged);
      _notesCtrl.dispose();
      _notesCtrl = TextEditingController(text: widget.task.notes);
      _notesCtrl.addListener(_onNotesChanged);
      _lastSavedNotes = widget.task.notes;
      _notesWordCountText.value = widget.task.notes;
      _dirty = false;
      _mode = _PanelMode.edit;
      return;
    }

    // Same task, new object. The parent watches AppState and rebuilds with a
    // freshly mapped Task on every notify — including the one our own save
    // triggers. Writing that back into the controller would move the caret,
    // so only genuinely foreign edits (a sync landing while the field is not
    // being typed into) are allowed through.
    final incoming = widget.task.notes;
    if (incoming != _notesCtrl.text &&
        incoming != _lastSavedNotes &&
        !_dirty &&
        !_notesFocus.hasFocus) {
      _notesCtrl.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
      _lastSavedNotes = incoming;
      _notesWordCountText.value = incoming;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _savedFlashTimer?.cancel();
    // Closing the panel or sheet inside the debounce window would otherwise
    // drop the last edit on the floor.
    if (_dirty) {
      _flushPendingSave();
    }
    _notesCtrl.removeListener(_onNotesChanged);
    _notesCtrl.dispose();
    _notesWordCountText.dispose();
    _notesFocus.removeListener(_onFocusChanged);
    _notesFocus.dispose();
    _previewScroll.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    // Word count is pushed to its own listener rather than rebuilding the
    // panel: a `setState` here would rebuild the TextField on every keystroke.
    _notesWordCountText.value = _notesCtrl.text;

    // Live preview does need the panel to rebuild, but only in the modes that
    // actually show one.
    final needsPreviewRebuild = _mode != _PanelMode.edit;

    if (!_dirty) {
      _dirty = true;
      // First keystroke since the last save flips the status indicator.
      setState(() => _showSaved = false);
    } else if (needsPreviewRebuild) {
      setState(() {});
    }

    // Idle-based: the timer restarts on each keystroke, so a save only lands
    // once typing actually pauses, never in the middle of a burst.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _save(context.read<AppState>());
    });
  }

  /// Persists the note. [task] defaults to the current one; `didUpdateWidget`
  /// passes the outgoing task when flushing a switch.
  void _save(AppState state, {Task? task}) {
    _debounceTimer?.cancel();
    if (!_dirty) return;
    final target = task ?? widget.task;
    final newNotes = _notesCtrl.text;

    // Nothing actually changed — skip the write so we do not spin AppState
    // (and every widget watching it) for a no-op.
    if (newNotes == target.notes) {
      _dirty = false;
      return;
    }

    final updated = state.copyTask(
      target,
      previousTaskId: target.previousTaskId,
      nextTaskId: target.nextTaskId,
    );
    // The title belongs to the task list; the panel only owns the note body.
    updated.notes = newNotes;
    _lastSavedNotes = newNotes;
    state.updateTask(updated);
    _dirty = false;

    // "Saved" lingers a moment so an autosave is actually visible, then fades
    // rather than sitting there as permanent chrome.
    if (mounted) {
      setState(() => _showSaved = true);
      _savedFlashTimer?.cancel();
      _savedFlashTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSaved = false);
      });
    }
  }

  // ───── Markdown editing actions ─────

  /// Wraps the selection in [token], or unwraps it when it is already wrapped.
  /// With nothing selected it inserts the pair and parks the caret between.
  void _toggleWrap(String token) {
    final text = _notesCtrl.text;
    final sel = _notesCtrl.selection;
    if (!sel.isValid) return;
    final start = sel.start;
    final end = sel.end;
    final n = token.length;

    // Markers just outside the selection: the common case after a previous
    // toggle left the inner text selected.
    final wrappedOutside = start >= n &&
        end + n <= text.length &&
        text.substring(start - n, start) == token &&
        text.substring(end, end + n) == token;
    if (wrappedOutside) {
      final stripped =
          text.replaceRange(end, end + n, '').replaceRange(start - n, start, '');
      _setText(
        stripped,
        TextSelection(baseOffset: start - n, extentOffset: end - n),
      );
      return;
    }

    final selected = text.substring(start, end);
    if (selected.length >= 2 * n &&
        selected.startsWith(token) &&
        selected.endsWith(token)) {
      final inner = selected.substring(n, selected.length - n);
      _setText(
        text.replaceRange(start, end, inner),
        TextSelection(baseOffset: start, extentOffset: start + inner.length),
      );
      return;
    }

    _setText(
      text.replaceRange(start, end, '$token$selected$token'),
      selected.isEmpty
          ? TextSelection.collapsed(offset: start + n)
          : TextSelection(baseOffset: start + n, extentOffset: end + n),
    );
  }

  /// Applies [build] to every line the selection touches, toggling the prefix
  /// back off when all of those lines already carry it.
  void _toggleLinePrefix(String Function(int indexInBlock) build) {
    final text = _notesCtrl.text;
    final sel = _notesCtrl.selection;
    if (!sel.isValid) return;

    final lineStart =
        text.lastIndexOf('\n', sel.start > 0 ? sel.start - 1 : 0) + 1;
    var lineEnd = text.indexOf('\n', sel.end);
    if (lineEnd == -1) lineEnd = text.length;

    final lines = text.substring(lineStart, lineEnd).split('\n');
    final prefixes = [for (var i = 0; i < lines.length; i++) build(i)];

    var allPrefixed = true;
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith(prefixes[i])) {
        allPrefixed = false;
        break;
      }
    }

    final updated = <String>[
      for (var i = 0; i < lines.length; i++)
        allPrefixed
            ? lines[i].substring(prefixes[i].length)
            : '${prefixes[i]}${_stripBlockPrefix(lines[i])}',
    ];

    final replacement = updated.join('\n');
    _setText(
      text.replaceRange(lineStart, lineEnd, replacement),
      TextSelection.collapsed(offset: lineStart + replacement.length),
    );
  }

  /// Strips an existing heading / bullet / numbered / quote / task marker so a
  /// new block style replaces the old one instead of stacking on top of it.
  static String _stripBlockPrefix(String line) {
    return line.replaceFirst(
      RegExp(r'^\s*(?:#{1,6} +|> ?|[-*+] +(?:\[[ xX]\] +)?|\d+\. +)'),
      '',
    );
  }

  void _insertLink() {
    final text = _notesCtrl.text;
    final sel = _notesCtrl.selection;
    if (!sel.isValid) return;
    final selected = text.substring(sel.start, sel.end);
    final label = selected.isEmpty ? 'text' : selected;
    _setText(
      text.replaceRange(sel.start, sel.end, '[$label](url)'),
      // Land on `url`: the part that always has to be typed is pre-selected.
      TextSelection(
        baseOffset: sel.start + label.length + 3,
        extentOffset: sel.start + label.length + 6,
      ),
    );
  }

  void _setText(String text, TextSelection selection) {
    _notesCtrl.value = TextEditingValue(text: text, selection: selection);
    _notesFocus.requestFocus();
  }

  // ───── Editor key handling ─────

  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Escape leaves the editor rather than closing the panel: the note is
    // still on screen, and dropping focus here is what commits the pending
    // save. A second Escape, now that nothing in the panel has focus, reaches
    // the page and closes it. Handled above the selection guard below, since
    // leaving the field does not depend on where the caret is.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _notesFocus.unfocus();
      return KeyEventResult.handled;
    }

    final text = _notesCtrl.text;
    final sel = _notesCtrl.selection;
    if (!sel.isValid) return KeyEventResult.ignored;

    final accel = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (accel) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyB:
          _toggleWrap('**');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyI:
          _toggleWrap('_');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyK:
          _insertLink();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyS:
          _save(context.read<AppState>());
          return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      const indent = '    ';
      _setText(
        text.replaceRange(sel.start, sel.end, indent),
        TextSelection.collapsed(offset: sel.start + indent.length),
      );
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter && sel.isCollapsed) {
      final continued = _continueList(text, sel.start);
      if (continued) return KeyEventResult.handled;
      return KeyEventResult.ignored;
    }

    // Backspace eats a full four-space indent so Tab and Backspace agree.
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        sel.isCollapsed &&
        sel.start >= 4 &&
        text.substring(sel.start - 4, sel.start) == '    ') {
      _setText(
        text.replaceRange(sel.start - 4, sel.start, ''),
        TextSelection.collapsed(offset: sel.start - 4),
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Carries the current list marker onto the next line. An empty item ends
  /// the list instead of laying down another bullet, which is what every other
  /// Markdown editor does and what muscle memory expects.
  ///
  /// Returns false when the caret is not in a list, leaving Enter alone.
  bool _continueList(String text, int caret) {
    final lineStart = text.lastIndexOf('\n', caret > 0 ? caret - 1 : 0) + 1;
    final line = text.substring(lineStart, caret);
    final match =
        RegExp(r'^([ \t]*)([-*+]|\d+\.) +(\[[ xX]\] +)?').firstMatch(line);
    if (match == null) return false;

    if (line.substring(match.end).trim().isEmpty) {
      _setText(
        text.replaceRange(lineStart, caret, ''),
        TextSelection.collapsed(offset: lineStart),
      );
      return true;
    }

    final indent = match[1]!;
    final marker = match[2]!;
    final checkbox = match[3] == null ? '' : '[ ] ';
    final nextMarker = marker.endsWith('.')
        ? '${(int.tryParse(marker.substring(0, marker.length - 1)) ?? 0) + 1}.'
        : marker;
    final insert = '\n$indent$nextMarker $checkbox';
    _setText(
      text.replaceRange(caret, caret, insert),
      TextSelection.collapsed(offset: caret + insert.length),
    );
    return true;
  }

  // ───── Build ─────

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final splitAllowed = constraints.maxWidth >= _splitMinPanelWidth;
        // Falling back on a narrow panel keeps `_mode` intact, so widening the
        // panel again restores the split the user had chosen.
        final mode = (!splitAllowed && _mode == _PanelMode.split)
            ? _PanelMode.edit
            : _mode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(state, mode, splitAllowed),
            if (mode != _PanelMode.preview) _buildFormatBar(),
            Expanded(
              child: switch (mode) {
                _PanelMode.edit => _buildEditor(state),
                _PanelMode.preview => _buildPreview(),
                _PanelMode.split => _buildSplit(state, constraints),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppState state, _PanelMode mode, bool splitAllowed) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      // A single row: the title lives in the task list, not here, so the
      // panel opens straight onto the note itself.
      child: Row(
        children: [
          _ModeSwitcher(
            mode: mode,
            splitAllowed: splitAllowed,
            onChanged: (next) {
              if (next == _PanelMode.preview) _save(state);
              setState(() => _mode = next);
            },
          ),
          // The switcher keeps its intrinsic width; on a narrow phone the
          // word count is the part that gives way rather than overflowing.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _WordCount(text: _notesWordCountText),
            ),
          ),
          const SizedBox(width: 8),
          _SaveStatus(
            dirty: _dirty,
            showSaved: _showSaved,
            onSave: () => _save(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBar() {
    final theme = Theme.of(context);
    return TapRegion(
      // Shares the editor's group so pressing a format button is not treated
      // as tapping outside the field — otherwise every button press would
      // unfocus the editor and flush a save mid-edit.
      groupId: _editorTapGroup,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        // Horizontally scrollable so the bar degrades gracefully in the
        // narrow bottom sheet instead of overflowing.
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            _FormatButton(
              icon: Icons.format_bold,
              tooltip: 'Bold  (Ctrl+B)',
              onTap: () => _toggleWrap('**'),
            ),
            _FormatButton(
              icon: Icons.format_italic,
              tooltip: 'Italic  (Ctrl+I)',
              onTap: () => _toggleWrap('_'),
            ),
            _FormatButton(
              icon: Icons.strikethrough_s,
              tooltip: 'Strikethrough',
              onTap: () => _toggleWrap('~~'),
            ),
            _FormatButton(
              icon: Icons.code,
              tooltip: 'Inline code',
              onTap: () => _toggleWrap('`'),
            ),
            const _FormatDivider(),
            _FormatButton(
              icon: Icons.title,
              tooltip: 'Heading',
              onTap: () => _toggleLinePrefix((_) => '## '),
            ),
            _FormatButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bulleted list',
              onTap: () => _toggleLinePrefix((_) => '- '),
            ),
            _FormatButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered list',
              onTap: () => _toggleLinePrefix((i) => '${i + 1}. '),
            ),
            _FormatButton(
              icon: Icons.checklist,
              tooltip: 'Task list',
              onTap: () => _toggleLinePrefix((_) => '- [ ] '),
            ),
            _FormatButton(
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onTap: () => _toggleLinePrefix((_) => '> '),
            ),
            const _FormatDivider(),
            _FormatButton(
              icon: Icons.link,
              tooltip: 'Link  (Ctrl+K)',
              onTap: _insertLink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(AppState state) {
    return Focus(
      onKeyEvent: _handleEditorKey,
      child: TextField(
        controller: _notesCtrl,
        focusNode: _notesFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorWidth: 2,
        groupId: _editorTapGroup,
        scrollPadding: const EdgeInsets.all(40),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Write notes in Markdown…',
          isDense: true,
          contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 24),
        ),
        style: TextStyle(
          fontFamily: kNotesMonoFamily,
          fontSize: 14,
          height: 1.55,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        // Losing focus is a natural commit point, but the save runs on the
        // focus change below rather than here, so an unrelated tap cannot
        // flush a write while the caret is still in the field.
        onTapOutside: (_) => _notesFocus.unfocus(),
      ),
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);
    final notes = _notesCtrl.text;

    if (notes.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notes_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing to preview yet',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Markdown(
      data: notes,
      controller: _previewScroll,
      selectable: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      styleSheet: notesMarkdownStyleSheet(context),
      // GitHub-flavored, so task lists, tables and strikethrough render the
      // way people habitually write them in notes.
      extensionSet: md.ExtensionSet.gitHubFlavored,
      softLineBreak: true,
      onTapLink: (text, href, title) => _openLink(href),
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    var opened = false;
    if (uri != null) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $href')),
      );
    }
  }

  Widget _buildSplit(AppState state, BoxConstraints constraints) {
    const minWidth = 240.0;
    const handleWidth = 9.0;
    final maxWidth = constraints.maxWidth - minWidth - handleWidth;
    final leftWidth = _leftPaneWidth.clamp(minWidth, maxWidth);
    final theme = Theme.of(context);

    return ClipRect(
      child: Row(
        children: [
          SizedBox(width: leftWidth, child: _buildEditor(state)),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
              child: SizedBox(
                width: handleWidth,
                child: Center(
                  child: Container(width: 1, color: theme.dividerColor),
                ),
              ),
            ),
          ),
          // A slightly recessed reading column separates rendered output from
          // the editor without drawing another hard border.
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerLowest,
              child: _buildPreview(),
            ),
          ),
        ],
      ),
    );
  }
}

// ───── Header pieces ─────

/// Save state, rendered at a fixed size in every state.
///
/// The earlier version swapped a full-height button for a short label, which
/// changed the header's height and shunted the editor up and down each time an
/// autosave landed. This is a constant-size square in all three states, so the
/// status can change without moving a pixel of the editor below it. It is
/// icon-only for the same reason: a text label's width depends on the label,
/// and that reintroduced the same class of jitter sideways.
class _SaveStatus extends StatelessWidget {
  final bool dirty;
  final bool showSaved;
  final VoidCallback onSave;

  static const double _size = 28;

  const _SaveStatus({
    required this.dirty,
    required this.showSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final Widget content;
    if (dirty) {
      // An unsaved dot, not a button: autosave is coming either way, and a
      // tap still forces it for anyone who wants the reassurance.
      content = Icon(
        Icons.circle,
        key: const ValueKey('unsaved'),
        size: 8,
        color: muted.withValues(alpha: 0.7),
      );
    } else if (showSaved) {
      content = Icon(
        Icons.check_circle_outline,
        key: const ValueKey('saved'),
        size: 15,
        color: muted,
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey('idle'));
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: Tooltip(
        message: dirty ? 'Unsaved changes  (Ctrl+S)' : 'All changes saved',
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: dirty ? onSave : null,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            // Cross-fade rather than swap, so the status settles quietly
            // instead of blinking at the edge of vision while typing.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Word and character count, driven straight off the controller text.
///
/// Listening to a notifier keeps the count live without the panel rebuilding
/// the editor on every keystroke.
class _WordCount extends StatelessWidget {
  final ValueListenable<String> text;

  const _WordCount({required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return ValueListenableBuilder<String>(
      valueListenable: text,
      builder: (context, value, _) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();
        final words = trimmed.split(RegExp(r'\s+')).length;
        return Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Text(
            words == 1 ? '1 word' : '$words words',
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: style,
          ),
        );
      },
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final _PanelMode mode;
  final bool splitAllowed;
  final ValueChanged<_PanelMode> onChanged;

  const _ModeSwitcher({
    required this.mode,
    required this.splitAllowed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = <(_PanelMode, IconData, String)>[
      (_PanelMode.edit, Icons.edit_outlined, 'Edit'),
      (_PanelMode.preview, Icons.visibility_outlined, 'Preview'),
      if (splitAllowed)
        (_PanelMode.split, Icons.vertical_split_outlined, 'Split'),
    ];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, icon, label) in modes)
            _ModeChip(
              icon: icon,
              label: label,
              active: mode == value,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = active
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                active ? theme.colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───── Format bar pieces ─────

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FormatDivider extends StatelessWidget {
  const _FormatDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}
