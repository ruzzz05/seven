import 'package:flutter/material.dart';

/// Tokens del estilo C6 «Negro y lima». Fuente: docs/07-Estilo-C6.md.
abstract final class C6 {
  // Color
  static const bg = Color(0xFF0A0A0A);
  static const panel = Color(0xFF161616);
  static const border = Color(0xFF2C2C2C);
  static const deep = Color(0xFF000000);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF8A8A8A);
  static const accent = Color(0xFFD4FF3A);
  static const accentSide = Color(0xFF8FB01A);
  static const onAccent = Color(0xFF0A0A0A);
  static const cta = Color(0xFFF5F5F5);
  static const ctaSide = Color(0xFFA8A8A8);
  static const onCta = Color(0xFF0A0A0A);
  static const danger = Color(0xFFFF6B6B);

  // Forma
  static const radiusFicha = 14.0;
  static const radiusKey = 12.0;
  static const radiusPill = 20.0;
  static const cantoKey = 5.0;
  static const cantoFicha = 7.0;
  static const gap = 10.0;

  // Tipografía
  static const family = 'JetBrainsMono';

  static TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = text,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.1,
  );
}
