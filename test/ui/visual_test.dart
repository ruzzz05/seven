import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/app/theme.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/features/game/game_notifier.dart';
import 'package:seven/features/game/game_screen.dart';
import 'package:seven/features/help/help_screen.dart';
import 'package:seven/features/home/home_screen.dart';
import 'package:seven/features/ranking/ranking_screen.dart';
import 'package:seven/features/result/result_screen.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Capturas de referencia a 390×844 (teléfono). Se regeneran con
/// `flutter test test/ui/visual_test.dart --update-goldens`.
Future<void> _loadFonts() async {
  final loader = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
  await loader.load();
}

Future<Widget> _host(Widget home) async {
  SharedPreferences.setMockInitialValues({'nickname': 'Tester'});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(LocalStore(prefs)),
      rankingBackendProvider.overrideWithValue(null),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: home,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var k = 0; k < 3; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('golden: inicio', (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _host(const HomeScreen()));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('golden: partida normal', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      await _host(const GameScreen(mode: GameMode.normal)),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    await c
        .read(gameProvider.notifier)
        .start(GameMode.normal, board: Board([null, 0, 3, 5]));
    await tester.pump();
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/game_normal.png'),
    );
  });

  testWidgets('golden: partida hardcore', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      await _host(const GameScreen(mode: GameMode.hardcore)),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    await c
        .read(gameProvider.notifier)
        .start(GameMode.hardcore, board: Board([null, 4, 6, 9]));
    await tester.pump();
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/game_hardcore.png'),
    );
  });

  testWidgets('golden: resultado ganado', (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _host(const ResultScreen()));
    final c = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );
    await c
        .read(gameProvider.notifier)
        .start(GameMode.hardcore, board: Board([null, null, 2, 5]));
    c.read(gameProvider.notifier)
      ..tapOp(Op.add)
      ..tapCell(2)
      ..tapCell(3);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/result_won.png'),
    );
  });

  testWidgets('golden: ranking', (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _host(const RankingScreen()));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ranking.png'),
    );
  });

  testWidgets('golden: ayuda', (tester) async {
    _phone(tester);
    await tester.pumpWidget(await _host(const HelpScreen()));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/help.png'),
    );
  });
}
