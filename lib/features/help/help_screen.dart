import 'package:flutter/material.dart';

import '../../app/c6.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'objetivo',
      'deja un único número y que sea 7. si el último número no es 7, pierdes.',
    ),
    (
      'operaciones',
      'pulsa +, −, × o ÷ y luego toca dos números. la operación se ejecuta al tocar el segundo.',
    ),
    (
      'resultados',
      'el resultado se reparte en las celdas. las vacías se acumulan a la izquierda.',
    ),
    (
      'no permitido',
      'división no exacta o entre cero. el movimiento no cambia nada.',
    ),
    (
      'normal · ceros',
      'si aparece un 0, pulsa convertir ceros y elige un número del 1 al 9. todos los ceros cambian.',
    ),
    (
      'hardcore',
      'igual que normal, pero sin ceros y sin convertir. un resultado que sea solo 0 no se permite.',
    ),
    (
      'puntuación',
      'el cronómetro empieza con tu primer toque. ganas en menos tiempo, mejor posición.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ayuda', style: C6.style(16))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          for (final (title, body) in _sections) ...[
            Text(
              title,
              style: C6.style(13, weight: FontWeight.w700, color: C6.accent),
            ),
            const SizedBox(height: 6),
            Text(body, style: C6.style(13, color: C6.text)),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}
