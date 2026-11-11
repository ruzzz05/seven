import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/assets.dart';
import '../../app/pixel_widgets.dart';
import '../../app/theme.dart';
import '../common/format.dart';
import '../game/game_notifier.dart';
import '../game/game_state.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final palette = SevenPalette.of(game.mode);
    final won = game.phase == GamePhase.won;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.fondo),
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Image.asset(
                    won ? Assets.menuWin : Assets.menuLost,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                LcdPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (won) ...[
                        _row(palette, 'TIEMPO', formatMs(game.elapsedMs)),
                        if (game.bestMs != null)
                          _row(palette, 'MEJOR', formatMs(game.bestMs!)),
                        _row(
                          palette,
                          'POSICIÓN',
                          game.position != null ? '#${game.position}' : '—',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _submitText(game.submit),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Assets.fontPixel,
                            fontSize: 10,
                            color: palette.text,
                          ),
                        ),
                      ] else
                        _row(
                          palette,
                          'ÚLTIMO',
                          game.board.values.isEmpty
                              ? '-'
                              : '${game.board.values.last}',
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                PixelButton(
                  label: 'REINTENTAR',
                  height: 56,
                  onTap: () {
                    ref.read(gameProvider.notifier).start(game.mode);
                    context.pushReplacement('/game/${game.mode.name}');
                  },
                ),
                const SizedBox(height: 12),
                if (won) ...[
                  PixelButton(
                    label: 'RANKING',
                    height: 48,
                    onTap: () => context.push('/ranking'),
                  ),
                  const SizedBox(height: 12),
                ],
                PixelButton(
                  label: 'MENÚ',
                  height: 48,
                  onTap: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _row(SevenPalette p, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Assets.fontPixel,
            fontSize: 12,
            color: p.text,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: Assets.fontPixel,
            fontSize: 20,
            color: p.accent,
          ),
        ),
      ],
    ),
  );

  static String _submitText(SubmitState s) => switch (s) {
    SubmitState.sending => 'ENVIANDO AL RANKING…',
    SubmitState.sent => 'GUARDADO EN EL RANKING MUNDIAL',
    SubmitState.queued => 'SIN CONEXIÓN: SE ENVIARÁ DESPUÉS',
    SubmitState.notSent => 'PARTIDA NO ENVIADA AL RANKING',
    SubmitState.none => '',
  };
}
