import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/state/app_state.dart';
import 'package:todopen/ui/home_page.dart';
import 'package:todopen/ui/task_notes_panel.dart';
import 'package:todopen/utils/uuid128.dart';

/// Ctrl+F / Ctrl+Shift+F open search scoped to the list or to everything.
///
/// `HomePage` itself needs the drift database to mount, so these drive the
/// real shortcut map from `home_page.dart` over a stand-in for the page. That
/// keeps the part that actually goes stale — which chord maps to which intent,
/// and that the shift variant is not shadowed by the plain one — under test.
void main() {
  /// Presses [key] with the given modifiers held, the way a user would.
  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    LogicalKeyboardKey? modifier,
    bool shift = false,
  }) async {
    if (modifier != null) await tester.sendKeyDownEvent(modifier);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (modifier != null) await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  /// Mounts the app's real shortcut map over a recorder, optionally with a
  /// focused text field, since search must be reachable while typing.
  Future<List<Intent>> harness(
    WidgetTester tester, {
    bool withTextField = false,
  }) async {
    final fired = <Intent>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Shortcuts(
          shortcuts: searchShortcuts,
          child: Actions(
            actions: {
              SearchListIntent: CallbackAction<SearchListIntent>(
                onInvoke: (i) => fired.add(i),
              ),
              SearchAllIntent: CallbackAction<SearchAllIntent>(
                onInvoke: (i) => fired.add(i),
              ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                body: withTextField
                    ? const TextField(autofocus: true)
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fired;
  }

  testWidgets('Ctrl+F asks for a list-scoped search', (tester) async {
    final fired = await harness(tester);
    await press(
      tester,
      LogicalKeyboardKey.keyF,
      modifier: LogicalKeyboardKey.controlLeft,
    );

    expect(fired, [isA<SearchListIntent>()]);
  });

  testWidgets('Ctrl+Shift+F asks for a global search', (tester) async {
    final fired = await harness(tester);
    await press(
      tester,
      LogicalKeyboardKey.keyF,
      modifier: LogicalKeyboardKey.controlLeft,
      shift: true,
    );

    // The plain Ctrl+F binding must not swallow the shift variant.
    expect(fired, [isA<SearchAllIntent>()]);
  });

  testWidgets('Cmd+F and Cmd+Shift+F work for macOS muscle memory', (
    tester,
  ) async {
    final fired = await harness(tester);
    await press(
      tester,
      LogicalKeyboardKey.keyF,
      modifier: LogicalKeyboardKey.metaLeft,
    );
    await press(
      tester,
      LogicalKeyboardKey.keyF,
      modifier: LogicalKeyboardKey.metaLeft,
      shift: true,
    );

    expect(fired, [isA<SearchListIntent>(), isA<SearchAllIntent>()]);
  });

  testWidgets('fires while a text field has focus', (tester) async {
    final fired = await harness(tester, withTextField: true);
    await press(
      tester,
      LogicalKeyboardKey.keyF,
      modifier: LogicalKeyboardKey.controlLeft,
    );

    expect(fired, [isA<SearchListIntent>()]);
  });

  testWidgets('a bare F is left to the focused field', (tester) async {
    final fired = await harness(tester, withTextField: true);
    await press(tester, LogicalKeyboardKey.keyF);

    expect(fired, isEmpty);
  });

  /// The page wraps everything in `Focus(autofocus: true)` so Ctrl+F works
  /// before anything has been clicked. That Focus sits above the notes
  /// editor's own key handling, which owns Tab and Ctrl+B — if it ever starts
  /// swallowing those, indenting and bold break with no other symptom.
  testWidgets("does not swallow the notes editor's own keys", (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: AppState(),
        child: MaterialApp(
          home: Shortcuts(
            shortcuts: searchShortcuts,
            child: Actions(
              actions: {
                SearchListIntent: CallbackAction<SearchListIntent>(
                  onInvoke: (_) => null,
                ),
                SearchAllIntent: CallbackAction<SearchAllIntent>(
                  onInvoke: (_) => null,
                ),
              },
              child: Focus(
                autofocus: true,
                child: Scaffold(
                  body: TaskNotesPanel(
                    task: Task(
                      id: Uuid128.generateV4(),
                      title: 'T',
                      notes: 'hello',
                      createdAt: DateTime(2026, 1, 1),
                      listId: Uuid128.generateV4(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final finder = find.byWidgetPredicate(
      (w) => w is TextField && w.maxLines == null,
    );
    final ctrl = tester.widget<TextField>(finder).controller!;
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 16));
    ctrl.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump(const Duration(milliseconds: 16));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 16));
    expect(ctrl.text, '    hello', reason: 'Tab still indents');

    // Ctrl+B must still reach the editor, not be eaten above it.
    ctrl.selection = const TextSelection(baseOffset: 4, extentOffset: 9);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      ctrl.text,
      contains('**hello**'),
      reason: 'Ctrl+B still reaches editor',
    );
  });

  /// The page-level `Focus` exists so Ctrl+F works before anything is
  /// clicked. It must not take primary focus itself: if it does, it outranks
  /// the `autofocus` on the add-task field, the field never becomes primary,
  /// and its arrow keys (held or tapped) never move the caret.
  testWidgets('page Focus does not steal arrow keys from a text field', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);
    final fired = <Intent>[];
    final pageFocus = homePageFocusWrapper();

    await tester.pumpWidget(
      MaterialApp(
        home: Shortcuts(
          shortcuts: searchShortcuts,
          child: Actions(
            actions: {
              SearchListIntent: CallbackAction<SearchListIntent>(
                onInvoke: (i) => fired.add(i),
              ),
              SearchAllIntent: CallbackAction<SearchAllIntent>(
                onInvoke: (i) => fired.add(i),
              ),
            },
            // The real page's wrapper, read out of home_page.dart rather
            // than restated here, so this fails if that widget regresses.
            child: Focus(
              autofocus: pageFocus.autofocus,
              canRequestFocus: pageFocus.canRequestFocus,
              child: Scaffold(
                body: TextField(controller: controller, autofocus: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      controller.selection.baseOffset,
      4,
      reason: 'a tapped arrow moves the caret',
    );

    // Holding the key: one down plus repeats, as the embedder delivers it.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      controller.selection.baseOffset,
      0,
      reason: 'a held arrow keeps moving the caret on each repeat',
    );

    // And the shortcut the wrapper exists for still fires.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(fired, isNotEmpty, reason: 'Ctrl+F still reaches the shortcut');
  });
}
