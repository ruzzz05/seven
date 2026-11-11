import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seven_engine/seven_engine.dart';

import '../features/game/game_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/nickname_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/result/result_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasNickname = ref.read(nicknameProvider) != null;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!hasNickname && !onOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const NicknameScreen()),
      GoRoute(
        path: '/game/:mode',
        builder: (c, s) =>
            GameScreen(mode: GameMode.parse(s.pathParameters['mode']!)),
      ),
      GoRoute(path: '/result', builder: (c, s) => const ResultScreen()),
      GoRoute(path: '/ranking', builder: (c, s) => const RankingScreen()),
      GoRoute(path: '/help', builder: (c, s) => const HelpScreen()),
    ],
  );
});
