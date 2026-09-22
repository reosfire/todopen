import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/models/task_search.dart';
import 'package:todopen/utils/uuid128.dart';

final _listA = TaskList(id: Uuid128.generateV4(), name: 'Groceries');
final _listB = TaskList(id: Uuid128.generateV4(), name: 'Work');
final _urgent = Tag(id: Uuid128.generateV4(), name: 'urgent');

Task _task(
  String title, {
  String notes = '',
  bool isCompleted = false,
  TaskList? list,
  Set<Uuid128>? tagIds,
  DateTime? createdAt,
}) {
  return Task(
    id: Uuid128.generateV4(),
    title: title,
    notes: notes,
    isCompleted: isCompleted,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    listId: (list ?? _listA).id,
    tagIds: tagIds,
  );
}

List<String> _titles(List<TaskSearchResult> results) =>
    results.map((r) => r.task.title).toList();

List<TaskSearchResult> _search(
  String query,
  List<Task> tasks, {
  bool includeListNames = true,
}) => TaskSearch.search(
  query,
  tasks: tasks,
  tags: [_urgent],
  lists: [_listA, _listB],
  includeListNames: includeListNames,
);

void main() {
  group('tokenize', () {
    test('splits on whitespace and lowercases', () {
      expect(TaskSearch.tokenize('  Buy   MILK '), ['buy', 'milk']);
    });

    test('empty query yields no terms', () {
      expect(TaskSearch.tokenize('   '), isEmpty);
    });
  });

  group('search', () {
    test('empty query returns nothing', () {
      expect(_search('  ', [_task('buy milk')]), isEmpty);
    });

    test('matches title case-insensitively', () {
      final results = _search('MILK', [_task('Buy milk'), _task('Buy bread')]);
      expect(_titles(results), ['Buy milk']);
    });

    test('matches partial words', () {
      final results = _search('mil', [_task('Buy milk')]);
      expect(results, hasLength(1));
    });

    test('matches notes', () {
      final results = _search('receipt', [
        _task('Buy milk', notes: 'keep the receipt'),
      ]);
      expect(results.single.matchedNotes, isTrue);
      expect(results.single.matchedTitle, isFalse);
    });

    test('matches tag names', () {
      final results = _search('urgent', [
        _task('Call bank', tagIds: {_urgent.id}),
        _task('Water plants'),
      ]);
      expect(_titles(results), ['Call bank']);
      expect(results.single.matchedTag, isTrue);
    });

    test('matches list names when enabled', () {
      final results = _search('groceries', [_task('Buy milk', list: _listA)]);
      expect(results.single.matchedList, isTrue);
    });

    test('ignores list names when scoped to one list', () {
      final results = _search('groceries', [
        _task('Buy milk', list: _listA),
      ], includeListNames: false);
      expect(results, isEmpty);
    });

    test('all terms must match (AND semantics)', () {
      final tasks = [_task('Buy milk'), _task('Buy bread')];
      expect(_titles(_search('buy milk', tasks)), ['Buy milk']);
      expect(_search('buy cheese', tasks), isEmpty);
    });

    test('terms may match across different fields', () {
      final results = _search('milk receipt', [
        _task('Buy milk', notes: 'keep the receipt'),
      ]);
      expect(results, hasLength(1));
    });

    test('ranks title matches above notes matches', () {
      final results = _search('milk', [
        _task('Order supplies', notes: 'also milk'),
        _task('Buy milk'),
      ]);
      expect(_titles(results).first, 'Buy milk');
    });

    test('ranks pending tasks above completed ones', () {
      final results = _search('milk', [
        _task('Buy milk', isCompleted: true, createdAt: DateTime(2026, 5, 1)),
        _task('Buy milk', createdAt: DateTime(2026, 1, 1)),
      ]);
      expect(results.first.task.isCompleted, isFalse);
    });

    test('ranks prefix matches above mid-word matches', () {
      final results = _search('bread', [
        _task('Flatbread order'),
        _task('Bread and butter'),
      ]);
      expect(_titles(results).first, 'Bread and butter');
    });
  });

  group('toSections', () {
    test(
      'splits pending and completed, omitting an empty completed section',
      () {
        final pendingOnly = TaskSearch.toSections(
          _search('milk', [_task('Buy milk')]),
        );
        expect(pendingOnly, hasLength(1));
        expect(pendingOnly.single.header, isNull);

        final both = TaskSearch.toSections(
          _search('milk', [
            _task('Buy milk'),
            _task('Buy milk', isCompleted: true),
          ]),
        );
        expect(both, hasLength(2));
        expect(both[1].header, 'Completed');
        expect(both[1].tasks.single.isCompleted, isTrue);
      },
    );
  });

  group('highlightRanges', () {
    test('finds every occurrence', () {
      expect(TaskSearch.highlightRanges('milk and more milk', ['milk']), [
        (start: 0, end: 4),
        (start: 14, end: 18),
      ]);
    });

    test('merges overlapping ranges from different terms', () {
      expect(TaskSearch.highlightRanges('milkshake', ['milk', 'milks']), [
        (start: 0, end: 5),
      ]);
    });

    test('returns nothing for no match or empty input', () {
      expect(TaskSearch.highlightRanges('bread', ['milk']), isEmpty);
      expect(TaskSearch.highlightRanges('', ['milk']), isEmpty);
      expect(TaskSearch.highlightRanges('bread', []), isEmpty);
    });
  });

  group('notesExcerpt', () {
    test('returns null when nothing matches', () {
      expect(TaskSearch.notesExcerpt('some notes', ['milk']), isNull);
      expect(TaskSearch.notesExcerpt('', ['milk']), isNull);
    });

    test('collapses whitespace and includes the match', () {
      final excerpt = TaskSearch.notesExcerpt('keep   the\nreceipt', [
        'receipt',
      ]);
      expect(excerpt, 'keep the receipt');
    });

    test('ellipsizes long notes around the hit', () {
      final notes = '${'a ' * 60}needle${' b' * 60}';
      final excerpt = TaskSearch.notesExcerpt(notes, ['needle'])!;
      expect(excerpt, contains('needle'));
      expect(excerpt, startsWith('…'));
      expect(excerpt, endsWith('…'));
      expect(excerpt.length, lessThan(notes.length));
    });
  });
}
