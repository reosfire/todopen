import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The preset swatches offered before the user reaches for a custom color.
const kPresetColors = <int>[
  0xFF42A5F5, // blue
  0xFF66BB6A, // green
  0xFFEF5350, // red
  0xFFAB47BC, // purple
  0xFFFF7043, // orange
  0xFFFFA726, // amber
  0xFF26C6DA, // cyan
  0xFF78909C, // grey
];

/// A row of preset swatches plus a custom swatch that opens the full picker.
///
/// When [allowNoColor] is set the row starts with a "default" swatch that maps
/// to a null value, meaning the caller falls back to the theme color.
class ColorPickerField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowNoColor;

  const ColorPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNoColor = false,
  }) : assert(
         allowNoColor || value != null,
         'value may only be null when allowNoColor is set',
       );

  /// True when the value is a color the presets do not cover, which is what
  /// makes the custom swatch show as selected.
  bool get _isCustom => value != null && !kPresetColors.contains(value);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (allowNoColor)
          _Swatch(
            color: null,
            selected: value == null,
            onTap: () => onChanged(null),
            child: Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ...kPresetColors.map(
          (c) => _Swatch(
            color: Color(c),
            selected: value == c,
            onTap: () => onChanged(c),
          ),
        ),
        _Swatch(
          color: _isCustom ? Color(value!) : null,
          selected: _isCustom,
          onTap: () async {
            final picked = await showCustomColorDialog(
              context,
              initial: Color(value ?? kPresetColors.first),
            );
            if (picked != null) onChanged(toColorValue(picked));
          },
          child: _isCustom
              ? null
              : const Center(child: Icon(Icons.colorize, size: 16)),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              width: selected ? 3 : 1,
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Packs an opaque [color] into the int the models persist.
int toColorValue(Color color) =>
    (0xFF << 24) |
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

/// Opens the custom picker and returns the chosen color, or null if cancelled.
Future<Color?> showCustomColorDialog(
  BuildContext context, {
  required Color initial,
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _CustomColorDialog(initial: initial),
  );
}

class _CustomColorDialog extends StatefulWidget {
  final Color initial;
  const _CustomColorDialog({required this.initial});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexCtrl;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hexCtrl = TextEditingController(text: _hex);
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  String get _hex => (toColorValue(_color) & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();

  /// Moves the swatch and keeps the hex field in sync with the sliders.
  void _setHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _hexCtrl.value = TextEditingValue(text: _hex);
  }

  /// Accepts "A1B2C3" or "#A1B2C3" and ignores anything still incomplete so
  /// the field does not fight the user mid-typing.
  void _onHexChanged(String raw) {
    final cleaned = raw.replaceAll('#', '').trim();
    if (cleaned.length != 6) return;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Color'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SliderRow(
                label: 'Hue',
                value: _hsv.hue,
                max: 360,
                gradient: [
                  for (var i = 0; i <= 360; i += 60)
                    HSVColor.fromAHSV(1, i % 360, 1, 1).toColor(),
                ],
                onChanged: (v) => _setHsv(_hsv.withHue(v)),
              ),
              _SliderRow(
                label: 'Saturation',
                value: _hsv.saturation,
                max: 1,
                gradient: [
                  HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                  HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
                ],
                onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
              ),
              _SliderRow(
                label: 'Brightness',
                value: _hsv.value,
                max: 1,
                gradient: [
                  HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0).toColor(),
                  HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
                ],
                onChanged: (v) => _setHsv(_hsv.withValue(v)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hexCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hex',
                  prefixText: '#',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(7),
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F#]')),
                ],
                onChanged: _onHexChanged,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

/// A labelled slider whose track previews the values it spans.
class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(colors: gradient),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                ),
                child: Slider(
                  value: value.clamp(0, max),
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
