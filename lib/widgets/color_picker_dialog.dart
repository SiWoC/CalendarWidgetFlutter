import 'package:flutter/material.dart';

import '../utils.dart';

/// Bottom sheet HSV color picker; returns an opaque [Color] or null if cancelled.
Future<Color?> showColorPicker({
  required BuildContext context,
  required Color initialColor,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => _ColorPickerSheet(
      initialColor: initialColor,
    ),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final material = MaterialLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HueSlider(
            value: _hsv.hue,
            onChanged: (hue) => setState(() => _hsv = _hsv.withHue(hue)),
          ),
          const SizedBox(height: 8),
          _SaturationValuePicker(
            hsv: _hsv,
            onChanged: (hsv) => setState(() => _hsv = hsv),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(material.cancelButtonLabel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, color),
                child: Text(material.okButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const _trackHeight = 20.0;

  static final _rainbowColors = List<Color>.generate(
    7,
    (index) => HSVColor.fromAHSV(1, index * 60, 1, 1).toColor(),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: _trackHeight,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
          overlayColor: Colors.black12,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: _trackHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_trackHeight / 2),
                gradient: LinearGradient(colors: _rainbowColors),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            Slider(
              value: value.clamp(0, 359.99),
              min: 0,
              max: 359.99,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  static const _height = 160.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onPanDown: (details) => _update(details.localPosition, width),
            onPanUpdate: (details) => _update(details.localPosition, width),
            onTapDown: (details) => _update(details.localPosition, width),
            child: CustomPaint(
              size: Size(width, _height),
              painter: _SaturationValuePainter(hue: hsv.hue),
              child: Stack(
                children: [
                  Positioned(
                    left: (hsv.saturation * width) - 8,
                    top: ((1 - hsv.value) * _height) - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _update(Offset local, double width) {
    final saturation = (local.dx / width).clamp(0.0, 1.0);
    final value = (1 - local.dy / _height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }
}

class _SaturationValuePainter extends CustomPainter {
  _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

/// Picker result as `#AARRGGBB` with alpha forced to FF.
String opaqueColorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return Utils.argbToHex(0xFF000000 | rgb);
}

/// Parses a stored `#AARRGGBB` value for the picker; ignores the alpha channel.
Color opaqueColorFromHex(String hex) {
  final argb = Utils.hexToArgb(hex);
  return Color(0xFF000000 | (argb & 0x00FFFFFF));
}
