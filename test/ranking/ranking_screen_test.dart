import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/data/ranking_backend.dart';
import 'package:seven/features/ranking/ranking_screen.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackend implements RankingBackend {
  FakeBackend({this.rows = const [], this.fail = false});

  final List<RankEntry> rows;
  final bool fail;

  @override
  Future<List<RankEntry>> leaderboard(
    GameMode mode, {
    int limit = 100,
    int offset = 0,
  }) async {
    if (fail) throw Exception('sin red');
    return rows;
  }

  @override
  Future<StartedRun> startRun(GameMode mode) => throw UnimplementedError();

  @override
  Future<FinishResult> finishRun({
    required String runId,
    required List<Move> moves,
    required int timeMs,
  }) => throw UnimplementedError();

  @override
  Future<void> saveNickname(String nickname) async {}
}

RankEntry _row(int pos, String nick, int ms) =>
    RankEntry(position: pos, nickname: nick, timeMs: ms, userId: 'u$pos');

Future<void> _pump(
  WidgetTester tester,
  RankingBackend? backend, {
  String? nickname,
}) async {
  SharedPreferences.setMockInitialValues(
    nickname == null ? {} : {'nickname': nickname},
  );
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(LocalStore(prefs)),
        rankingBackendProvider.overrideWithValue(backend),
      ],
      child: const MaterialApp(home: RankingScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra posiciones, nicks y tiempos', (tester) async {
    await _pump(
      tester,
      FakeBackend(rows: [_row(1, 'NEO', 6410), _row(2, 'RUIZ', 7020)]),
    );
    expect(find.text('NEO'), findsOneWidget);
    expect(find.text('RUIZ'), findsOneWidget);
    expect(find.text('00:06.41'), findsOneWidget);
    expect(find.text('00:07.02'), findsOneWidget);
  });

  testWidgets('resalta mi fila cuando mi apodo está en el ranking', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBackend(rows: [_row(1, 'NEO', 6410), _row(2, 'Tester', 9820)]),
      nickname: 'Tester',
    );
    expect(find.byKey(const ValueKey('mi-fila')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mi-fila')),
        matching: find.text('Tester'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin mi apodo no hay fila resaltada', (tester) async {
    await _pump(
      tester,
      FakeBackend(rows: [_row(1, 'NEO', 6410)]),
      nickname: 'Tester',
    );
    expect(find.byKey(const ValueKey('mi-fila')), findsNothing);
  });

  testWidgets('lista vacía muestra mensaje de primer tiempo', (tester) async {
    await _pump(tester, FakeBackend());
    expect(find.textContaining('sé el primero'), findsOneWidget);
  });

  testWidgets('error de red muestra reintentar', (tester) async {
    await _pump(tester, FakeBackend(fail: true));
    expect(find.text('sin conexión'), findsOneWidget);
    expect(find.text('reintentar'), findsOneWidget);
  });

  testWidgets('sin backend avisa de que no hay ranking', (tester) async {
    await _pump(tester, null);
    expect(find.textContaining('sin conexión configurada'), findsOneWidget);
  });
}
