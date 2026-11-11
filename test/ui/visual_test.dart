import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/features/game/game_notifier.dart';
import 'package:seven/features/game/game_screen.dart';
import 'package:seven/features/home/home_screen.dart';
import 'package:seven/app/theme.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Capturas de referencia a 360×780 (gama de teléfono).
Future<Widget> _host(Widget child, {GameMode? mode}) async {
  SharedPreferences.setMockInitialValues({'nickname': 'Tester'});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(LocalStore(prefs)),
      rankingBackendProvider.overrideWithValue(null),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(SevenPalette.of(mode ?? GameMode.normal)),
      home: child,
    ),
  );
}

Future<void> _loadFonts() async {
  for (final (family, path) in [
    ('PerfectDOSVGA437', 'assets/fonts/PerfectDOSVGA437.ttf'),
    ('LiberationSans', 'assets/fonts/LiberationSans.ttf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(path));
    await loader.load();
  }
}

/// Espera a que los sprites se decodifiquen (son asíncronos en el test).
Future<void> _settle(WidgetTester tester) async {
  for (var k = 0; k < 4; k++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('golden: inicio', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(await _host(const HomeScreen()));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('golden: juego normal', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final host = await _host(
      const GameScreen(mode: GameMode.normal),
      mode: GameMode.normal,
    );
    await tester.pumpWidget(host);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    await container
        .read(gameProvider.notifier)
        .start(GameMode.normal, board: Board([null, 0, 3, 5]));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/game_normal.png'),
    );
  });

  testWidgets('golden: juego hardcore', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final host = await _host(
      const GameScreen(mode: GameMode.hardcore),
      mode: GameMode.hardcore,
    );
    await tester.pumpWidget(host);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    await container
        .read(gameProvider.notifier)
        .start(GameMode.hardcore, board: Board([null, 4, 6, 9]));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/game_hardcore.png'),
    );
  });
}
