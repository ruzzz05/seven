import 'package:flutter/material.dart';

import 'c6.dart';

/// Tema global: C6 «Negro y lima», JetBrains Mono.
ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C6.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: C6.accent,
      onPrimary: C6.onAccent,
      surface: C6.panel,
      onSurface: C6.text,
      error: C6.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: C6.text,
      displayColor: C6.text,
      fontFamily: C6.family,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: C6.bg,
      foregroundColor: C6.text,
      elevation: 0,
      titleTextStyle: C6.style(16),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: C6.panel),
  );
}
