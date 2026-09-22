import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// The monospace stack used by both the editor and rendered code spans, so a
/// fenced block looks the same on either side of the split view.
const String kNotesMonoFamily = 'monospace';

/// Builds the stylesheet for rendered note bodies.
///
/// `MarkdownStyleSheet.fromTheme` only inherits the text theme; everything that
/// gives a note structure — heading rhythm, code surfaces, quote rules, table
/// borders — has to be spelled out, which is what this does.
MarkdownStyleSheet notesMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final text = theme.textTheme;

  // Code and quotes sit on a tinted panel rather than a hard-edged box; mixing
  // toward the surface keeps it subtle in both light and dark themes.
  final codeSurface = Color.alphaBlend(
    scheme.surfaceTint.withValues(alpha: 0.05),
    scheme.surfaceContainerHighest,
  );
  final codeStyle = TextStyle(
    fontFamily: kNotesMonoFamily,
    fontSize: (text.bodyMedium?.fontSize ?? 14) * 0.92,
    height: 1.45,
    color: scheme.onSurface,
  );

  TextStyle heading(TextStyle? base, double size, FontWeight weight) =>
      (base ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: weight,
        height: 1.3,
        color: scheme.onSurface,
      );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: text.bodyMedium?.copyWith(height: 1.6, color: scheme.onSurface),
    pPadding: const EdgeInsets.only(bottom: 2),
    a: TextStyle(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary.withValues(alpha: 0.4),
    ),
    h1: heading(text.headlineSmall, 26, FontWeight.w700),
    h2: heading(text.titleLarge, 21, FontWeight.w700),
    h3: heading(text.titleMedium, 18, FontWeight.w600),
    h4: heading(text.titleSmall, 16, FontWeight.w600),
    h5: heading(text.titleSmall, 14, FontWeight.w600),
    h6: heading(
      text.labelLarge,
      13,
      FontWeight.w600,
    ).copyWith(color: scheme.onSurfaceVariant),
    h1Padding: const EdgeInsets.only(top: 12, bottom: 4),
    h2Padding: const EdgeInsets.only(top: 20, bottom: 4),
    h3Padding: const EdgeInsets.only(top: 16, bottom: 2),
    h4Padding: const EdgeInsets.only(top: 14, bottom: 2),
    h5Padding: const EdgeInsets.only(top: 12, bottom: 2),
    h6Padding: const EdgeInsets.only(top: 12, bottom: 2),
    blockSpacing: 10,
    listIndent: 22,
    listBullet: text.bodyMedium?.copyWith(
      height: 1.6,
      color: scheme.onSurfaceVariant,
    ),
    listBulletPadding: const EdgeInsets.only(right: 6),
    strong: const TextStyle(fontWeight: FontWeight.w700),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: TextStyle(
      decoration: TextDecoration.lineThrough,
      color: scheme.onSurfaceVariant,
    ),
    code: codeStyle.copyWith(
      backgroundColor: Colors.transparent,
      color: scheme.onSurfaceVariant,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: codeSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    blockquote: text.bodyMedium?.copyWith(
      height: 1.6,
      color: scheme.onSurfaceVariant,
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
    blockquoteDecoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(4),
        right: Radius.circular(8),
      ),
      border: Border(
        left: BorderSide(
          color: scheme.primary.withValues(alpha: 0.6),
          width: 3,
        ),
      ),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
    ),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: text.bodyMedium?.copyWith(color: scheme.onSurface),
    tableBorder: TableBorder.all(color: scheme.outlineVariant, width: 1),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    tableHeadCellsDecoration: BoxDecoration(color: codeSurface),
    checkbox: text.bodyMedium?.copyWith(color: scheme.primary),
  );
}
