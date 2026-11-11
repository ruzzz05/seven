import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/features/game/game_screen.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ruta de asset que muestra un Image.asset (o null).
String? _assetOf(Widget w) => w is Image && w.image is AssetImage
    ? (w.image as AssetImage).assetName
    : null;

Finder _asset(String path) =>
    find.byWidgetPredicate((w) => _assetOf(w) == path);

void main() {
  // Los assets vienen de la beta (data.unity3d). Solo se usan los existentes.
  test('todo asset referenciado en lib/ existe en assets/', () {
    final re = RegExp(r"'(assets/[^']+)'");
    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in re.allMatches(f.readAsStringSync())) {
        if (!File(m.group(1)!).existsSync()) missing.add(m.group(1)!);
      }
    }
    expect(missing, isEmpty);
  });

  testWidgets('pantalla de juego usa los botones de la beta', (tester) async {
    SharedPreferences.setMockInitialValues({'nickname': 'Tester'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore(prefs)),
          rankingBackendProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: GameScreen(mode: GameMode.normal)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(_asset('assets/images/btn_suma.png'), findsOneWidget);
    expect(_asset('assets/images/btn_resta.png'), findsOneWidget);
    expect(_asset('assets/images/btn_mult.png'), findsOneWidget);
    expect(_asset('assets/images/btn_convert.png'), findsOneWidget);
    expect(_asset('assets/images/btn_reinicio.png'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).image?.image is AssetImage &&
            ((w.decoration as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/fondo.png',
      ),
      findsOneWidget,
    );
  });
}
