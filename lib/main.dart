import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/local_store.dart';
import 'data/ranking_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Solo vertical.
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();

  RankingBackend? backend;
  if (AppConfig.backendEnabled) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    backend = SupabaseRankingBackend(Supabase.instance.client);
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(LocalStore(prefs)),
        rankingBackendProvider.overrideWithValue(backend),
      ],
      child: const SevenApp(),
    ),
  );
}
