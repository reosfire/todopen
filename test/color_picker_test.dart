import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/ui/accent_theme.dart';
import 'package:todopen/ui/color_picker.dart';

void main() {
  group('toColorValue', () {
    test('packs a color into an opaque unsigned ARGB int', () {
      expect(toColorValue(const Color(0xFF26C6DA)), 0xFF26C6DA);
      expect(toColorValue(const Color(0xFF000000)), 0xFF000000);
      expect(toColorValue(const Color(0xFFFFFFFF)), 0xFFFFFFFF);
    });

    test('never produces a negative value', () {
      // The sync layer treats colours as unsigned; a sign-extended int here
      // would round-trip wrongly (see color_overflow_test.dart).
      for (final c in [
        const Color(0xFFFFFFFF),
        const Color(0xFF26C6DA),
        const Color(0xFFAB47BC),
      ]) {
        expect(toColorValue(c), greaterThan(0));
      }
    });

    test('forces full opacity for a translucent input', () {
      expect(toColorValue(const Color(0x0026C6DA)), 0xFF26C6DA);
    });
  });

  group('ColorPickerField', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('reports the preset that was tapped', (tester) async {
      int? picked;
      await tester.pumpWidget(
        wrap(
          ColorPickerField(
            value: kPresetColors.first,
            onChanged: (c) => picked = c,
          ),
        ),
      );

      // Swatch order is: presets, then the custom swatch.
      await tester.tap(find.byType(GestureDetector).at(2));
      expect(picked, kPresetColors[2]);
    });

    testWidgets('offers a no-color swatch only when allowed', (tester) async {
      await tester.pumpWidget(
        wrap(ColorPickerField(value: kPresetColors.first, onChanged: (_) {})),
      );
      // presets + custom
      expect(
        find.byType(GestureDetector),
        findsNWidgets(kPresetColors.length + 1),
      );

      await tester.pumpWidget(
        wrap(
          ColorPickerField(value: null, allowNoColor: true, onChanged: (_) {}),
        ),
      );
      // default + presets + custom
      expect(
        find.byType(GestureDetector),
        findsNWidgets(kPresetColors.length + 2),
      );
    });

    testWidgets('a custom color picked in the dialog reaches onChanged', (
      tester,
    ) async {
      int? picked;
      await tester.pumpWidget(
        wrap(
          ColorPickerField(
            value: kPresetColors.first,
            onChanged: (c) => picked = c,
          ),
        ),
      );

      // The custom swatch is last.
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();
      expect(find.text('Custom Color'), findsOneWidget);

      // Type a hex the presets do not contain.
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(picked, 0xFF123456);
      expect(kPresetColors.contains(picked), isFalse);
    });

    testWidgets('an out-of-preset value selects the custom swatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ColorPickerField(value: 0xFF123456, onChanged: (_) {})),
      );

      final custom = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector).last,
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = custom.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF123456));
    });
  });

  group('AccentTheme', () {
    testWidgets('leaves the theme untouched for a null accent', (tester) async {
      late ColorScheme inner;
      final base = ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: base,
          home: AccentTheme(
            accent: null,
            child: Builder(
              builder: (context) {
                inner = Theme.of(context).colorScheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(inner.primary, base.colorScheme.primary);
    });

    testWidgets('re-seeds primary from the accent', (tester) async {
      late ColorScheme inner;
      final base = ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: base,
          home: AccentTheme(
            accent: const Color(0xFFEF5350),
            child: Builder(
              builder: (context) {
                inner = Theme.of(context).colorScheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(inner.primary, isNot(base.colorScheme.primary));
      // The seeded scheme stays internally consistent and keeps the surface.
      expect(inner.brightness, Brightness.light);
      expect(inner.surface, base.colorScheme.surface);
    });

    testWidgets('follows the ambient brightness', (tester) async {
      late ColorScheme inner;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
          ),
          home: AccentTheme(
            accent: const Color(0xFFEF5350),
            child: Builder(
              builder: (context) {
                inner = Theme.of(context).colorScheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(inner.brightness, Brightness.dark);
    });
  });
}
