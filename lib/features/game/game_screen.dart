import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/assets.dart';
import '../../app/pixel_widgets.dart';
import '../../app/theme.dart';
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
    final palette = SevenPalette.of(widget.mode);

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
          backgroundColor: palette.bg,
          builder: (_) => DigitPad(
            palette: palette,
            onPick: (d) {
              Navigator.of(context).pop();
              notifier.pickDigit(d);
            },
          ),
        );
        notifier.closeDigitPad();
      }
    });

    final loading = game.phase == GamePhase.loading;
    final canConvert = widget.mode == GameMode.normal && game.board.hasZero;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(Assets.fondo),
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
            // Hardcore: el fondo gris de la beta se tiñe de rojo (multiplicación).
            colorFilter: widget.mode == GameMode.hardcore
                ? ColorFilter.mode(palette.bg, BlendMode.multiply)
                : null,
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Cabecera: volver · modo · cronómetro LCD.
                      Row(
                        children: [
                          PixelButton(
                            label: '<',
                            width: 48,
                            height: 48,
                            fontSize: 16,
                            onTap: () => context.go('/'),
                          ),
                          Expanded(
                            child: Text(
                              widget.mode == GameMode.normal
                                  ? 'NORMAL'
                                  : 'HARDCORE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: Assets.fontPixel,
                                fontSize: 16,
                                color: palette.text,
                              ),
                            ),
                          ),
                          LcdPanel(
                            child: Text(
                              formatMs(game.elapsedMs),
                              style: TextStyle(
                                fontFamily: Assets.fontPixel,
                                fontSize: 16,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        game.hint ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Assets.fontPixel,
                          fontSize: 12,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Center(
                          child: Row(
                            children: [
                              for (var i = 0; i < Board.size; i++)
                                Expanded(
                                  child: CellTile(
                                    index: i,
                                    value: game.board.cells[i],
                                    palette: palette,
                                    selected: game.firstIndex == i,
                                    flash: game.flash.contains(i),
                                    onTap: () => notifier.tapCell(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final op in Op.values)
                            OpButton(
                              op: op,
                              palette: palette,
                              active: game.pendingOp == op,
                              enabled: true,
                              onTap: () => notifier.tapOp(op),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.mode == GameMode.normal)
                            Expanded(
                              child: Opacity(
                                opacity: canConvert ? 1 : 0.4,
                                child: GestureDetector(
                                  onTap: canConvert
                                      ? notifier.openDigitPad
                                      : null,
                                  child: SizedBox(
                                    height: 40,
                                    child: pixelImage(Assets.btnConvert),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 16),
                          SpriteButton(
                            asset: Assets.btnReinicio,
                            semantics: 'Reiniciar partida',
                            onTap: notifier.restart,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
