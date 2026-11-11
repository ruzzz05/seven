import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:flutter/services.dart';

import '../../app/assets.dart';
import '../../app/pixel_widgets.dart';
import '../../app/providers.dart';
import '../../data/ranking_backend.dart';
import '../game/game_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Reintenta envíos pendientes de partidas anteriores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).retryPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nick = ref.watch(nicknameProvider);
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
                  height: 80,
                  child: Image.asset(
                    Assets.titleSeven,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
                if (nick != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'JUGADOR: $nick',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: Assets.fontPixel,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                PixelButton(
                  label: 'JUGAR NORMAL',
                  height: 56,
                  fontSize: 16,
                  onTap: () => context.push('/game/${GameMode.normal.name}'),
                ),
                const SizedBox(height: 16),
                PixelButton(
                  label: 'JUGAR HARDCORE',
                  height: 56,
                  fontSize: 16,
                  face: const Color(0xFF910000),
                  textColor: const Color(0xFFFFFFFF),
                  onTap: () => context.push('/game/${GameMode.hardcore.name}'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PixelButton(
                        label: 'RANKING',
                        height: 48,
                        onTap: () => context.push('/ranking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SpriteButton(
                      asset: Assets.btnAyuda,
                      semantics: 'Ayuda',
                      onTap: () => context.push('/help'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  child: SpriteButton(
                    asset: Assets.btnSalir,
                    semantics: 'Salir',
                    onTap: () => SystemNavigator.pop(),
                  ),
                ),
                if (!AppConfig.backendEnabled)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'MODO OFFLINE: SIN RANKING MUNDIAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Assets.fontPixel,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
