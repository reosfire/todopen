import 'package:flutter/material.dart';

/// Re-themes [child] around [accent] so the selected list's color reaches the
/// widgets that read `colorScheme.primary` — the add button, checkboxes, text
/// field focus rings, selected tiles — instead of each one tinting by hand.
///
/// A null [accent] leaves the ambient theme untouched, which is what a list
/// with no color of its own should look like.
class AccentTheme extends StatelessWidget {
  final Color? accent;
  final Widget child;

  const AccentTheme({super.key, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = this.accent;
    if (accent == null) return child;

    // Seeding keeps the derived tones (containers, `on*` pairs) legible even
    // for colors that would clash if dropped straight onto `primary`. The
    // original surface is kept so only accents shift, not the page itself.
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: theme.brightness,
      surface: theme.colorScheme.surface,
    );

    return Theme(
      data: theme.copyWith(
        colorScheme: scheme,
        // These default off the old scheme at construction, so they need to be
        // pointed at the new one explicitly.
        primaryColor: scheme.primary,
        dividerColor: theme.dividerColor,
      ),
      child: child,
    );
  }
}
