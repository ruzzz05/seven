import 'package:flutter/material.dart';
import 'package:seven_engine/seven_engine.dart';

import 'assets.dart';

/// Paleta muestreada de los sprites de la beta (ver assets/images).
/// Modo Hardcore usa los rojos de los botones R/X de la beta como fondo.
class SevenPalette {
  const SevenPalette({
    required this.bg,
    required this.surface,
    required this.cell,
    required this.cellEmpty,
    required this.accent,
    required this.op,
    required this.danger,
    required this.ok,
    required this.text,
    required this.metalLight,
    required this.metalDark,
    required this.metalEdge,
  });

  static const normal = SevenPalette(
    bg: Color(0xFF4D4C4D), // fondo de la beta
    surface: Color(0xFF1C1C1C), // panel LCD
    cell: Color(0xFFFFFFFF), // celda blanca
    cellEmpty: Color(0xFF616161), // metal (celda vacía)
    accent: Color(0xFF00FF48), // verde "SEVEN"
    op: Color(0xFF616161), // metal de botón
    danger: Color(0xFF910000), // rojo de botón R/X
    ok: Color(0xFF00FF48),
    text: Color(0xFFFFFFFF),
    metalLight: Color(0xFF949494),
    metalDark: Color(0xFF2E2E2E),
    metalEdge: Color(0xFF1C1C1C),
  );

  static const hardcore = SevenPalette(
    bg: Color(0xFF520000), // rojo oscuro de la beta
    surface: Color(0xFF1C1C1C),
    cell: Color(0xFFFFFFFF),
    cellEmpty: Color(0xFF610000),
    accent: Color(0xFF00FF48),
    op: Color(0xFF616161),
    danger: Color(0xFFFFFFFF), // flash de error: blanco sobre rojo
    ok: Color(0xFF00FF48),
    text: Color(0xFFFFFFFF),
    metalLight: Color(0xFF949494),
    metalDark: Color(0xFF2E2E2E),
    metalEdge: Color(0xFF1C1C1C),
  );

  static SevenPalette of(GameMode mode) =>
      mode == GameMode.normal ? normal : hardcore;

  final Color bg;
  final Color surface;
  final Color cell;
  final Color cellEmpty;
  final Color accent;
  final Color op;
  final Color danger;
  final Color ok;
  final Color text;
  final Color metalLight;
  final Color metalDark;
  final Color metalEdge;
}

ThemeData buildTheme(SevenPalette p) {
  final base = ThemeData.dark(useMaterial3: true);
  const pixel = Assets.fontPixel;
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: p.accent,
      secondary: p.op,
      surface: p.surface,
      error: p.danger,
      onSurface: p.text,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
      fontFamily: pixel,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      titleTextStyle: TextStyle(fontFamily: pixel, fontSize: 16, color: p.text),
    ),
  );
}
