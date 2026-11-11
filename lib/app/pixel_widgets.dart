import 'package:flutter/material.dart';

import 'assets.dart';
import 'theme.dart';

/// Tamaño de un "pixel" del arte de la beta, en píxeles lógicos.
const double kPixel = 4;

/// Botón metálico biselado, dibujado con el mismo esquema de colores de los
/// sprites de la beta. Se usa donde la beta no tiene sprite propio.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 48,
    this.fontSize = 16,
    this.enabled = true,
    this.face,
    this.textColor = const Color(0xFF000000),
  });

  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double fontSize;
  final bool enabled;
  final Color? face;
  final Color textColor;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const p = SevenPalette.normal;
    final active = widget.enabled && widget.onTap != null;
    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _down = true) : null,
        onTapUp: active ? (_) => setState(() => _down = false) : null,
        onTapCancel: active ? () => setState(() => _down = false) : null,
        onTap: active ? widget.onTap : null,
        child: Opacity(
          opacity: active ? 1 : 0.4,
          child: CustomPaint(
            painter: _BevelPainter(
              face: widget.face ?? p.op,
              light: p.metalLight,
              dark: p.metalDark,
              edge: p.metalEdge,
              pressed: _down,
            ),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Assets.fontPixel,
                    fontSize: widget.fontSize,
                    color: widget.textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BevelPainter extends CustomPainter {
  const _BevelPainter({
    required this.face,
    required this.light,
    required this.dark,
    required this.edge,
    required this.pressed,
  });

  final Color face;
  final Color light;
  final Color dark;
  final Color edge;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final u = kPixel;
    final paint = Paint()..isAntiAlias = false;
    final hi = pressed ? dark : light;
    final lo = pressed ? light : dark;
    final w = size.width;
    final h = size.height;

    // Borde exterior.
    paint.color = edge;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    // Bisel: arriba/izquierda claro, abajo/derecha oscuro.
    final inner = Rect.fromLTRB(u, u, w - u, h - u);
    paint.color = hi;
    canvas.drawRect(
      Rect.fromLTRB(inner.left, inner.top, inner.right, inner.top + u),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(inner.left, inner.top, inner.left + u, inner.bottom),
      paint,
    );
    paint.color = lo;
    canvas.drawRect(
      Rect.fromLTRB(inner.left, inner.bottom - u, inner.right, inner.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(inner.right - u, inner.top, inner.right, inner.bottom),
      paint,
    );
    // Cara.
    paint.color = face;
    canvas.drawRect(inner.deflate(u), paint);
  }

  @override
  bool shouldRepaint(_BevelPainter old) =>
      old.face != face || old.pressed != pressed;
}

/// Panel LCD: fondo negro, texto verde. Para cronómetro y resultados.
class LcdPanel extends StatelessWidget {
  const LcdPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        border: Border(
          top: BorderSide(color: Color(0xFF2E2E2E), width: kPixel),
          left: BorderSide(color: Color(0xFF2E2E2E), width: kPixel),
          bottom: BorderSide(color: Color(0xFF949494), width: kPixel),
          right: BorderSide(color: Color(0xFF949494), width: kPixel),
        ),
      ),
      child: child,
    );
  }
}

/// Botón con sprite de la beta (sin dibujar nada propio).
class SpriteButton extends StatelessWidget {
  const SpriteButton({
    super.key,
    required this.asset,
    required this.semantics,
    required this.onTap,
    this.size = 48,
  });

  final String asset;
  final String semantics;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            asset,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
