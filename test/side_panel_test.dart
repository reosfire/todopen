import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/ui/side_panel.dart';

/// The resize handles hand their drag delta to the owner and get back the
/// travel the layout refused. That remainder is what stops a pointer dragged
/// past a section's minimum from "banking" distance: without it, dragging
/// 200px past the end and then back 10px would leave the divider still pinned,
/// because the owner would have to be dragged all 200px back first.
///
/// These drive the real widgets, since the debt only behaves correctly in
/// combination with the gesture recognizer's per-drag lifecycle.
void main() {
  /// A handle wired to a single clamped value, mimicking how the side panel
  /// owns its section heights.
  Widget harness({
    required ValueNotifier<double> value,
    required double min,
    required double max,
    bool vertical = true,
  }) {
    double apply(double delta) {
      final before = value.value;
      value.value = (value.value + delta).clamp(min, max);
      return delta - (value.value - before);
    }

    final handle = vertical
        ? SectionResizeHandle(onDrag: apply, onDragEnd: () {})
        : PanelResizeHandle(onDrag: apply, onDragEnd: () {});

    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 200, height: 200, child: handle)),
      ),
    );
  }

  group('SectionResizeHandle', () {
    testWidgets('passes drag distance through to the owner', (tester) async {
      final value = ValueNotifier(100.0);
      await tester.pumpWidget(harness(value: value, min: 0, max: 200));

      await tester.drag(find.byType(SectionResizeHandle), const Offset(0, 40));
      await tester.pump();

      expect(value.value, 140);
    });

    testWidgets('clamps at the owner-imposed maximum', (tester) async {
      final value = ValueNotifier(100.0);
      await tester.pumpWidget(harness(value: value, min: 0, max: 120));

      await tester.drag(find.byType(SectionResizeHandle), const Offset(0, 80));
      await tester.pump();

      expect(value.value, 120);
    });

    testWidgets('does not bank travel dragged past the end', (tester) async {
      final value = ValueNotifier(100.0);
      await tester.pumpWidget(harness(value: value, min: 0, max: 120));

      // One continuous gesture: far past the maximum, then back a little.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SectionResizeHandle)),
      );
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(value.value, 120, reason: 'pinned at the maximum');

      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.up();

      // The 80px of refused travel must not have to be dragged back first.
      expect(value.value, 90);
    });

    testWidgets('resumes immediately after being pinned at the minimum', (
      tester,
    ) async {
      final value = ValueNotifier(50.0);
      await tester.pumpWidget(harness(value: value, min: 40, max: 200));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SectionResizeHandle)),
      );
      await gesture.moveBy(const Offset(0, -150));
      await tester.pump();
      expect(value.value, 40);

      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();
      await gesture.up();

      expect(value.value, 65);
    });

    testWidgets('a new gesture starts without inherited debt', (tester) async {
      final value = ValueNotifier(100.0);
      await tester.pumpWidget(harness(value: value, min: 0, max: 120));

      // First gesture overshoots badly and ends while still pinned.
      await tester.drag(find.byType(SectionResizeHandle), const Offset(0, 300));
      await tester.pump();
      expect(value.value, 120);

      // A fresh grab must move the divider straight away.
      await tester.drag(find.byType(SectionResizeHandle), const Offset(0, -20));
      await tester.pump();

      expect(value.value, 100);
    });
  });

  group('PanelResizeHandle', () {
    testWidgets('widens and narrows on horizontal drag', (tester) async {
      final value = ValueNotifier(280.0);
      await tester.pumpWidget(
        harness(value: value, min: 200, max: 520, vertical: false),
      );

      await tester.drag(find.byType(PanelResizeHandle), const Offset(60, 0));
      await tester.pump();
      expect(value.value, 340);

      await tester.drag(find.byType(PanelResizeHandle), const Offset(-100, 0));
      await tester.pump();
      expect(value.value, 240);
    });

    testWidgets('respects the minimum width', (tester) async {
      final value = ValueNotifier(280.0);
      await tester.pumpWidget(
        harness(value: value, min: 200, max: 520, vertical: false),
      );

      await tester.drag(find.byType(PanelResizeHandle), const Offset(-400, 0));
      await tester.pump();

      expect(value.value, 200);
    });

    testWidgets('does not bank travel dragged past the end', (tester) async {
      final value = ValueNotifier(280.0);
      await tester.pumpWidget(
        harness(value: value, min: 200, max: 520, vertical: false),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanelResizeHandle)),
      );
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();
      expect(value.value, 200);

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();

      expect(value.value, 250);
    });
  });

  group('PanelSection', () {
    testWidgets('renders its header, actions and body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: PanelSection(
                header: 'SMART LISTS',
                headerActions: [
                  IconButton(icon: const Icon(Icons.add), onPressed: () {}),
                ],
                child: ListView(children: const [Text('an item')]),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SMART LISTS'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('an item'), findsOneWidget);
    });

    testWidgets('body scrolls independently of the header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              child: PanelSection(
                header: 'LISTS',
                child: ListView(
                  children: List.generate(
                    30,
                    (i) => SizedBox(height: 40, child: Text('row $i')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('row 20'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -820));
      await tester.pump();

      // The header stays put while the body scrolls under it.
      expect(find.text('LISTS'), findsOneWidget);
      expect(find.text('row 0'), findsNothing);
      expect(find.text('row 22'), findsOneWidget);
    });

    testWidgets('a short section renders without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 44,
              child: PanelSection(
                header: 'LISTS',
                child: ListView(
                  children: List.generate(10, (i) => Text('row $i')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
