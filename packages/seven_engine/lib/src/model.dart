import 'dart:math';

/// Modo de juego.
enum GameMode {
  normal,
  hardcore;

  static GameMode parse(String value) => switch (value) {
        'normal' => GameMode.normal,
        'hardcore' => GameMode.hardcore,
        _ => throw FormatException('Modo desconocido: $value'),
      };
}

/// Operaciones aritméticas.
enum Op {
  add('add'),
  sub('sub'),
  mul('mul'),
  div('div');

  const Op(this.code);

  /// Código usado en JSON (`moves`).
  final String code;

  static Op parse(String code) => switch (code) {
        'add' => Op.add,
        'sub' => Op.sub,
        'mul' => Op.mul,
        'div' => Op.div,
        _ => throw FormatException('Operación desconocida: $code'),
      };
}

/// Tablero: 4 celdas fijas. `null` = vacía.
///
/// Invariante: las celdas vacías están a la izquierda y los valores a la
/// derecha, en el mismo orden relativo (alineación a la derecha).
final class Board {
  Board(List<int?> cells)
      : cells = List.unmodifiable(cells) {
    if (cells.length != size) {
      throw ArgumentError.value(cells, 'cells', 'Debe tener $size celdas');
    }
    for (final c in cells) {
      if (c != null && (c < 0 || c > 9)) {
        throw ArgumentError.value(cells, 'cells', 'Dígito fuera de 0–9');
      }
    }
  }

  static const int size = 4;

  final List<int?> cells;

  /// Tablero inicial aleatorio: 4 dígitos 1–9.
  factory Board.random(Random rng) =>
      Board(List<int?>.generate(size, (_) => rng.nextInt(9) + 1));

  /// Valores presentes, en orden.
  List<int> get values => cells.whereType<int>().toList(growable: false);

  bool get hasZero => values.contains(0);

  /// Alinea a la derecha: vacías a la izquierda, valores a la derecha.
  static Board alignRight(List<int?> cells) {
    final values = cells.whereType<int>().toList();
    final empties = size - values.length;
    return Board([
      ...List<int?>.filled(empties, null),
      ...values,
    ]);
  }

  Map<String, Object?> toJson() => {'cells': cells};

  @override
  bool operator ==(Object other) =>
      other is Board && _listEq(other.cells, cells);

  @override
  int get hashCode => Object.hashAll(cells);

  @override
  String toString() =>
      cells.map((c) => c?.toString() ?? '-').join(' ');

  static bool _listEq(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var k = 0; k < a.length; k++) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

/// Movimiento del jugador.
sealed class Move {
  const Move();

  Map<String, Object?> toJson();

  factory Move.fromJson(Map<String, Object?> json) {
    switch (json['type']) {
      case 'op':
        return OpMove(
          Op.parse(json['op'] as String),
          json['i'] as int,
          json['j'] as int,
        );
      case 'convert':
        return ConvertMove(json['digit'] as int);
    }
    throw FormatException('Movimiento desconocido: $json');
  }
}

/// Aplica [op] entre la celda [i] (primer operando) y la celda [j] (segundo).
/// `i` y `j` son índices distintos en cualquier orden.
final class OpMove extends Move {
  const OpMove(this.op, this.i, this.j);

  final Op op;
  final int i;
  final int j;

  @override
  Map<String, Object?> toJson() => {
        'type': 'op',
        'op': op.code,
        'i': i,
        'j': j,
      };
}

/// Convierte todos los ceros en [digit] (solo modo normal).
final class ConvertMove extends Move {
  const ConvertMove(this.digit);

  final int digit;

  @override
  Map<String, Object?> toJson() => {'type': 'convert', 'digit': digit};
}

/// Resultado de aplicar un movimiento.
sealed class ApplyResult {
  const ApplyResult();
}

final class Applied extends ApplyResult {
  const Applied(this.board);
  final Board board;
}

final class Invalid extends ApplyResult {
  const Invalid(this.reason);
  final InvalidReason reason;
}

enum InvalidReason {
  badIndices,
  emptyCell,
  inexactDivision,
  zeroResultHardcore,
  convertNotAllowed,
  convertNoZeros,
  convertBadDigit,
}

enum Outcome { ongoing, won, lost }
