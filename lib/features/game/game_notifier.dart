import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/providers.dart';
import '../../data/local_store.dart';
import 'game_state.dart';

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);

/// Controla una partida: taps, reglas (seven_engine), cronómetro y envío.
class GameNotifier extends Notifier<GameState> {
  Stopwatch? _watch;
  Timer? _ticker;
  Timer? _flashTimer;

  /// Incrementa en cada partida nueva; descarta trabajo async de partidas viejas.
  int _session = 0;

  @override
  GameState build() {
    ref.onDispose(_disposeTimers);
    return GameState.initial(GameMode.normal);
  }

  bool get _canPlay => state.phase == GamePhase.playing && !state.showDigitPad;

  /// Inicia una partida. Con backend pide tablero y `run_id` al servidor.
  /// Si [board] viene dado (tests, reintentos) no llama al servidor.
  Future<void> start(GameMode mode, {Board? board}) async {
    _disposeTimers();
    final session = ++_session;
    state = GameState.initial(mode);

    var initial = board ?? Board.random(ref.read(rngProvider));
    String? runId;
    final backend = ref.read(rankingBackendProvider);
    if (backend != null && board == null) {
      try {
        final started = await backend.startRun(mode);
        initial = started.board;
        runId = started.runId;
      } catch (_) {
        // Sin red: se juega, pero la partida no irá al ranking.
      }
    }
    if (session != _session) return;

    state = GameState(
      mode: mode,
      phase: GamePhase.playing,
      board: initial,
      runId: runId,
      bestMs: ref.read(localStoreProvider).bestMs(mode),
      hint: backend != null && runId == null
          ? 'Sin conexión: esta partida no irá al ranking'
          : 'Elige una operación',
    );
  }

  void restart() => start(state.mode);

  // ---------------------------------------------------------------- taps

  /// Operación: si ya hay dos números seleccionados, se ejecuta al momento.
  /// Si no, queda pendiente hasta que se elijan los números.
  void tapOp(Op op) {
    if (!_canPlay) return;
    _startClock();
    if (state.pendingOp == op) {
      state = state.copyWith(
        clearPendingOp: true,
        clearFirst: true,
        clearSecond: true,
        hint: 'Elige una operación',
      );
      return;
    }
    state = state.copyWith(pendingOp: op);
    if (state.firstIndex != null && state.secondIndex != null) {
      _executeSelected();
    } else {
      state = state.copyWith(
        hint: state.firstIndex == null
            ? 'Elige el primer número'
            : 'Elige el segundo número',
      );
    }
  }

  /// Números: hasta dos seleccionados (orden de toque). Con la operación ya
  /// elegida, el segundo número ejecuta.
  void tapCell(int i) {
    if (!_canPlay) return;
    if (state.board.cells[i] == null) return;
    _startClock();

    final first = state.firstIndex;
    final second = state.secondIndex;
    if (i == first) {
      state = state.copyWith(
        firstIndex: second,
        clearFirst: second == null,
        clearSecond: true,
        hint: second == null ? 'Elige un número' : 'Elige el primer número',
      );
      return;
    }
    if (i == second) {
      state = state.copyWith(
        clearSecond: true,
        hint: 'Elige el segundo número',
      );
      return;
    }
    if (first == null) {
      state = state.copyWith(firstIndex: i, hint: 'Elige el segundo número');
      return;
    }
    if (second == null) {
      state = state.copyWith(secondIndex: i);
    } else {
      // Ya hay dos: la nueva sustituye a la más antigua.
      state = state.copyWith(firstIndex: second, secondIndex: i);
    }

    if (state.pendingOp != null) {
      _executeSelected();
    } else {
      state = state.copyWith(hint: 'Elige una operación');
    }
  }

  void _executeSelected() {
    final op = state.pendingOp!;
    final a = state.firstIndex!;
    final b = state.secondIndex!;
    state = state.copyWith(
      clearPendingOp: true,
      clearFirst: true,
      clearSecond: true,
    );
    _play(OpMove(op, a, b));
  }

  void openDigitPad() {
    if (!_canPlay || state.mode != GameMode.normal || !state.board.hasZero) {
      return;
    }
    state = state.copyWith(showDigitPad: true);
  }

  void closeDigitPad() {
    if (state.showDigitPad) state = state.copyWith(showDigitPad: false);
  }

  void pickDigit(int digit) {
    state = state.copyWith(showDigitPad: false);
    final move = ConvertMove(digit);
    final res = apply(state.board, state.mode, move);
    if (res case Applied(:final board)) {
      state = state.copyWith(
        board: board,
        moves: [...state.moves, move],
        clearHint: true,
      );
      _afterMove();
    }
  }

  // ------------------------------------------------------------- internals

  void _play(Move move) {
    final res = apply(state.board, state.mode, move);
    switch (res) {
      case Invalid(:final reason):
        _flash(move);
        state = state.copyWith(
          clearPendingOp: true,
          clearFirst: true,
          hint: _reasonText(reason),
        );
      case Applied(:final board):
        state = state.copyWith(
          board: board,
          moves: [...state.moves, move],
          clearPendingOp: true,
          clearFirst: true,
          clearHint: true,
        );
        _afterMove();
    }
  }

  void _afterMove() {
    final o = outcome(state.board, state.mode);
    switch (o) {
      case Outcome.won:
        unawaited(_finishWon());
      case Outcome.lost:
        final ms = _stopClock();
        state = state.copyWith(phase: GamePhase.lost, elapsedMs: ms);
      case Outcome.ongoing:
        if (state.mode == GameMode.normal &&
            state.board.values.length == 1 &&
            state.board.hasZero) {
          state = state.copyWith(hint: 'Convierte el 0 para terminar');
        }
    }
  }

  Future<void> _finishWon() async {
    final session = _session;
    final ms = _stopClock();
    final store = ref.read(localStoreProvider);
    await store.saveBestIfBetter(state.mode, ms);
    state = state.copyWith(
      phase: GamePhase.won,
      elapsedMs: ms,
      bestMs: store.bestMs(state.mode),
      clearHint: true,
      submit: SubmitState.sending,
    );

    final runId = state.runId;
    final backend = ref.read(rankingBackendProvider);
    if (runId == null || backend == null) {
      state = state.copyWith(submit: SubmitState.notSent);
      return;
    }

    final run = PendingRun(runId: runId, moves: state.moves, timeMs: ms);
    SubmitState result;
    int? position;
    try {
      final res = await backend.finishRun(
        runId: run.runId,
        moves: run.moves,
        timeMs: run.timeMs,
      );
      position = res.position;
      result = res.accepted ? SubmitState.sent : SubmitState.notSent;
    } catch (_) {
      await _enqueue(run);
      result = SubmitState.queued;
    }
    if (session != _session) return;
    state = state.copyWith(submit: result, position: position);
  }

  Future<void> _enqueue(PendingRun run) async {
    final store = ref.read(localStoreProvider);
    await store.setPendingRuns([...store.pendingRuns, run]);
  }

  /// Reintenta partidas guardadas sin conexión. Las rechazadas se descartan.
  Future<void> retryPending() async {
    final backend = ref.read(rankingBackendProvider);
    if (backend == null) return;
    final store = ref.read(localStoreProvider);
    for (final run in store.pendingRuns) {
      try {
        await backend.finishRun(
          runId: run.runId,
          moves: run.moves,
          timeMs: run.timeMs,
        );
        await store.setPendingRuns(
          store.pendingRuns.where((p) => p.runId != run.runId).toList(),
        );
      } catch (_) {
        // Sigue en cola; se reintentará en el próximo arranque.
      }
    }
  }

  void _flash(Move move) {
    if (move is! OpMove) return;
    _flashTimer?.cancel();
    state = state.copyWith(flash: {move.i, move.j});
    _flashTimer = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(flash: {});
    });
  }

  void _startClock() {
    if (_watch != null) return;
    _watch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      state = state.copyWith(elapsedMs: _watch!.elapsedMilliseconds);
    });
  }

  int _stopClock() {
    final ms = _watch?.elapsedMilliseconds ?? state.elapsedMs;
    _disposeClock();
    return ms;
  }

  void _disposeClock() {
    _watch?.stop();
    _ticker?.cancel();
    _watch = null;
    _ticker = null;
  }

  void _disposeTimers() {
    _disposeClock();
    _flashTimer?.cancel();
  }

  static String _reasonText(InvalidReason r) => switch (r) {
    InvalidReason.inexactDivision => 'División no exacta: no permitida',
    InvalidReason.zeroResultHardcore => 'Sin ceros en Hardcore',
    InvalidReason.emptyCell => 'Esa celda está vacía',
    _ => 'Movimiento no válido',
  };
}
