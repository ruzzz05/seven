import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/ranking_backend.dart';

/// Se sobrescribe en `main.dart` con la instancia ya inicializada.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider no inicializado'),
);

/// null = modo offline (sin ranking).
final rankingBackendProvider = Provider<RankingBackend?>((ref) => null);

/// Fuente de aleatoriedad. Sobrescribible en tests.
final rngProvider = Provider<Random>((ref) => Random());

/// Apodo local. null = todavía no elegido.
class NicknameNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(localStoreProvider).nickname;

  Future<void> save(String nickname) async {
    await ref.read(localStoreProvider).setNickname(nickname);
    state = nickname;
    final backend = ref.read(rankingBackendProvider);
    if (backend != null) {
      try {
        await backend.saveNickname(nickname);
      } catch (_) {
        // Se reintentará al próximo envío de partida (ver game_notifier).
      }
    }
  }
}

final nicknameProvider = NotifierProvider<NicknameNotifier, String?>(
  NicknameNotifier.new,
);
