import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/c6.dart';
import '../../app/providers.dart';
import '../../data/ranking_backend.dart';
import '../../ui/c6_widgets.dart';
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
      ref.read(nicknameProvider.notifier).syncRemote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nick = ref.watch(nicknameProvider);
    return Scaffold(
      body: C6Page(
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SEVEN',
              textAlign: TextAlign.center,
              style: C6.style(56, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'llega a 7 con cuatro números',
              textAlign: TextAlign.center,
              style: C6.style(12, color: C6.muted),
            ),
            const SizedBox(height: 40),
            C6Key(
              height: 88,
              face: C6.accent,
              faceBorder: C6.accent,
              canto: C6.accentSide,
              semanticLabel: 'Jugar en modo normal',
              onTap: () => context.push('/game/${GameMode.normal.name}'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'normal',
                    style: C6.style(
                      20,
                      weight: FontWeight.w700,
                      color: C6.onAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'con ceros y convertir',
                    style: C6.style(10, color: C6.onAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: C6.gap + 6),
            C6Key(
              height: 88,
              semanticLabel: 'Jugar en modo hardcore',
              onTap: () => context.push('/game/${GameMode.hardcore.name}'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'hardcore',
                    style: C6.style(20, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('sin ceros', style: C6.style(10, color: C6.muted)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: C6Key(
                    height: 52,
                    semanticLabel: 'Ranking mundial',
                    onTap: () => context.push('/ranking'),
                    child: Text(
                      'ranking',
                      style: C6.style(14, weight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: C6.gap),
                Expanded(
                  child: C6Key(
                    height: 52,
                    semanticLabel: 'Ayuda',
                    onTap: () => context.push('/help'),
                    child: Text(
                      'ayuda',
                      style: C6.style(14, weight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                nick == null ? '' : 'jugador: $nick',
                style: C6.style(11, color: C6.muted),
              ),
            ),
            if (!AppConfig.backendEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'sin conexión: sin ranking mundial',
                    style: C6.style(10, color: C6.muted),
                  ),
                ),
              ),
            Center(
              child: TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text('salir', style: C6.style(12, color: C6.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
