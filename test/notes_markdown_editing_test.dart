import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/state/app_state.dart';
import 'package:todopen/ui/task_notes_panel.dart';
import 'package:todopen/utils/uuid128.dart';

/// The notes panel rewrites the text field itself for the toolbar, Tab and
/// list-continuation behaviours. Those rewrites compute offsets by hand, so an
/// off-by-one silently eats a character or drops the caret in the wrong place.
///
/// These drive the real widget rather than the helpers, because the selection
/// state they depend on only exists once a TextField owns the controller.
///
/// The panel autosaves on an 800ms debounce and `AppState` here is never
/// initialised, so each test stays well inside that window and pumps with an
/// explicit short duration instead of `pumpAndSettle`.
void main() {
  Task makeTask({String notes = ''}) => Task(
    id: Uuid128.generateV4(),
    title: 'Task',
    notes: notes,
    createdAt: DateTime(2026, 1, 1),
    listId: Uuid128.generateV4(),
  );

  /// Mounts the panel wide enough that the Split mode chip is offered.
  Future<TextEditingController> pumpPanel(
    WidgetTester tester, {
    String notes = '',
    double width = 900,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: TaskNotesPanel(task: makeTask(notes: notes)),
          ),
        ),
      ),
    );

    // The notes field is the only one the panel renders.
    final field = tester.widget<TextField>(
      find.byWidgetPredicate((w) => w is TextField && w.maxLines == null),
    );
    return field.controller!;
  }

  /// Places the caret / selection, then taps a toolbar button by tooltip.
  Future<void> tapTool(
    WidgetTester tester,
    TextEditingController ctrl,
    String tooltip, {
    required TextSelection selection,
  }) async {
    ctrl.selection = selection;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byTooltip(tooltip));
    await tester.pump(const Duration(milliseconds: 16));
  }

  group('inline wrapping', () {
    testWidgets('bold wraps the selection and keeps it selected', (
      tester,
    ) async {
      final ctrl = await pumpPanel(tester, notes: 'hello world');
      await tapTool(
        tester,
        ctrl,
        'Bold  (Ctrl+B)',
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      expect(ctrl.text, '**hello** world');
      // Still wrapping the original word, so a second tap can undo it.
      expect(ctrl.selection.textInside(ctrl.text), 'hello');
    });

    testWidgets('bold twice returns the original text', (tester) async {
      final ctrl = await pumpPanel(tester, notes: 'hello world');
      const sel = TextSelection(baseOffset: 0, extentOffset: 5);
      await tapTool(tester, ctrl, 'Bold  (Ctrl+B)', selection: sel);
      // Unwrapping relies on the markers sitting just outside the selection
      // the first toggle left behind.
      await tapTool(tester, ctrl, 'Bold  (Ctrl+B)', selection: ctrl.selection);

      expect(ctrl.text, 'hello world');
    });

    testWidgets('unwraps when the markers are inside the selection', (
      tester,
    ) async {
      final ctrl = await pumpPanel(tester, notes: '**hello** world');
      await tapTool(
        tester,
        ctrl,
        'Bold  (Ctrl+B)',
        selection: const TextSelection(baseOffset: 0, extentOffset: 9),
      );

      expect(ctrl.text, 'hello world');
    });

    testWidgets('empty selection inserts a pair with the caret between', (
      tester,
    ) async {
      final ctrl = await pumpPanel(tester, notes: 'ab');
      await tapTool(
        tester,
        ctrl,
        'Italic  (Ctrl+I)',
        selection: const TextSelection.collapsed(offset: 1),
      );

      expect(ctrl.text, 'a__b');
      expect(ctrl.selection.baseOffset, 2);
      expect(ctrl.selection.isCollapsed, isTrue);
    });
  });

  group('block prefixes', () {
    testWidgets('bullets every line the selection touches', (tester) async {
      final ctrl = await pumpPanel(tester, notes: 'one\ntwo\nthree');
      await tapTool(
        tester,
        ctrl,
        'Bulleted list',
        // Starts mid-first-line and ends mid-second: both lines count.
        selection: const TextSelection(baseOffset: 1, extentOffset: 5),
      );

      expect(ctrl.text, '- one\n- two\nthree');
    });

    testWidgets('numbering counts up across the block', (tester) async {
      final ctrl = await pumpPanel(tester, notes: 'a\nb\nc');
      await tapTool(
        tester,
        ctrl,
        'Numbered list',
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      expect(ctrl.text, '1. a\n2. b\n3. c');
    });

    testWidgets('re-applying the same prefix strips it', (tester) async {
      final ctrl = await pumpPanel(tester, notes: 'one\ntwo');
      const sel = TextSelection(baseOffset: 0, extentOffset: 7);
      await tapTool(tester, ctrl, 'Bulleted list', selection: sel);
      expect(ctrl.text, '- one\n- two');

      await tapTool(
        tester,
        ctrl,
        'Bulleted list',
        selection: const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      expect(ctrl.text, 'one\ntwo');
    });

    testWidgets('a new block style replaces the old marker', (tester) async {
      final ctrl = await pumpPanel(tester, notes: '- one');
      await tapTool(
        tester,
        ctrl,
        'Quote',
        selection: const TextSelection.collapsed(offset: 5),
      );

      // Not '> - one': the bullet is consumed rather than stacked.
      expect(ctrl.text, '> one');
    });

    testWidgets('task list marker survives the heading strip', (tester) async {
      final ctrl = await pumpPanel(tester, notes: '## title');
      await tapTool(
        tester,
        ctrl,
        'Task list',
        selection: const TextSelection.collapsed(offset: 8),
      );

      expect(ctrl.text, '- [ ] title');
    });
  });

  group('links', () {
    testWidgets('selection becomes the label and url is pre-selected', (
      tester,
    ) async {
      final ctrl = await pumpPanel(tester, notes: 'docs here');
      await tapTool(
        tester,
        ctrl,
        'Link  (Ctrl+K)',
        selection: const TextSelection(baseOffset: 0, extentOffset: 4),
      );

      expect(ctrl.text, '[docs](url) here');
      expect(ctrl.selection.textInside(ctrl.text), 'url');
    });

    testWidgets('empty selection gets a placeholder label', (tester) async {
      final ctrl = await pumpPanel(tester);
      await tapTool(
        tester,
        ctrl,
        'Link  (Ctrl+K)',
        selection: const TextSelection.collapsed(offset: 0),
      );

      expect(ctrl.text, '[text](url)');
      expect(ctrl.selection.textInside(ctrl.text), 'url');
    });
  });

  group('mode switching', () {
    testWidgets('a wide panel offers Split', (tester) async {
      await pumpPanel(tester, width: 900);
      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('a narrow panel hides Split', (tester) async {
      await pumpPanel(tester, width: 420);
      expect(find.text('Split'), findsNothing);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('preview hides the format bar and renders the markdown', (
      tester,
    ) async {
      await pumpPanel(tester, notes: '# Heading');
      expect(find.byTooltip('Bold  (Ctrl+B)'), findsOneWidget);

      await tester.tap(find.text('Preview'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byTooltip('Bold  (Ctrl+B)'), findsNothing);
      expect(find.textContaining('Heading'), findsWidgets);
    });

    testWidgets('empty notes show the preview placeholder', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Preview'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Nothing to preview yet'), findsOneWidget);
    });
  });

  group('word count', () {
    testWidgets('counts words and stays hidden when empty', (tester) async {
      await pumpPanel(tester);
      expect(find.textContaining('word'), findsNothing);

      final ctrl = await pumpPanel(tester, notes: 'one two three');
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('3 words'), findsOneWidget);

      // Singular gets its own label rather than "1 words".
      ctrl.text = 'one';
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('1 word'), findsOneWidget);
    });
  });

  group('layout', () {
    // The header packs save status, mode chips and a word count into one
    // row, and the format bar holds eleven controls. Both have to survive a
    // phone-width bottom sheet without overflowing.
    for (final width in <double>[320, 360, 420, 560, 900]) {
      testWidgets('renders without overflow at ${width.toInt()}px', (
        tester,
      ) async {
        await pumpPanel(
          tester,
          notes: 'Some notes with enough words to show a count',
          width: width,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('preview renders rich markdown without overflow', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        width: 360,
        notes: '''
# Title

Body with **bold**, _italic_ and `code`.

- [ ] a task
- [x] a done task

> a quote

```
fenced code
```

| a | b |
| - | - |
| 1 | 2 |

[a link](https://example.com)
''',
      );
      await tester.tap(find.text('Preview'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Title'), findsWidgets);
    });

    testWidgets('does not render the task title', (tester) async {
      // The title belongs to the task list; showing it here duplicated it and
      // ate a row of vertical space above the editor.
      await pumpPanel(tester, notes: 'body');
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Task'), findsNothing);
      expect(find.widgetWithText(TextField, 'Task title'), findsNothing);
      // Exactly one field: the notes body.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('editor keeps its position when the save status changes', (
      tester,
    ) async {
      // The status used to swap a tall button for a short label, which resized
      // the header and shunted the editor down every time an autosave landed.
      // Asserting on the editor's size and origin covers both directions: the
      // header growing pushes it down, and it shrinking to compensate.
      final ctrl = await pumpPanel(tester, notes: 'body');
      final editor = find.byType(TextField);
      final cleanOrigin = tester.getTopLeft(editor);
      final cleanSize = tester.getSize(editor);

      // Dirty: the unsaved indicator is showing.
      ctrl.text = 'body edited';
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.getTopLeft(editor),
        cleanOrigin,
        reason: 'the unsaved indicator must not move the editor',
      );
      expect(
        tester.getSize(editor),
        cleanSize,
        reason: 'the unsaved indicator must not resize the editor',
      );

      // And back again, the way an autosave completing would leave it.
      ctrl.text = 'body';
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(editor), cleanOrigin);
      expect(tester.getSize(editor), cleanSize);
    });

    testWidgets('split view shows editor and preview together', (tester) async {
      await pumpPanel(tester, notes: '# Heading', width: 900);
      await tester.tap(find.text('Split'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      // The raw source stays visible on the left while the right renders it.
      expect(find.byTooltip('Bold  (Ctrl+B)'), findsOneWidget);
      expect(find.textContaining('Heading'), findsWidgets);
    });
  });
}
