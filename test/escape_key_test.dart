import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/state/app_state.dart';
import 'package:todopen/ui/home_page.dart';
import 'package:todopen/ui/sectioned_task_list.dart';
import 'package:todopen/ui/task_notes_panel.dart';
import 'package:todopen/utils/uuid128.dart';

/// Escape backs out of one level at a time.
///
/// The levels are owned by different widgets - the add-task field clears its
/// own filter, the notes editor drops its own focus, and only what is left
/// over reaches the page - so each one is driven through the real widget that
/// owns it. What goes stale silently is the *order*: a level that starts
/// consuming Escape too eagerly traps the user one screen deeper than they
/// asked to be, with no other symptom.

final _listId = Uuid128.generateV4();

/// `AppState.tags`/`lists` read the replica, which only exists after `init()`
/// has touched drift. These widgets only need those two projections.
class _FakeAppState extends AppState {
  @override
  List<Tag> get tags => const [];
  @override
  List<TaskList> get lists => const [];
}

Task _task(String title) => Task(
  id: Uuid128.generateV4(),
  title: title,
  createdAt: DateTime(2026, 1, 1),
  listId: _listId,
);

Future<void> _escape(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

/// The task titles currently rendered, in order.
List<String> _visible(WidgetTester tester) => tester
    .widgetList<TaskTile>(find.byType(TaskTile))
    .map((t) => t.task.title)
    .toList();

void main() {
  group('the add-task field', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: _FakeAppState(),
          child: MaterialApp(
            home: Scaffold(
              body: SectionedTaskList(
                sections: [
                  TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
                ],
                inputHint: 'Add a task...',
                filterWhileTyping: true,
                onAddTask: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('clears the filter and restores the full list', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField).first, 'milk');
      await tester.pumpAndSettle();
      expect(_visible(tester), ['buy milk']);

      await _escape(tester);

      expect(_visible(tester), ['buy milk', 'call mum']);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, '');
    });

    testWidgets('keeps focus so the user can type again immediately', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField).first, 'milk');
      await tester.pumpAndSettle();

      await _escape(tester);

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.focusNode!.hasFocus, isTrue);
    });

    /// An empty field has nothing of its own left to clear, so the key has to
    /// keep bubbling - that is what lets the page close the notes panel or
    /// search from a field the user never typed into.
    testWidgets('lets Escape through once it is empty', (tester) async {
      var reachedPage = false;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: _FakeAppState(),
          child: MaterialApp(
            home: Shortcuts(
              shortcuts: searchShortcuts,
              child: Actions(
                actions: {
                  EscapeIntent: CallbackAction<EscapeIntent>(
                    onInvoke: (_) {
                      reachedPage = true;
                      return null;
                    },
                  ),
                },
                child: Scaffold(
                  body: SectionedTaskList(
                    sections: [
                      TaskSection(tasks: [_task('buy milk')]),
                    ],
                    inputHint: 'Add a task...',
                    filterWhileTyping: true,
                    onAddTask: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      await _escape(tester);

      expect(reachedPage, isTrue);
    });
  });

  group('the notes editor', () {
    Future<TextField> pump(
      WidgetTester tester, {
      required List<Intent> fired,
    }) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: _FakeAppState(),
          child: MaterialApp(
            home: Shortcuts(
              shortcuts: searchShortcuts,
              child: Actions(
                actions: {
                  EscapeIntent: CallbackAction<EscapeIntent>(
                    onInvoke: (i) {
                      fired.add(i);
                      return null;
                    },
                  ),
                },
                // The page's real pairing: a Focus that never takes primary
                // focus, plus the listener that catches keys once focus has
                // drifted above it - which is exactly where unfocusing the
                // editor leaves it.
                child: homePageFocusWrapper(
                  child: SearchShortcutListener(
                    child: Scaffold(body: TaskNotesPanel(task: _task('T'))),
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
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 16));
      return tester.widget<TextField>(finder);
    }

    /// The note stays on screen; only the caret leaves. Closing the panel on
    /// the first Escape would take the user two levels out at once.
    testWidgets('drops focus without reaching the page', (tester) async {
      final fired = <Intent>[];
      final field = await pump(tester, fired: fired);
      expect(field.focusNode!.hasFocus, isTrue);

      await _escape(tester);

      expect(field.focusNode!.hasFocus, isFalse);
      expect(fired, isEmpty, reason: 'the panel keeps the first Escape');
    });

    testWidgets('a second Escape reaches the page', (tester) async {
      final fired = <Intent>[];
      await pump(tester, fired: fired);

      await _escape(tester);
      await _escape(tester);

      expect(fired, [isA<EscapeIntent>()]);
    });
  });

  group('the shortcut map', () {
    testWidgets('binds a bare Escape', (tester) async {
      final fired = <Intent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Shortcuts(
            shortcuts: searchShortcuts,
            child: Actions(
              actions: {
                EscapeIntent: CallbackAction<EscapeIntent>(
                  onInvoke: (i) => fired.add(i),
                ),
              },
              child: const Focus(
                autofocus: true,
                child: Scaffold(body: SizedBox.expand()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _escape(tester);

      expect(fired, [isA<EscapeIntent>()]);
    });

    /// The global listener resolves the same map off the raw key stream, for
    /// when focus sits above the page entirely.
    test('resolves Escape off a raw key event', () {
      final intent = matchSearchShortcut(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.escape,
          logicalKey: LogicalKeyboardKey.escape,
          timeStamp: Duration.zero,
        ),
      );
      expect(intent, isA<EscapeIntent>());
    });
  });
}
