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

  /// Accented themes, per base theme and accent.
  ///
  /// [ColorScheme.fromSeed] runs a tonal-palette solve that is far too slow
  /// to repeat on every rebuild of the page. Handing back the same instance
  /// also lets [Theme] skip notifying dependents without a deep comparison.
  /// Keyed by identity through an [Expando], so a base theme that goes away
  /// takes its entries with it.
  static final _accented = Expando<Map<Color, ThemeData>>();

  static ThemeData _accentedTheme(ThemeData theme, Color accent) {
    final perBase = _accented[theme] ??= {};
    return perBase[accent] ??= () {
      // Seeding keeps the derived tones (containers, `on*` pairs) legible
      // even for colors that would clash if dropped straight onto `primary`.
      // The original surface is kept so only accents shift, not the page.
      final scheme = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: theme.brightness,
        surface: theme.colorScheme.surface,
      );
      return theme.copyWith(
        colorScheme: scheme,
        // These default off the old scheme at construction, so they need to
        // be pointed at the new one explicitly.
        primaryColor: scheme.primary,
        dividerColor: theme.dividerColor,
      );
    }();
  }

  @override
  Widget build(BuildContext context) {
    final accent = this.accent;
    if (accent == null) return child;
    return Theme(data: _accentedTheme(Theme.of(context), accent), child: child);
  }
}
