import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/task_search.dart';
import '../state/app_state.dart';
import '../utils/uuid128.dart';
import 'sectioned_task_list.dart';

/// Shows the results of a task search.
///
/// When [listId] is given the search is scoped to that list; otherwise it
/// covers every task in the app.
class SearchView extends StatelessWidget {
  final String query;
  final Uuid128? listId;
  final String? selectedTaskId;
  final void Function(Task task)? onTaskSelected;

  const SearchView({
    super.key,
    required this.query,
    this.listId,
    this.selectedTaskId,
    this.onTaskSelected,
  });

  bool get _isScoped => listId != null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final terms = TaskSearch.tokenize(query);

    if (terms.isEmpty) {
      return _Placeholder(
        icon: Icons.search,
        message: _isScoped ? 'Search this list' : 'Search all tasks',
        hint: 'Matches titles, notes and tags.',
      );
    }

    final scope = _isScoped
        ? state.tasks.where((t) => t.listId == listId).toList()
        : state.tasks;

    final results = TaskSearch.search(
      query,
      tasks: scope,
      tags: state.tags,
      lists: state.lists,
      includeListNames: !_isScoped,
    );

    return Column(
      children: [
        _ResultCount(count: results.length),
        Expanded(
          child: SectionedTaskList(
            sections: TaskSearch.toSections(results),
            showListName: !_isScoped,
            emptyMessage: 'No matching tasks',
            emptyIcon: Icons.search_off,
            selectedTaskId: selectedTaskId,
            onTaskSelected: onTaskSelected,
            titleBuilder: (context, task, style) =>
                _HighlightedText(text: task.title, terms: terms, style: style),
            subtitleBuilder: (context, task) =>
                _buildSubtitle(context, state, task, terms),
          ),
        ),
      ],
    );
  }

  Widget? _buildSubtitle(
    BuildContext context,
    AppState state,
    Task task,
    List<String> terms,
  ) {
    final theme = Theme.of(context);
    final parts = <Widget>[];

    if (!_isScoped) {
      final listName = state.listById(task.listId)?.name ?? '';
      if (listName.isNotEmpty) {
        parts.add(
          _HighlightedText(
            text: listName,
            terms: terms,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    }

    final tags = task.tagIds
        .map((id) => state.tagById(id))
        .whereType<Tag>()
        .toList();
    if (tags.isNotEmpty) {
      parts.add(
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            for (final t in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: t.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _HighlightedText(
                  text: t.name,
                  terms: terms,
                  style: TextStyle(fontSize: 11, color: t.color),
                ),
              ),
          ],
        ),
      );
    }

    // Show where the match happened when the notes hold a hit, so a result
    // whose title looks unrelated still explains itself.
    final excerpt = TaskSearch.notesExcerpt(task.notes, terms);
    if (excerpt != null) {
      parts.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Icon(
                Icons.notes,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: _HighlightedText(
                text: excerpt,
                terms: terms,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (parts.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          parts[i],
        ],
      ],
    );
  }
}

class _ResultCount extends StatelessWidget {
  final int count;
  const _ResultCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Text(
        count == 1 ? '1 result' : '$count results',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;
  const _Placeholder({required this.icon, required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyLarge),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders [text] with every occurrence of [terms] highlighted.
class _HighlightedText extends StatelessWidget {
  final String text;
  final List<String> terms;
  final TextStyle? style;
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.terms,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final ranges = TaskSearch.highlightRanges(text, terms);
    if (ranges.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final theme = Theme.of(context);
    final highlight = TextStyle(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.22),
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final r in ranges) {
      if (r.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, r.start)));
      }
      spans.add(
        TextSpan(text: text.substring(r.start, r.end), style: highlight),
      );
      cursor = r.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
