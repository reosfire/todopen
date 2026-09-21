import 'package:flutter/material.dart';

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
            // With actions, the right padding puts the buttons over the count
            // column of the rows below. The value is larger than it looks like
            // it should be because an IconButton keeps a 40px minimum tap
            // target whatever constraints it is given, and the panel's resize
            // handle takes width from the rows but not from this row; 26 is
            // what measures as aligned on screen.
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              headerActions.isEmpty ? 16 : 26,
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
                ...headerActions,
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
