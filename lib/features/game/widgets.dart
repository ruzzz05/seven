import 'package:flutter/material.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/c6.dart';
import '../../ui/c6_widgets.dart';

/// Símbolo de operación en la tecla.
String opSymbol(Op op) => switch (op) {
  Op.add => '+',
  Op.sub => '−',
  Op.mul => '×',
  Op.div => '÷',
};

/// Tecla de operación: 64 de alto, símbolo 26/700. La activa usa el acento.
class OpButton extends StatelessWidget {
  const OpButton({
    super.key,
    required this.op,
    required this.active,
    required this.onTap,
  });

  final Op op;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return C6Key(
      key: ValueKey('op-${op.code}'),
      active: active,
      semanticLabel: 'Operación ${op.name}',
      onTap: onTap,
      child: Text(
        opSymbol(op),
        style: C6.style(
          26,
          weight: FontWeight.w700,
          color: active ? C6.onAccent : C6.text,
        ),
      ),
    );
  }
}

/// Panel 1–9 para convertir ceros. Se abre como hoja inferior.
class DigitPad extends StatelessWidget {
  const DigitPad({super.key, required this.onPick});

  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('convertir ceros en', style: C6.style(13, color: C6.muted)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: C6.gap,
              crossAxisSpacing: C6.gap,
              childAspectRatio: 1.6,
              children: [
                for (var d = 1; d <= 9; d++)
                  C6Key(
                    semanticLabel: 'Convertir en $d',
                    onTap: () => onPick(d),
                    child: Text(
                      '$d',
                      style: C6.style(26, weight: FontWeight.w700),
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
