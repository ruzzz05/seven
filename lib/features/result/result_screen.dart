import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/c6.dart';
import '../../ui/c6_widgets.dart';
import '../common/format.dart';
import '../game/game_notifier.dart';
import '../game/game_state.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final won = game.phase == GamePhase.won;

    return Scaffold(
      body: C6Page(
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              won ? '7' : 'fin',
              textAlign: TextAlign.center,
              style: C6.style(
                96,
                weight: FontWeight.w700,
                color: won ? C6.accent : C6.text,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              won ? 'lo conseguiste' : 'último número: ${_last(game)}',
              textAlign: TextAlign.center,
              style: C6.style(13, color: C6.muted),
            ),
            const SizedBox(height: 56),
            if (won) ...[
              _row('tiempo', formatMs(game.elapsedMs), big: true),
              const SizedBox(height: 18),
              if (game.bestMs != null) _row('mejor', formatMs(game.bestMs!)),
              const SizedBox(height: 14),
              _row(
                'posición',
                game.position != null ? '#${game.position}' : '—',
              ),
              const SizedBox(height: 14),
              Text(
                _submitText(game.submit),
                style: C6.style(11, color: C6.muted),
              ),
            ],
            const SizedBox(height: 40),
            C6Key(
              height: 60,
              face: C6.accent,
              faceBorder: C6.accent,
              canto: C6.accentSide,
              semanticLabel: 'Reintentar',
              onTap: () {
                ref.read(gameProvider.notifier).start(game.mode);
                context.pushReplacement('/game/${game.mode.name}');
              },
              child: Text(
                'reintentar',
                style: C6.style(
                  16,
                  weight: FontWeight.w700,
                  color: C6.onAccent,
                ),
              ),
            ),
            const SizedBox(height: C6.gap),
            if (won) ...[
              C6Key(
                height: 52,
                semanticLabel: 'Ver ranking',
                onTap: () => context.push('/ranking'),
                child: Text(
                  'ranking',
                  style: C6.style(14, weight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: C6.gap),
            ],
            C6Key(
              height: 52,
              semanticLabel: 'Volver al menú',
              onTap: () => context.go('/'),
              child: Text('menú', style: C6.style(14, weight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  static String _last(GameState g) =>
      g.board.values.isEmpty ? '-' : '${g.board.values.last}';

  static Widget _row(String label, String value, {bool big = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      C6Label(label),
      const Spacer(),
      Text(
        value,
        style: C6.style(
          big ? 44 : 20,
          weight: big ? FontWeight.w700 : FontWeight.w500,
          color: big ? C6.accent : C6.text,
        ),
      ),
    ],
  );

  static String _submitText(SubmitState s) => switch (s) {
    SubmitState.sending => 'enviando al ranking…',
    SubmitState.sent => 'guardado en el ranking mundial',
    SubmitState.queued => 'sin conexión: se enviará después',
    SubmitState.notSent => 'partida no enviada al ranking',
    SubmitState.none => '',
  };
}
