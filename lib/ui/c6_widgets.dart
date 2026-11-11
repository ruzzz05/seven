import 'package:flutter/material.dart';

import '../app/c6.dart';

/// Tecla con canto inferior. Pulsada: baja 3 px y el canto se acorta.
class C6Key extends StatefulWidget {
  const C6Key({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.height = 64,
    this.width,
    this.active = false,
    this.face,
    this.faceBorder,
    this.radius = C6.radiusKey,
    this.canto,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double height;
  final double? width;
  final bool active;
  final Color? face;
  final Color? faceBorder;
  final double radius;
  final Color? canto;

  @override
  State<C6Key> createState() => _C6KeyState();
}

class _C6KeyState extends State<C6Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final faceColor = widget.face ?? (widget.active ? C6.accent : C6.panel);
    final canto = widget.canto ?? (widget.active ? C6.accentSide : C6.deep);
    final r = BorderRadius.circular(widget.radius);
    final top = _down ? 3.0 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: enabled ? widget.onTap : null,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: canto, borderRadius: r),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  bottom: _down ? C6.cantoKey - 2 : C6.cantoKey,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: faceColor,
                      borderRadius: r,
                      border: Border.all(
                        color:
                            widget.faceBorder ??
                            (widget.active ? C6.accent : C6.border),
                      ),
                    ),
                    child: Center(child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ficha de número del tablero.
class C6Ficha extends StatelessWidget {
  const C6Ficha({
    super.key,
    required this.value,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int? value;
  final int index;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value == null;
    if (empty) {
      return SizedBox(
        height: 104,
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: C6.border,
            radius: C6.radiusFicha,
          ),
          child: Center(
            child: Text('–', style: C6.style(26, color: C6.muted)),
          ),
        ),
      );
    }
    final canto = selected ? C6.accentSide : C6.deep;
    final face = selected ? C6.accent : C6.panel;
    final fg = selected ? C6.onAccent : C6.text;
    final r = BorderRadius.circular(C6.radiusFicha);
    return Semantics(
      button: true,
      label: 'Celda ${index + 1}, valor $value',
      child: GestureDetector(
        key: ValueKey('ficha-$value'),
        onTap: onTap,
        child: Transform.translate(
          offset: Offset(0, selected ? -10 : 0),
          child: SizedBox(
            height: 104,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: canto,
                      borderRadius: r,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: C6.accent.withValues(alpha: 0.18),
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: C6.cantoFicha,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: face,
                      borderRadius: r,
                      border: Border.all(
                        color: selected ? C6.accent : C6.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: C6.style(44, weight: FontWeight.w700, color: fg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora de modo o etiqueta.
class C6Pill extends StatelessWidget {
  const C6Pill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: C6.border),
      borderRadius: BorderRadius.circular(C6.radiusPill),
    ),
    child: Text(label, style: C6.style(13)),
  );
}

/// Insignia cuadrada de la meta.
class C6Insignia extends StatelessWidget {
  const C6Insignia({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: C6.accent,
      borderRadius: BorderRadius.circular(C6.radiusKey),
    ),
    child: Text(
      value,
      style: C6.style(28, weight: FontWeight.w700, color: C6.onAccent),
    ),
  );
}

/// Cuatro cuadraditos: huecos para celdas vacías, lima para números.
class C6Quedan extends StatelessWidget {
  const C6Quedan({super.key, required this.values});

  /// Por cada celda del tablero: null = vacía.
  final List<int?> values;

  @override
  Widget build(BuildContext context) {
    final n = values.where((v) => v != null).length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in values)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            decoration: BoxDecoration(
              color: v == null ? null : C6.accent,
              border: v == null
                  ? Border.all(color: C6.muted, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 8),
        Text('quedan $n', style: C6.style(11, color: C6.muted)),
      ],
    );
  }
}

/// Etiqueta pequeña (tiempo, meta, mejor…).
class C6Label extends StatelessWidget {
  const C6Label(this.text, {super.key, this.color = C6.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: C6.style(11, color: color));
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rr);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Página C6: SafeArea + desplazable que ocupa al menos la altura de la
/// pantalla (los `Spacer` empujan al fondo) y no se desborda en pantallas bajas.
class C6Page extends StatelessWidget {
  const C6Page({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 46, 22, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
