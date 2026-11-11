import 'model.dart';

/// Target del juego: el último número debe ser este.
const int target = 7;

/// Aplica [move] sobre [board] según [mode]. No modifica el tablero original.
ApplyResult apply(Board board, GameMode mode, Move move) {
  return switch (move) {
    OpMove() => _applyOp(board, mode, move),
    ConvertMove() => _applyConvert(board, mode, move),
  };
}

ApplyResult _applyOp(Board board, GameMode mode, OpMove move) {
  final i = move.i;
  final j = move.j;
  // a = primer operando (cells[i]), b = segundo (cells[j]); i y j pueden
  // venir en cualquier orden. El resultado se escribe en la celda más a la
  // izquierda primero.
  if (i < 0 || j < 0 || i >= Board.size || j >= Board.size || i == j) {
    return const Invalid(InvalidReason.badIndices);
  }
  final a = board.cells[i];
  final b = board.cells[j];
  if (a == null || b == null) {
    return const Invalid(InvalidReason.emptyCell);
  }

  // El orden de los operandos no altera el resultado: la resta es |a − b| y
  // la división es mayor ÷ menor (debe ser exacta y el menor no puede ser 0).
  final big = a > b ? a : b;
  final small = a > b ? b : a;
  final int r;
  switch (move.op) {
    case Op.add:
      r = a + b;
    case Op.sub:
      r = big - small;
    case Op.mul:
      r = a * b;
    case Op.div:
      if (small == 0 || big % small != 0) {
        return const Invalid(InvalidReason.inexactDivision);
      }
      r = big ~/ small;
  }

  var digits = r.toString().split('');
  if (mode == GameMode.hardcore) {
    digits = digits.where((d) => d != '0').toList();
    if (digits.isEmpty) {
      return const Invalid(InvalidReason.zeroResultHardcore);
    }
  }

  final lo = i < j ? i : j;
  final hi = i < j ? j : i;
  final next = List<int?>.from(board.cells);
  next[lo] = null;
  next[hi] = null;
  next[lo] = int.parse(digits[0]);
  if (digits.length > 1) {
    next[hi] = int.parse(digits[1]);
  }
  return Applied(Board.alignRight(next));
}

ApplyResult _applyConvert(Board board, GameMode mode, ConvertMove move) {
  if (mode != GameMode.normal) {
    return const Invalid(InvalidReason.convertNotAllowed);
  }
  if (move.digit < 1 || move.digit > 9) {
    return const Invalid(InvalidReason.convertBadDigit);
  }
  if (!board.hasZero) {
    return const Invalid(InvalidReason.convertNoZeros);
  }
  final next = board.cells.map((c) => c == 0 ? move.digit : c).toList();
  return Applied(Board(next));
}

/// Todos los movimientos posibles desde [board] (válidos o no).
Iterable<Move> allCandidateMoves(Board board, GameMode mode) sync* {
  for (var i = 0; i < Board.size; i++) {
    for (var j = i + 1; j < Board.size; j++) {
      for (final op in Op.values) {
        yield OpMove(op, i, j);
      }
    }
  }
  if (mode == GameMode.normal && board.hasZero) {
    for (var d = 1; d <= 9; d++) {
      yield ConvertMove(d);
    }
  }
}

/// True si existe al menos un movimiento válido.
bool hasValidMove(Board board, GameMode mode) {
  for (final m in allCandidateMoves(board, mode)) {
    if (apply(board, mode, m) is Applied) return true;
  }
  return false;
}

/// Estado de la partida.
///
/// - Un solo número: 7 → ganada; 0 en Normal → sigue (hay que convertir);
///   cualquier otro → perdida.
/// - Varios números sin movimiento válido → perdida.
Outcome outcome(Board board, GameMode mode) {
  final values = board.values;
  if (values.length == 1) {
    final last = values.single;
    if (last == target) return Outcome.won;
    if (last == 0 && mode == GameMode.normal) return Outcome.ongoing;
    return Outcome.lost;
  }
  if (values.isEmpty) return Outcome.lost;
  return hasValidMove(board, mode) ? Outcome.ongoing : Outcome.lost;
}

/// Ejecuta una secuencia de movimientos. Devuelve el tablero final o el
/// primer movimiento inválido (índice y motivo).
ReplayResult replay(Board start, GameMode mode, List<Move> moves) {
  var board = start;
  for (var k = 0; k < moves.length; k++) {
    final res = apply(board, mode, moves[k]);
    switch (res) {
      case Applied(board: final next):
        board = next;
      case Invalid(:final reason):
        return ReplayResult.failed(k, reason);
    }
  }
  return ReplayResult.ok(board, outcome(board, mode));
}

final class ReplayResult {
  const ReplayResult._({
    required this.board,
    required this.outcome,
    this.failedAt,
    this.reason,
  });

  factory ReplayResult.ok(Board board, Outcome outcome) =>
      ReplayResult._(board: board, outcome: outcome);

  factory ReplayResult.failed(int index, InvalidReason reason) =>
      ReplayResult._(
        board: null,
        outcome: Outcome.ongoing,
        failedAt: index,
        reason: reason,
      );

  final Board? board;
  final Outcome outcome;
  final int? failedAt;
  final InvalidReason? reason;

  bool get isValid => failedAt == null;
}
