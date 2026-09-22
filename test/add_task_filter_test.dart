import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todopen/models/smart_list.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/state/app_state.dart';
import 'package:todopen/ui/sectioned_task_list.dart';
import 'package:todopen/utils/uuid128.dart';

/// Typing in the add-task field filters the list it would add to.
///
/// The point is duplicate detection: before you add "buy milk" a second time,
/// the one already there - pending or completed - is on screen. These drive
/// the real widget rather than the filter function alone, because the
/// behaviour only exists in the typing lifecycle: what the field does on
/// change, on submit, and what reordering does while a filter is active.

final _listId = Uuid128.generateV4();

/// `AppState.tags`/`lists` read the replica, which only exists after `init()`
/// has touched drift. Filtering only needs those two projections, so this
/// stands in for them.
class _FakeAppState extends AppState {
  @override
  List<Tag> get tags => const [];
  @override
  List<TaskList> get lists => const [];
}

Task _task(String title, {bool completed = false, String notes = ''}) => Task(
  id: Uuid128.generateV4(),
  title: title,
  createdAt: DateTime(2026, 1, 1),
  listId: _listId,
  isCompleted: completed,
  notes: notes,
);

Widget _app(
  List<TaskSection> sections, {
  void Function(String title)? onAddTask,
  void Function(int, int, int)? onReorder,
  bool filterWhileTyping = true,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: _FakeAppState(),
    child: MaterialApp(
      home: Scaffold(
        body: SectionedTaskList(
          sections: sections,
          inputHint: 'Add a task...',
          filterWhileTyping: filterWhileTyping,
          onAddTask: onAddTask ?? (_) {},
          onReorder: onReorder,
        ),
      ),
    ),
  );
}

/// The task titles currently rendered, in order.
List<String> _visible(WidgetTester tester) => tester
    .widgetList<TaskTile>(find.byType(TaskTile))
    .map((t) => t.task.title)
    .toList();

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing narrows the list to matching tasks', (tester) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'milk');
    expect(_visible(tester), ['buy milk']);
  });

  testWidgets('an already-completed duplicate still surfaces', (tester) async {
    // The whole point: a task you already did is exactly the one you are
    // about to add again by mistake.
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('call mum')]),
        TaskSection(
          header: 'Completed',
          tasks: [_task('buy milk', completed: true)],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'milk');
    expect(_visible(tester), ['buy milk']);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('matches notes, not just titles', (tester) async {
    await tester.pumpWidget(
      _app([
        TaskSection(
          tasks: [
            _task('groceries', notes: 'remember the milk'),
            _task('gym'),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'milk');
    expect(_visible(tester), ['groceries']);
  });

  testWidgets('every term must match, so more words narrow further', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('buy bread')]),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'buy');
    expect(_visible(tester), hasLength(2));
    await _type(tester, 'buy milk');
    expect(_visible(tester), ['buy milk']);
  });

  testWidgets('clearing the field restores the whole list', (tester) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'milk');
    expect(_visible(tester), hasLength(1));
    await _type(tester, '');
    expect(_visible(tester), hasLength(2));
  });

  testWidgets('a query matching nothing explains how to add it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk')]),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'wash the car');
    expect(_visible(tester), isEmpty);
    expect(find.textContaining('press Add'), findsOneWidget);
  });

  testWidgets('submitting still adds the task and clears the filter', (
    tester,
  ) async {
    final added = <String>[];
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
      ], onAddTask: added.add),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'wash the car');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(added, ['wash the car']);
    // The filter must not survive the add, or the new task would be hidden
    // behind a stale query.
    expect(_visible(tester), hasLength(2));
  });

  testWidgets('dragging is disabled while filtering', (tester) async {
    // A drop index addresses the filtered subset, so it means nothing in the
    // underlying order; reordering has to wait until the filter clears.
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('buy bread')]),
      ], onReorder: (a, b, c) {}),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));
    await _type(tester, 'buy milk');
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    await _type(tester, '');
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));
  });

  testWidgets('the count of existing matches is shown', (tester) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('buy bread')]),
      ]),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'buy');
    expect(find.text('2 existing tasks match'), findsOneWidget);
    await _type(tester, 'buy milk');
    expect(find.text('1 existing task matches'), findsOneWidget);
  });

  testWidgets('does nothing when the list has not opted in', (tester) async {
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
      ], filterWhileTyping: false),
    );
    await tester.pumpAndSettle();

    await _type(tester, 'milk');
    expect(_visible(tester), hasLength(2));
  });

  testWidgets('a task edited away from the query drops out of the filter', (
    tester,
  ) async {
    // Sections are rebuilt by the parent on every AppState change; the
    // filtered view has to track that rather than hold the old result.
    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('buy milk'), _task('call mum')]),
      ]),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'milk');
    expect(_visible(tester), ['buy milk']);

    await tester.pumpWidget(
      _app([
        TaskSection(tasks: [_task('call mum')]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(_visible(tester), isEmpty);
  });
}
