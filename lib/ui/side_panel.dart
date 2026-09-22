import 'package:flutter/material.dart';

// ───── The trailing column ─────
//
// Every side-panel row ends in the same slot: a task count, or the "…" menu
// while the row is hovered. The section headers' "+" button sits in that same
// column. Alignment kept breaking because each row type re-derived the
// geometry by hand, and ListTile, ExpansionTile and the header Row all have
// different defaults. The three constants below are the single source of
// truth; nothing else may hard-code these numbers.

/// Width of the trailing slot: the column every row ends in, holding either a
/// task count or, while the row is hovered, its "…" menu.
///
/// It is sized by the buttons rather than the counts. A count only needs room
/// for three digits, but a button this column can be clicked on needs a
/// comfortable square, and the two must share one centre line or the counts
/// stop lining up. So the column is the button, and the count is centred in it.
const double kPanelTrailingWidth = 34;

/// Side of a side-panel button: the row "…" menus and the section headers "+".
///
/// The button fills the trailing column exactly. Its box *is* its hit area and
/// its hover highlight, so this single number is what decides how big those
/// feel — there is no padding anywhere in the chain to adjust instead.
///
/// Do not try to keep a narrow column and let the button overflow it: Flutter
/// clips hit-testing to the parent's bounds, so that grows the highlight while
/// the clickable area stays narrow. The box has to be as large as the button.
const double kPanelActionSize = kPanelTrailingWidth;

/// Distance from the panel's right edge to the outer edge of that slot.
///
/// Applied explicitly to every row, overriding the differing defaults of
/// ListTile (16) and ExpansionTile (16), so all row types line up.
const double kPanelTrailingInset = 12;

/// A header action ("+") sized to the trailing column.
///
/// The header used to be padded by a hand-tuned number so the button would
/// land on the column, which never survived a change to either. Wrapping the
/// button in a box exactly as wide as the column, under the same right inset
/// as the rows, makes the alignment structural: the button centres because
/// the box does, whatever padding the IconButton keeps inside itself.
class PanelHeaderAction extends StatelessWidget {
  final Widget child;

  const PanelHeaderAction({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Height as well as width: the header Row would otherwise stretch the
    // button taller than the rows' buttons, making the highlight a different
    // shape in the two places.
    return SizedBox(
      width: kPanelTrailingWidth,
      height: kPanelActionSize,
      child: Center(child: child),
    );
  }
}

/// The trailing slot of a side-panel row.
///
/// Rows pass the count and, when they have a context menu, the hover state and
/// the menu button. Keeping both cases in one widget is what guarantees the
/// number and the "…" occupy exactly the same box.
class PanelTrailing extends StatelessWidget {
  /// Shown when the row is not hovered. Zero renders nothing.
  final int count;

  /// Whether to show [menuButton] in place of the count.
  final bool showMenu;

  /// The row's context-menu button, if it has one.
  final Widget? menuButton;

  const PanelTrailing({
    super.key,
    required this.count,
    this.showMenu = false,
    this.menuButton,
  });

  @override
  Widget build(BuildContext context) {
    final menu = menuButton;
    return SizedBox(
      width: kPanelTrailingWidth,
      height: kPanelTrailingWidth,
      child: showMenu && menu != null
          ? Center(child: menu)
          : count > 0
          ? Center(
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The context-menu button used inside [PanelTrailing], centred on the column
/// and sized to [kPanelActionSize].
class PanelMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;

  const PanelMenuButton({super.key, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return PanelActionButton(
      icon: Icons.more_horiz,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

/// The one button shape the side panel uses: a [kPanelActionSize] square with
/// no padding of its own, so its hit area and its hover highlight are exactly
/// that square.
///
/// Both the row "…" menus and the header "+" buttons are this widget, which is
/// what keeps them coherent — there is no second place where one of them can be
/// sized by hand.
class PanelActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const PanelActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      // Sized through `style` rather than `constraints` + `visualDensity`.
      // Those two size the *button*, but leave the ink response inset within
      // it, so the highlight and the hit area stay small however large the box
      // is told to be — which is how the old 24px controls ended up with an
      // 18px highlight. Pinning the three sizes here makes the button, its
      // highlight and its hit area all exactly [kPanelActionSize], and
      // shrinkWrap stops Material padding it back out to a 48px tap target,
      // which would widen the column and push the counts off their line.
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(kPanelActionSize, kPanelActionSize),
        fixedSize: const Size(kPanelActionSize, kPanelActionSize),
        maximumSize: const Size(kPanelActionSize, kPanelActionSize),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// A drag handle that sits between two stacked sections of the side panel.
///
/// The gesture reports a delta in logical pixels; the owner decides how much
/// of it the layout can absorb and returns the unused remainder. Travel spent
/// pushing past a section's minimum is discarded the moment the pointer
/// reverses, so the divider follows the cursor again immediately instead of
/// waiting for the overshoot to be dragged back first.
class SectionResizeHandle extends StatefulWidget {
  /// Applies [delta] and returns the portion that could not be used.
  final double Function(double delta) onDrag;
  final VoidCallback onDragEnd;

  const SectionResizeHandle({
    super.key,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  State<SectionResizeHandle> createState() => _SectionResizeHandleState();
}

class _SectionResizeHandleState extends State<SectionResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  /// Travel the layout refused on the previous update. It is only carried
  /// forward while the drag keeps pushing the same way; reversing discards it.
  double _overflow = 0;

  void _handleDrag(double dy) {
    // Still pushing into the end stop: the refused travel accumulates rather
    // than moving anything.
    if (_overflow != 0 && _overflow.isNegative == dy.isNegative && dy != 0) {
      _overflow += dy;
      return;
    }
    // Any reversal means the pointer is heading back into range, so the
    // overshoot is dropped and this delta applies in full.
    _overflow = widget.onDrag(dy);
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {
          _overflow = 0;
          setState(() => _dragging = true);
        },
        onVerticalDragUpdate: (d) => _handleDrag(d.delta.dy),
        onVerticalDragEnd: (_) {
          _overflow = 0;
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        onVerticalDragCancel: () {
          _overflow = 0;
          setState(() => _dragging = false);
        },
        child: SizedBox(
          height: 9,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: active ? 3 : 1,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain divider between two side-panel sections whose boundary is not
/// draggable. It occupies the same 9px as [SectionResizeHandle] and draws the
/// same resting line, so swapping one for the other does not move anything.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 9,
      child: Center(
        child: Container(height: 1, color: Theme.of(context).dividerColor),
      ),
    );
  }
}

/// The vertical handle on the side panel's outer edge, for widening and
/// narrowing the whole panel.
class PanelResizeHandle extends StatefulWidget {
  /// Applies [delta] and returns the portion that could not be used.
  final double Function(double delta) onDrag;
  final VoidCallback onDragEnd;

  const PanelResizeHandle({
    super.key,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  State<PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<PanelResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  /// See [_SectionResizeHandleState._overflow].
  double _overflow = 0;

  void _handleDrag(double dx) {
    if (_overflow != 0 && _overflow.isNegative == dx.isNegative && dx != 0) {
      _overflow += dx;
      return;
    }
    _overflow = widget.onDrag(dx);
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _overflow = 0;
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (d) => _handleDrag(d.delta.dx),
        onHorizontalDragEnd: (_) {
          _overflow = 0;
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        onHorizontalDragCancel: () {
          _overflow = 0;
          setState(() => _dragging = false);
        },
        child: SizedBox(
          width: 9,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: active ? 3 : 1,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// One resizable section of the side panel: a fixed header row plus a body
/// that scrolls on its own.
class PanelSection extends StatelessWidget {
  final String? header;
  final Widget child;

  /// Trailing widgets for the header row (e.g. an "add" button).
  final List<Widget> headerActions;

  const PanelSection({
    super.key,
    this.header,
    required this.child,
    this.headerActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final title = header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            // Actions sit under the same right inset as the rows, each in a
            // column-width box, so they line up with the counts below.
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              headerActions.isEmpty ? 16 : kPanelTrailingInset,
              2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...headerActions.map((a) => PanelHeaderAction(child: a)),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
