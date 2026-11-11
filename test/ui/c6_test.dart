import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/c6.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/app/theme.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/features/game/game_screen.dart';
import 'package:seven/features/game/game_notifier.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('tokens C6 (docs/07-Estilo-C6.md)', () {
    test('colores exactos', () {
      expect(C6.bg, const Color(0xFF0A0A0A));
      expect(C6.panel, const Color(0xFF161616));
      expect(C6.border, const Color(0xFF2C2C2C));
      expect(C6.deep, const Color(0xFF000000));
      expect(C6.text, const Color(0xFFF5F5F5));
      expect(C6.muted, const Color(0xFF8A8A8A));
      expect(C6.accent, const Color(0xFFD4FF3A));
      expect(C6.accentSide, const Color(0xFF8FB01A));
      expect(C6.onAccent, const Color(0xFF0A0A0A));
      expect(C6.danger, const Color(0xFFFF6B6B));
    });

    test('radios y tipografía', () {
      expect(C6.radiusFicha, 14);
      expect(C6.radiusKey, 12);
      expect(C6.family, 'JetBrainsMono');
    });

    test('tema usa fondo negro y JetBrains Mono', () {
      final t = buildTheme();
      expect(t.scaffoldBackgroundColor, C6.bg);
      expect(t.textTheme.bodyMedium?.fontFamily, 'JetBrainsMono');
    });
  });

  group('pantalla de partida C6', () {
    late ProviderContainer c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'nickname': 'Tester'});
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore(prefs)),
          rankingBackendProvider.overrideWithValue(null),
        ],
      );
      addTearDown(c.dispose);
    });

    testWidgets('sin barra de operación en curso', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: GameScreen(mode: GameMode.normal)),
        ),
      );
      await c
          .read(gameProvider.notifier)
          .start(GameMode.normal, board: Board([null, 0, 3, 5]));
      await tester.pump();
      // La barra antigua mostraba "toca otro"; no debe existir.
      expect(find.textContaining('toca otro'), findsNothing);
      expect(find.textContaining('elige'), findsNothing);
    });

    testWidgets('muestra tiempo, meta, cuatro fichas y acciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: GameScreen(mode: GameMode.normal)),
        ),
      );
      await c
          .read(gameProvider.notifier)
          .start(GameMode.normal, board: Board([null, 0, 3, 5]));
      await tester.pump();
      expect(find.text('tiempo'), findsOneWidget);
      expect(find.text('meta'), findsOneWidget);
      expect(find.text('convertir ceros'), findsOneWidget);
      expect(find.byKey(const ValueKey('ficha-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('op-add')), findsOneWidget);
      expect(find.byKey(const ValueKey('op-div')), findsOneWidget);
    });

    testWidgets('en hardcore no aparece convertir', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: GameScreen(mode: GameMode.hardcore)),
        ),
      );
      await c
          .read(gameProvider.notifier)
          .start(GameMode.hardcore, board: Board([null, 4, 6, 9]));
      await tester.pump();
      expect(find.text('convertir ceros'), findsNothing);
    });
  });
}
