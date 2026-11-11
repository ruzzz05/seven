import 'package:seven_engine/seven_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración por `--dart-define`. Sin ambas variables la app funciona
/// en modo offline (sin ranking).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get backendEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class StartedRun {
  const StartedRun({required this.runId, required this.board});
  final String runId;
  final Board board;
}

class FinishResult {
  const FinishResult({required this.accepted, this.position});
  final bool accepted;
  final int? position;
}

class RankEntry {
  const RankEntry({
    required this.position,
    required this.nickname,
    required this.timeMs,
    required this.userId,
  });

  factory RankEntry.fromJson(Map<String, dynamic> json) => RankEntry(
    position: (json['position'] as num).toInt(),
    nickname: json['nickname'] as String,
    timeMs: (json['time_ms'] as num).toInt(),
    userId: json['user_id'] as String,
  );

  final int position;
  final String nickname;
  final int timeMs;
  final String userId;
}

/// Contrato del backend de ranking. Lanza excepción ante fallo de red.
abstract interface class RankingBackend {
  Future<StartedRun> startRun(GameMode mode);

  Future<FinishResult> finishRun({
    required String runId,
    required List<Move> moves,
    required int timeMs,
  });

  Future<List<RankEntry>> leaderboard(
    GameMode mode, {
    int limit = 100,
    int offset = 0,
  });

  Future<void> saveNickname(String nickname);
}

class SupabaseRankingBackend implements RankingBackend {
  SupabaseRankingBackend(this._client);

  final SupabaseClient _client;

  Future<void> _ensureSession() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  @override
  Future<StartedRun> startRun(GameMode mode) async {
    await _ensureSession();
    final res = await _client.functions.invoke(
      'start-run',
      body: {'mode': mode.name},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    return StartedRun(
      runId: data['run_id'] as String,
      board: Board(
        (data['board'] as List).map((e) => (e as num).toInt() as int?).toList(),
      ),
    );
  }

  @override
  Future<FinishResult> finishRun({
    required String runId,
    required List<Move> moves,
    required int timeMs,
  }) async {
    await _ensureSession();
    final res = await _client.functions.invoke(
      'finish-run',
      body: {
        'run_id': runId,
        'moves': moves.map((m) => m.toJson()).toList(),
        'time_ms': timeMs,
      },
    );
    final data = (res.data as Map).cast<String, dynamic>();
    return FinishResult(
      accepted: data['status'] == 'valid',
      position: (data['position'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<RankEntry>> leaderboard(
    GameMode mode, {
    int limit = 100,
    int offset = 0,
  }) async {
    await _ensureSession();
    final rows = await _client.rpc(
      'get_leaderboard',
      params: {'p_mode': mode.name, 'p_limit': limit, 'p_offset': offset},
    ) as List<dynamic>;
    return rows
        .map((r) => RankEntry.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> saveNickname(String nickname) async {
    await _ensureSession();
    final uid = _client.auth.currentUser!.id;
    await _client.from('profiles').upsert({'id': uid, 'nickname': nickname});
  }
}
