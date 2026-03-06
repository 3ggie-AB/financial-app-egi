// widgets/color_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget color picker custom — bisa pilih dari preset atau input hex manual
class ColorPickerWidget extends StatefulWidget {
  final String selectedColor;
  final ValueChanged<String> onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late String _current;
  late TextEditingController _hexCtrl;
  bool _showCustomInput = false;

  final _presets = [
    // Reds
    '#F44336', '#E53935', '#C62828', '#FF5252',
    // Pinks
    '#E91E63', '#AD1457', '#FF4081',
    // Purples
    '#9C27B0', '#6A1B9A', '#EA80FC', '#7C4DFF',
    // Blues
    '#3F51B5', '#1565C0', '#2196F3', '#039BE5', '#00BCD4',
    // Greens
    '#009688', '#2E7D32', '#4CAF50', '#8BC34A', '#CDDC39',
    // Yellows/Oranges
    '#FFEB3B', '#FFC107', '#FF9800', '#FF6D00', '#FF5722',
    // Browns/Greys
    '#795548', '#546E7A', '#607D8B', '#9E9E9E',
    // Dark
    '#212121', '#37474F', '#263238',
    // Whites/Lights
    '#FAFAFA', '#ECEFF1', '#F5F5F5',
  ];

  @override
  void initState() {
    super.initState();
    _current = widget.selectedColor;
    _hexCtrl = TextEditingController(text: _current.replaceAll('#', ''));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color _toColor(String hex) {
    try {
      final h = hex.replaceAll('#', '').padRight(6, '0');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _selectColor(String hex) {
    setState(() {
      _current = hex;
      _hexCtrl.text = hex.replaceAll('#', '');
    });
    widget.onColorChanged(hex);
  }

  void _onHexInput(String val) {
    final clean = val.replaceAll('#', '');
    if (clean.length == 6) {
      try {
        Color(int.parse('FF$clean', radix: 16));
        _selectColor('#$clean');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentColor = _toColor(_current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview + hex input toggle
        Row(
          children: [
            // Color preview circle
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = !_showCustomInput),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outline.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _current.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: scheme.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Ketuk lingkaran untuk input hex manual',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Hex manual input
        if (_showCustomInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _hexCtrl,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
            ],
            onChanged: _onHexInput,
            style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2),
            decoration: InputDecoration(
              prefixText: '# ',
              prefixStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
              labelText: 'Kode Hex',
              counterText: '',
              suffixIcon: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Preset colors grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((hex) {
            final color = _toColor(hex);
            final isSelected = _current.toLowerCase() == hex.toLowerCase();
            return GestureDetector(
              onTap: () => _selectColor(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isSelected ? 36 : 32,
                height: isSelected ? 36 : 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: scheme.onSurface, width: 2.5)
                      : Border.all(color: Colors.transparent, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        size: 16,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}