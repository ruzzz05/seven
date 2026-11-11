import 'package:flutter/material.dart';

import '../../app/assets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Objetivo',
      'Deja un único número y que sea 7. Si el último número no es 7, pierdes.',
    ),
    (
      'Operaciones',
      'Pulsa +, −, × o ÷. Después toca dos números: el primero y el segundo. '
          'La operación se ejecuta sola al tocar el segundo.',
    ),
    (
      'Resultados',
      'El resultado se escribe en las celdas de los dos números. '
          'Las celdas vacías se muestran con "-" y se acumulan a la izquierda.',
    ),
    (
      'No permitido',
      'Resultados negativos y divisiones no exactas. El movimiento no cambia '
          'nada y la partida sigue.',
    ),
    (
      'Normal: ceros',
      'Si aparece un 0, pulsa CONVERTIR y elige un número del 1 al 9. '
          'Todos los ceros cambian a ese número.',
    ),
    (
      'Hardcore',
      'Igual que Normal, pero sin ceros y sin CONVERTIR. '
          'Un resultado que sea solo 0 no se permite.',
    ),
    (
      'Puntuación',
      'El cronómetro empieza con tu primer toque. Ganas en menos tiempo, '
          'mejor posición en el ranking.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              height: 216,
              child: Image.asset(
                Assets.helpPaper,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final (title, body) in _sections) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
