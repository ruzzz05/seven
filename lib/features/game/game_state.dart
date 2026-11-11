import 'package:seven_engine/seven_engine.dart';

enum GamePhase { loading, playing, won, lost }

/// Estado del envío al ranking tras ganar.
enum SubmitState { none, sending, sent, queued, notSent }

class GameState {
  const GameState({
    required this.mode,
    required this.phase,
    required this.board,
    this.pendingOp,
    this.firstIndex,
    this.secondIndex,
    this.flash = const {},
    this.moves = const [],
    this.elapsedMs = 0,
    this.showDigitPad = false,
    this.runId,
    this.hint,
    this.submit = SubmitState.none,
    this.position,
    this.bestMs,
  });

  factory GameState.initial(GameMode mode) => GameState(
    mode: mode,
    phase: GamePhase.loading,
    board: Board(List<int?>.filled(Board.size, null)),
  );

  final GameMode mode;
  final GamePhase phase;
  final Board board;
  final Op? pendingOp;
  final int? firstIndex;
  final int? secondIndex;
  final Set<int> flash;
  final List<Move> moves;
  final int elapsedMs;
  final bool showDigitPad;
  final String? runId;
  final String? hint;
  final SubmitState submit;
  final int? position;
  final int? bestMs;

  GameState copyWith({
    GamePhase? phase,
    Board? board,
    Op? pendingOp,
    bool clearPendingOp = false,
    int? firstIndex,
    int? secondIndex,
    bool clearSecond = false,
    bool clearFirst = false,
    Set<int>? flash,
    List<Move>? moves,
    int? elapsedMs,
    bool? showDigitPad,
    String? runId,
    String? hint,
    bool clearHint = false,
    SubmitState? submit,
    int? position,
    int? bestMs,
  }) {
    return GameState(
      mode: mode,
      phase: phase ?? this.phase,
      board: board ?? this.board,
      pendingOp: clearPendingOp ? null : (pendingOp ?? this.pendingOp),
      firstIndex: clearFirst ? null : (firstIndex ?? this.firstIndex),
      secondIndex: clearSecond ? null : (secondIndex ?? this.secondIndex),
      flash: flash ?? this.flash,
      moves: moves ?? this.moves,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      showDigitPad: showDigitPad ?? this.showDigitPad,
      runId: runId ?? this.runId,
      hint: clearHint ? null : (hint ?? this.hint),
      submit: submit ?? this.submit,
      position: position ?? this.position,
      bestMs: bestMs ?? this.bestMs,
    );
  }
}
