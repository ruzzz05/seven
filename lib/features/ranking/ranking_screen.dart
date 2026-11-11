import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/assets.dart';
import '../../app/pixel_widgets.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/ranking_backend.dart';
import '../common/format.dart';

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<RankEntry>, GameMode>((ref, mode) async {
      final backend = ref.watch(rankingBackendProvider);
      if (backend == null) throw StateError('offline');
      return backend.leaderboard(mode);
    });

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  GameMode _mode = GameMode.normal;

  @override
  Widget build(BuildContext context) {
    final palette = SevenPalette.normal;
    final backendOn = ref.watch(rankingBackendProvider) != null;

    Widget body;
    if (!backendOn) {
      body = const Center(
        child: Text(
          'RANKING NO DISPONIBLE SIN CONEXIÓN CONFIGURADA.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: Assets.fontPixel, fontSize: 12),
        ),
      );
    } else {
      body = ref
          .watch(leaderboardProvider(_mode))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SIN CONEXIÓN.',
                    style: TextStyle(fontFamily: Assets.fontPixel),
                  ),
                  const SizedBox(height: 12),
                  PixelButton(
                    label: 'REINTENTAR',
                    onTap: () => ref.invalidate(leaderboardProvider(_mode)),
                  ),
                ],
              ),
            ),
            data: (rows) => rows.isEmpty
                ? const Center(
                    child: Text(
                      'AÚN NO HAY TIEMPOS. ¡SÉ EL PRIMERO!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Assets.fontPixel,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rows.length,
                    itemBuilder: (_, k) {
                      final r = rows[k];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: LcdPanel(
                          child: Row(
                            children: [
                              Text(
                                '#${r.position}',
                                style: TextStyle(
                                  fontFamily: Assets.fontPixel,
                                  fontSize: 16,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.nickname,
                                  style: const TextStyle(
                                    fontFamily: Assets.fontPixel,
                                    fontSize: 16,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                              Text(
                                formatMs(r.timeMs),
                                style: TextStyle(
                                  fontFamily: Assets.fontPixel,
                                  fontSize: 16,
                                  color: palette.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
    }

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    PixelButton(
                      label: '<',
                      width: 48,
                      height: 48,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'RANKING MUNDIAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Assets.fontPixel,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final m in GameMode.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: PixelButton(
                            label: m == GameMode.normal ? 'NORMAL' : 'HARDCORE',
                            height: 44,
                            face: _mode == m ? palette.accent : null,
                            onTap: () => setState(() => _mode = m),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
