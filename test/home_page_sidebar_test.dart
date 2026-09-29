import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/services/app_database.dart';
import 'package:todopen/state/app_state.dart';
import 'package:todopen/ui/home_page.dart';

/// The wide side panel is only rebuilt when something it shows changes; the
/// rest of the time the page hands back the widget it built last. These
/// drive the real page over the real app state, so a change that the panel
/// should show but that its cache does not notice fails here rather than
/// going stale silently on screen.
void main() {
  late AppDatabase db;
  late AppState state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Deep links have no platform side under test; an idle stream will do.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('com.llfbandit.app_links/events'),
          MockStreamHandler.inline(onListen: (_, _) {}),
        );
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.useForTesting(db);
  });

  tearDown(() async {
    AppDatabase.useForTesting(null);
    await db.close();
  });

  /// The page's own storage reads and the app state's debounced writes are
  /// real async work, so they get real time to finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    state = AppState();
    await tester.runAsync(state.init);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await settle(tester);
  }

  /// Lets the app state's debounce timers run out, so none is left pending
  /// when the test ends.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
  }

  /// The count badge on [list]'s sidebar row, or null when it shows none.
  String? badge(WidgetTester tester, String list) {
    final row = find.ancestor(
      of: find.text(list),
      matching: find.byType(ListTile),
    );
    final texts = tester
        .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
        .map((t) => t.data)
        .where((d) => d != null && int.tryParse(d) != null);
    return texts.isEmpty ? null : texts.single;
  }

  Task newTask(TaskList list, String title) => Task(
    id: state.newId(),
    title: title,
    createdAt: DateTime(2026, 1, 1),
    listId: list.id,
  );

  testWidgets('shows lists as they are added, renamed and removed', (
    tester,
  ) async {
    await pumpPage(tester);
    final list = TaskList(id: state.newId(), name: 'Groceries');

    await state.addList(list);
    await tester.pump();
    expect(find.text('Groceries'), findsOneWidget);

    final renamed = state.listById(list.id)!..name = 'Shopping';
    await state.updateList(renamed);
    await tester.pump();
    expect(find.text('Groceries'), findsNothing);
    expect(find.text('Shopping'), findsOneWidget);

    await state.deleteList(list.id);
    await tester.pump();
    expect(find.text('Shopping'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('keeps list counts current as tasks change', (tester) async {
    await pumpPage(tester);
    final list = TaskList(id: state.newId(), name: 'Groceries');
    await state.addList(list);
    await tester.pump();
    expect(badge(tester, 'Groceries'), isNull);

    final milk = newTask(list, 'milk');
    await state.addTask(milk);
    await state.addTask(newTask(list, 'eggs'));
    await tester.pump();
    expect(badge(tester, 'Groceries'), '2');

    await state.toggleTask(state.taskById(milk.id)!);
    await tester.pump();
    expect(badge(tester, 'Groceries'), '1');

    await state.deleteTask(milk.id);
    await state.toggleTask(state.tasksForList(list.id).single);
    await tester.pump();
    expect(badge(tester, 'Groceries'), isNull);
    await drainTimers(tester);
  });

  testWidgets('is not rebuilt by a change it does not show', (tester) async {
    await pumpPage(tester);
    final list = TaskList(id: state.newId(), name: 'Groceries');
    await state.addList(list);
    await state.addTask(newTask(list, 'milk'));
    await tester.pump();

    ListTile row() => tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Groceries'),
        matching: find.byType(ListTile),
      ),
    );
    // The first layout fits the stored section heights to the window, which
    // the panel has to be rebuilt once to pick up. Let that settle first.
    Future<void> renameTask(String title) async {
      final task = state.tasksForList(list.id).single..title = title;
      await state.updateTask(task);
      await tester.pump();
    }

    await renameTask('milk 2');
    final before = row();

    // A title edit changes the task list but nothing in the sidebar.
    await renameTask('oat milk');
    expect(identical(row(), before), isTrue);

    // Adding a task changes the count, so now the row must be rebuilt.
    await state.addTask(newTask(list, 'eggs'));
    await tester.pump();
    expect(identical(row(), before), isFalse);
    expect(badge(tester, 'Groceries'), '2');
    await drainTimers(tester);
  });
}
