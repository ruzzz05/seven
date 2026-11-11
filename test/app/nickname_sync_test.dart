import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/data/ranking_backend.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingBackend implements RankingBackend {
  final saved = <String>[];

  @override
  Future<void> saveNickname(String nickname) async => saved.add(nickname);

  @override
  Future<StartedRun> startRun(GameMode mode) => throw UnimplementedError();

  @override
  Future<FinishResult> finishRun({
    required String runId,
    required List<Move> moves,
    required int timeMs,
  }) => throw UnimplementedError();

  @override
  Future<List<RankEntry>> leaderboard(
    GameMode mode, {
    int limit = 100,
    int offset = 0,
  }) => throw UnimplementedError();
}

void main() {
  test('sincroniza el apodo local con el backend', () async {
    SharedPreferences.setMockInitialValues({'nickname': 'Jugador1'});
    final prefs = await SharedPreferences.getInstance();
    final backend = RecordingBackend();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(LocalStore(prefs)),
        rankingBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(c.dispose);

    await c.read(nicknameProvider.notifier).syncRemote();
    expect(backend.saved, ['Jugador1']);
  });

  test('sin apodo local no llama al backend', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = RecordingBackend();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(LocalStore(prefs)),
        rankingBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(c.dispose);

    await c.read(nicknameProvider.notifier).syncRemote();
    expect(backend.saved, isEmpty);
  });

  test('sin backend no falla', () async {
    SharedPreferences.setMockInitialValues({'nickname': 'Jugador1'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(LocalStore(prefs)),
        rankingBackendProvider.overrideWithValue(null),
      ],
    );
    addTearDown(c.dispose);

    await c.read(nicknameProvider.notifier).syncRemote();
  });
}
