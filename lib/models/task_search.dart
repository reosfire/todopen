import 'smart_list.dart';
import 'tag.dart';
import 'task.dart';
import 'task_list.dart';

/// Where a query matched within a task. Used to rank results and to explain
/// the match in the UI when the hit is not visible in the title.
enum TaskMatchField { title, notes, tag, list }

/// A single task that matched a search query.
class TaskSearchResult {
  final Task task;
  final Set<TaskMatchField> fields;
  final int score;

  const TaskSearchResult({
    required this.task,
    required this.fields,
    required this.score,
  });

  bool get matchedTitle => fields.contains(TaskMatchField.title);
  bool get matchedNotes => fields.contains(TaskMatchField.notes);
  bool get matchedTag => fields.contains(TaskMatchField.tag);
  bool get matchedList => fields.contains(TaskMatchField.list);
}

/// Searches tasks by title, notes, tag name and (optionally) list name.
///
/// The query is split on whitespace and every term must match somewhere in a
/// task for it to be a result, so typing more words narrows the result set.
class TaskSearch {
  /// Searches [tasks] for [query].
  ///
  /// [tags] and [lists] let terms match a task's tag or list name.
  /// When [includeListNames] is false (searching inside a single list, where
  /// every task shares the same list name) list names are ignored.
  static List<TaskSearchResult> search(
    String query, {
    required List<Task> tasks,
    List<Tag> tags = const [],
    List<TaskList> lists = const [],
    bool includeListNames = true,
  }) {
    final terms = tokenize(query);
    if (terms.isEmpty) return const [];

    final tagNames = {for (final t in tags) t.id: t.name.toLowerCase()};
    final listNames = {for (final l in lists) l.id: l.name.toLowerCase()};

    final results = <TaskSearchResult>[];
    for (final task in tasks) {
      final title = task.title.toLowerCase();
      final notes = task.notes.toLowerCase();
      final taskTagNames = task.tagIds
          .map((id) => tagNames[id])
          .whereType<String>()
          .toList();
      final listName = includeListNames ? listNames[task.listId] : null;

      final fields = <TaskMatchField>{};
      var score = 0;
      var matchesAll = true;

      for (final term in terms) {
        final titleIndex = title.indexOf(term);
        final inTitle = titleIndex != -1;
        final inNotes = notes.contains(term);
        final inTag = taskTagNames.any((n) => n.contains(term));
        final inList = listName != null && listName.contains(term);

        if (!inTitle && !inNotes && !inTag && !inList) {
          matchesAll = false;
          break;
        }

        if (inTitle) {
          fields.add(TaskMatchField.title);
          // Prefer title hits, and among those prefer earlier / prefix matches.
          score += 100;
          if (titleIndex == 0) score += 40;
          if (_isWordStart(title, titleIndex)) score += 20;
          if (title == term) score += 60;
        }
        if (inTag) {
          fields.add(TaskMatchField.tag);
          score += 50;
        }
        if (inList) {
          fields.add(TaskMatchField.list);
          score += 25;
        }
        if (inNotes) {
          fields.add(TaskMatchField.notes);
          score += 10;
        }
      }

      if (!matchesAll) continue;

      // Surface actionable work above things already done.
      if (!task.isCompleted) score += 30;

      results.add(
        TaskSearchResult(task: task, fields: fields, score: score),
      );
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byDate = b.task.createdAt.compareTo(a.task.createdAt);
      if (byDate != 0) return byDate;
      return a.task.title.toLowerCase().compareTo(b.task.title.toLowerCase());
    });
    return results;
  }

  /// Splits a query into lowercase search terms.
  static List<String> tokenize(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// Groups results into pending and completed sections for display.
  static List<TaskSection> toSections(List<TaskSearchResult> results) {
    final pending = <Task>[];
    final completed = <Task>[];
    for (final r in results) {
      (r.task.isCompleted ? completed : pending).add(r.task);
    }
    return [
      TaskSection(tasks: pending),
      if (completed.isNotEmpty)
        TaskSection(header: 'Completed', tasks: completed),
    ];
  }

  /// The ranges of [text] that [terms] match, merged and sorted, for highlighting.
  static List<({int start, int end})> highlightRanges(
    String text,
    List<String> terms,
  ) {
    if (text.isEmpty || terms.isEmpty) return const [];
    final lower = text.toLowerCase();
    final raw = <({int start, int end})>[];
    for (final term in terms) {
      var from = 0;
      while (true) {
        final i = lower.indexOf(term, from);
        if (i == -1) break;
        raw.add((start: i, end: i + term.length));
        from = i + term.length;
      }
    }
    if (raw.isEmpty) return const [];
    raw.sort((a, b) => a.start.compareTo(b.start));

    final merged = <({int start, int end})>[raw.first];
    for (final r in raw.skip(1)) {
      final last = merged.last;
      if (r.start <= last.end) {
        if (r.end > last.end) {
          merged[merged.length - 1] = (start: last.start, end: r.end);
        }
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  /// A short excerpt of [notes] around the first matching term, for showing
  /// why a task matched when the hit is in its notes rather than its title.
  static String? notesExcerpt(
    String notes,
    List<String> terms, {
    int context = 40,
  }) {
    if (notes.isEmpty || terms.isEmpty) return null;
    final flat = notes.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return null;
    final lower = flat.toLowerCase();

    var hit = -1;
    for (final term in terms) {
      final i = lower.indexOf(term);
      if (i != -1 && (hit == -1 || i < hit)) hit = i;
    }
    if (hit == -1) return null;

    var start = (hit - context).clamp(0, flat.length);
    var end = (hit + context).clamp(0, flat.length);
    // Avoid cutting words in half where there is a nearby space.
    if (start > 0) {
      final space = flat.indexOf(' ', start);
      if (space != -1 && space < hit) start = space + 1;
    }
    if (end < flat.length) {
      final space = flat.lastIndexOf(' ', end);
      if (space != -1 && space > hit) end = space;
    }

    final buffer = StringBuffer();
    if (start > 0) buffer.write('…');
    buffer.write(flat.substring(start, end).trim());
    if (end < flat.length) buffer.write('…');
    return buffer.toString();
  }

  static bool _isWordStart(String text, int index) {
    if (index <= 0) return true;
    return !RegExp(r'[a-z0-9]').hasMatch(text[index - 1]);
  }
}
