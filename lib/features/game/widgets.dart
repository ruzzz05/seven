import 'package:flutter/material.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/assets.dart';
import '../../app/pixel_widgets.dart';
import '../../app/theme.dart';

/// Imagen de pixel art sin suavizado.
Widget pixelImage(
  String asset, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) => Image.asset(
  asset,
  width: width,
  height: height,
  fit: fit,
  filterQuality: FilterQuality.none,
);

/// Ficha del tablero: celda blanca de la beta, o metal si está vacía.
class CellTile extends StatelessWidget {
  const CellTile({
    super.key,
    required this.index,
    required this.value,
    required this.palette,
    required this.selected,
    required this.flash,
    required this.onTap,
  });

  final int index;
  final int? value;
  final SevenPalette palette;
  final bool selected;
  final bool flash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value == null;
    return Semantics(
      label: empty
          ? 'Celda ${index + 1}, vacía'
          : 'Celda ${index + 1}, valor $value',
      button: !empty,
      child: GestureDetector(
        onTap: empty ? null : onTap,
        child: SizedBox(
          height: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              pixelImage(
                empty ? Assets.cellEmpty : Assets.cellBg,
                fit: BoxFit.fill,
              ),
              if (flash)
                ColoredBox(color: palette.danger.withValues(alpha: 0.85)),
              if (selected) pixelImage(Assets.border, fit: BoxFit.fill),
              Center(
                child: Text(
                  value?.toString() ?? '-',
                  style: TextStyle(
                    fontFamily: Assets.fontPixel,
                    fontSize: 40,
                    color: empty ? palette.text : const Color(0xFF1C1C1C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de operación. +, − y × usan los sprites de la beta. ÷ no tiene
/// sprite en la beta, así que se dibuja con el mismo bisel metálico.
class OpButton extends StatelessWidget {
  const OpButton({
    super.key,
    required this.op,
    required this.palette,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final Op op;
  final SevenPalette palette;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  static String? asset(Op op) => switch (op) {
    Op.add => Assets.btnSuma,
    Op.sub => Assets.btnResta,
    Op.mul => Assets.btnMult,
    Op.div => null,
  };

  @override
  Widget build(BuildContext context) {
    final img = asset(op);
    final content = img != null
        ? Opacity(
            opacity: enabled ? 1 : 0.4,
            child: pixelImage(img, fit: BoxFit.contain),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              PixelButton(
                label: '',
                height: 56,
                enabled: enabled,
                onTap: onTap,
              ),
              const IgnorePointer(
                child: CustomPaint(size: Size(32, 32), painter: _DivideGlyph()),
              ),
            ],
          );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          button: true,
          selected: active,
          label: 'Operación ${op.name}',
          child: GestureDetector(
            onTap: img != null && enabled ? onTap : null,
            child: Container(
              height: 56,
              decoration: active
                  ? BoxDecoration(
                      border: Border.all(color: palette.accent, width: kPixel),
                    )
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel 1–9 que aparece solo al pulsar Convertir (modo Normal).
class DigitPad extends StatelessWidget {
  const DigitPad({super.key, required this.palette, required this.onPick});

  final SevenPalette palette;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONVERTIR CEROS EN:',
              style: TextStyle(
                fontFamily: Assets.fontPixel,
                color: palette.accent,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var d = 1; d <= 9; d++)
                  GestureDetector(
                    onTap: () => onPick(d),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        pixelImage(Assets.cellBg, fit: BoxFit.fill),
                        Center(
                          child: Text(
                            '$d',
                            style: const TextStyle(
                              fontFamily: Assets.fontPixel,
                              fontSize: 28,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Símbolo ÷ dibujado en bloques pixel (la beta no tiene sprite para él).
class _DivideGlyph extends CustomPainter {
  const _DivideGlyph();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..isAntiAlias = false;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(cx - 12, cy - 2, 24, 4), paint); // barra
    canvas.drawRect(
      Rect.fromLTWH(cx - 2, cy - 12, 4, 4),
      paint,
    ); // punto arriba
    canvas.drawRect(Rect.fromLTWH(cx - 2, cy + 8, 4, 4), paint); // punto abajo
  }

  @override
  bool shouldRepaint(_DivideGlyph old) => false;
}
