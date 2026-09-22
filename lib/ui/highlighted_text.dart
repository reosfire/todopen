import 'package:flutter/material.dart';
import '../models/task_search.dart';

/// Renders [text] with every occurrence of [terms] highlighted.
///
/// Shared by the search results view and the add-task filter so a match looks
/// the same however the user arrived at it.
class HighlightedText extends StatelessWidget {
  final String text;
  final List<String> terms;
  final TextStyle? style;
  final int? maxLines;

  const HighlightedText({
    super.key,
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
