import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/c6.dart';
import '../../ui/c6_widgets.dart';
import '../common/format.dart';
import 'game_notifier.dart';
import 'game_state.dart';
import 'widgets.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).start(widget.mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final normal = widget.mode == GameMode.normal;
    final canConvert = normal && game.board.hasZero;

    ref.listen<GamePhase>(gameProvider.select((s) => s.phase), (prev, next) {
      if (next == GamePhase.won || next == GamePhase.lost) {
        context.pushReplacement('/result');
      }
    });

    ref.listen<bool>(gameProvider.select((s) => s.showDigitPad), (
      prev,
      next,
    ) async {
      if (next) {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: C6.panel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => DigitPad(
            onPick: (d) {
              Navigator.of(context).pop();
              notifier.pickDigit(d);
            },
          ),
        );
        notifier.closeDigitPad();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: game.phase == GamePhase.loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 46, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera.
                    Row(
                      children: [
                        C6Key(
                          width: 44,
                          height: 44,
                          semanticLabel: 'Volver al menú',
                          onTap: () => context.go('/'),
                          child: const Icon(Icons.chevron_left, color: C6.text),
                        ),
                        const Spacer(),
                        C6Pill(label: normal ? 'normal' : 'hardcore'),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const C6Label('mejor'),
                            const SizedBox(height: 4),
                            Text(
                              game.bestMs == null
                                  ? '--:--.-'
                                  : formatMs(game.bestMs!),
                              style: C6.style(11),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tiempo y meta.
                    Padding(
                      padding: const EdgeInsets.only(top: 34),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const C6Label('tiempo'),
                                const SizedBox(height: 4),
                                Text(
                                  formatMs(game.elapsedMs),
                                  style: C6.style(52, weight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Column(
                            children: [
                              C6Label('meta'),
                              SizedBox(height: 6),
                              C6Insignia(value: '7'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tablero.
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < Board.size; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: C6Ficha(
                                        index: i,
                                        value: game.board.cells[i],
                                        selected:
                                            game.firstIndex == i ||
                                            game.secondIndex == i,
                                        onTap: game.board.cells[i] == null
                                            ? null
                                            : () => notifier.tapCell(i),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            C6Quedan(values: game.board.cells),
                          ],
                        ),
                      ),
                    ),

                    // Operaciones.
                    Row(
                      children: [
                        for (final op in Op.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: C6.gap / 2,
                              ),
                              child: OpButton(
                                op: op,
                                active: game.pendingOp == op,
                                onTap: () => notifier.tapOp(op),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Acciones.
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          if (normal)
                            Expanded(
                              child: C6Key(
                                height: 58,
                                face: C6.cta,
                                faceBorder: C6.cta,
                                canto: C6.ctaSide,
                                semanticLabel: 'Convertir ceros',
                                onTap: canConvert
                                    ? notifier.openDigitPad
                                    : null,
                                child: Text(
                                  'convertir ceros',
                                  style: C6.style(
                                    15,
                                    weight: FontWeight.w700,
                                    color: C6.onCta,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: C6.gap),
                          C6Key(
                            width: 58,
                            height: 58,
                            semanticLabel: 'Reiniciar partida',
                            onTap: notifier.restart,
                            child: const Icon(
                              Icons.replay,
                              color: C6.danger,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
