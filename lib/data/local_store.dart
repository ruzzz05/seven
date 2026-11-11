import 'dart:convert';

import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Partida ganada que aún no se ha confirmado en el servidor.
class PendingRun {
  const PendingRun({
    required this.runId,
    required this.moves,
    required this.timeMs,
  });

  factory PendingRun.fromJson(Map<String, Object?> json) => PendingRun(
    runId: json['run_id'] as String,
    moves: (json['moves'] as List)
        .map((m) => Move.fromJson((m as Map).cast<String, Object?>()))
        .toList(),
    timeMs: json['time_ms'] as int,
  );

  final String runId;
  final List<Move> moves;
  final int timeMs;

  Map<String, Object?> toJson() => {
    'run_id': runId,
    'moves': moves.map((m) => m.toJson()).toList(),
    'time_ms': timeMs,
  };
}

/// Persistencia local (SharedPreferences). Operaciones tolerantes a fallos.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _nicknameKey = 'nickname';
  static const _pendingKey = 'pending_runs';

  String? get nickname => _prefs.getString(_nicknameKey);

  Future<void> setNickname(String value) =>
      _prefs.setString(_nicknameKey, value);

  int? bestMs(GameMode mode) => _prefs.getInt('best_ms.${mode.name}');

  Future<void> saveBestIfBetter(GameMode mode, int ms) async {
    final current = bestMs(mode);
    if (current == null || ms < current) {
      await _prefs.setInt('best_ms.${mode.name}', ms);
    }
  }

  List<PendingRun> get pendingRuns {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingRun.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> setPendingRuns(List<PendingRun> runs) => _prefs.setString(
    _pendingKey,
    jsonEncode(runs.map((r) => r.toJson()).toList()),
  );
}
