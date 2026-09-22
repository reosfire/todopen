import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/ui/side_panel.dart';

/// The trailing column is the one piece of side-panel geometry that four
/// different row types and two header rows all have to agree on, and it broke
/// every time one of them was tuned by hand. These lock the agreement down by
/// measuring real rendered rects.
/// Centre x of every rendered trailing slot. Read straight off the render
/// objects: identical const widgets cannot be told apart by find.byWidget.
Set<double> _trailingCentres(WidgetTester tester) {
  return find.byType(PanelTrailing).evaluate().map((e) {
    final box = e.renderObject! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft.dx + box.size.width / 2;
  }).toSet();
}

void main() {
  /// Builds a panel-like column of rows plus a section header, mirroring how
  /// home_page composes them, and reports the centre x of each trailing slot.
  Widget harness({required double width}) {
    Widget row({
      required Widget leading,
      required String title,
      required int count,
      bool menu = false,
      double indent = 0,
    }) => ListTile(
      contentPadding: EdgeInsets.only(
        left: 16 + indent,
        right: kPanelTrailingInset,
      ),
      leading: leading,
      title: Text(title),
      trailing: PanelTrailing(
        count: count,
        showMenu: menu,
        menuButton: PanelMenuButton(onPressed: () {}),
      ),
      dense: true,
    );

    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PanelSection(
                  header: 'LISTS',
                  headerActions: [
                    PanelActionButton(icon: Icons.add, onPressed: () {}),
                  ],
                  child: ListView(
                    children: [
                      row(
                        leading: const Icon(Icons.star),
                        title: 'smart list',
                        count: 3,
                      ),
                      row(
                        leading: const Icon(Icons.list),
                        title: 'hovered list',
                        count: 7,
                        menu: true,
                      ),
                      ExpansionTile(
                        leading: const Icon(Icons.folder_outlined, size: 20),
                        title: const Text('folder'),
                        dense: true,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding: const EdgeInsets.only(
                          left: 16,
                          right: kPanelTrailingInset,
                        ),
                        trailing: const PanelTrailing(count: 12),
                      ),
                      row(
                        leading: const Icon(Icons.list),
                        title: 'nested list',
                        count: 5,
                        indent: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('every trailing slot shares one centre line', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    final slots = tester
        .widgetList<PanelTrailing>(find.byType(PanelTrailing))
        .length;
    expect(slots, 4, reason: 'three rows plus the folder');

    final centres = _trailingCentres(tester);

    // All four must land on exactly one x.
    expect(
      centres.length,
      1,
      reason: 'trailing slots are not vertically aligned: $centres',
    );
  });

  testWidgets('the header action centres on the trailing column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    final column = _trailingCentres(tester).first;
    final plus = tester.getRect(find.byIcon(Icons.add)).center.dx;

    expect(
      (plus - column).abs(),
      lessThan(0.5),
      reason: '"+" at $plus, trailing column at $column',
    );
  });

  testWidgets('the header action box is the column width', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    // Alignment is structural: the action sits in a box exactly as wide as a
    // trailing slot, not at a hand-tuned offset.
    final box = tester.getRect(find.byType(PanelHeaderAction));
    expect(box.width, kPanelTrailingWidth);

    final slot = tester.getRect(find.byType(PanelTrailing).first);
    expect(box.center.dx, slot.center.dx);
  });

  testWidgets('every panel button is one comfortable square', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    // The hit area and the hover highlight are the button's own box, so this
    // is the number that decides whether the control feels big enough.
    final buttons = tester
        .renderObjectList<RenderBox>(find.byType(PanelActionButton))
        .map((b) => b.size)
        .toSet();

    expect(buttons, {
      const Size(kPanelActionSize, kPanelActionSize),
    }, reason: 'the "+" and the "…" must be the same, larger square');

    // The button fills the column, so its box is the whole hit area. If these
    // ever diverge, the clickable region silently shrinks back to the smaller
    // of the two — which is the bug this file exists to prevent.
    expect(kPanelActionSize, kPanelTrailingWidth);

    // A guard on the number itself: the old 24/28px controls were too small to
    // hit comfortably, so the column must not drift back down there.
    expect(kPanelActionSize, greaterThanOrEqualTo(32));
  });

  testWidgets('a bigger button does not move the counts', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    // Counts and buttons share one slot size, so a hovered row's slot sits on
    // the same centre line as the plain counts.
    final centres = _trailingCentres(tester);
    expect(centres.length, 1, reason: 'overflow shifted a row: $centres');

    for (final slot in tester.renderObjectList<RenderBox>(
      find.byType(PanelTrailing),
    )) {
      expect(slot.size.width, kPanelTrailingWidth);
    }

    // The button is centred on that column despite being wider than it.
    final menu = tester.getRect(find.byIcon(Icons.more_horiz)).center.dx;
    expect((menu - centres.first).abs(), lessThan(0.5));
  });

  testWidgets('the highlight fills the button, not just the box', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 280));
    await tester.pumpAndSettle();

    // What the user sees and clicks is the InkWell, not the IconButton's own
    // box. Sizing the box while Material keeps the ink inset inside it is a
    // silent no-op — it is how a 24px control ended up with an 18px highlight
    // — so the ink is measured directly.
    // Scoped to the buttons: rows and ExpansionTiles have their own InkWells.
    final inks = tester
        .renderObjectList<RenderBox>(
          find.descendant(
            of: find.byType(PanelActionButton),
            matching: find.byType(InkWell),
          ),
        )
        .map((b) => b.size)
        .toSet();

    expect(inks, isNotEmpty, reason: 'no button ink found to measure');

    expect(inks, {
      const Size(kPanelActionSize, kPanelActionSize),
    }, reason: 'the hover highlight is not the full button square');
  });

  testWidgets('alignment holds at other panel widths', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final w in [200.0, 280.0, 400.0, 520.0]) {
      await tester.pumpWidget(harness(width: w));
      await tester.pumpAndSettle();

      final centres = _trailingCentres(tester);
      expect(centres.length, 1, reason: 'rows misaligned at width $w');

      final plus = tester.getRect(find.byIcon(Icons.add)).center.dx;
      expect(
        (plus - centres.first).abs(),
        lessThan(0.5),
        reason: '"+" misaligned at width $w',
      );
    }
  });
}
