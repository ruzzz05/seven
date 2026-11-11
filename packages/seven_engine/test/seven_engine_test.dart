import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:seven_engine/seven_engine.dart';
import 'package:test/test.dart';

Board boardFrom(List<dynamic> raw) =>
    Board(raw.map((e) => e as int?).toList());

InvalidReason reasonFrom(String name) =>
    InvalidReason.values.firstWhere((r) => r.name == name);

Outcome outcomeFrom(String name) =>
    Outcome.values.firstWhere((o) => o.name == name);

void main() {
  final vectors = jsonDecode(
    File('test/vectors/rules.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = (vectors['cases'] as List).cast<Map<String, dynamic>>();

  group('vectores compartidos (rules.json)', () {
    for (final c in cases) {
      test(c['name'] as String, () {
        final mode = GameMode.parse(c['mode'] as String);
        final board = boardFrom(c['board'] as List);
        final exp = c['expect'] as Map<String, dynamic>;

        if (c.containsKey('move')) {
          final move =
              Move.fromJson((c['move'] as Map).cast<String, Object?>());
          final res = apply(board, mode, move);
          if (exp['result'] == 'ok') {
            expect(res, isA<Applied>());
            expect((res as Applied).board, boardFrom(exp['board'] as List));
          } else {
            expect(res, isA<Invalid>());
            expect((res as Invalid).reason,
                reasonFrom(exp['reason'] as String));
          }
        }
        if (exp.containsKey('outcome')) {
          expect(outcome(board, mode), outcomeFrom(exp['outcome'] as String));
        }
      });
    }
  });

  group('invariantes', () {
    test('tablero aleatorio tiene 4 dígitos 1–9 y no tiene ceros', () {
      final rng = Random(42);
      for (var k = 0; k < 500; k++) {
        final b = Board.random(rng);
        expect(b.values.length, 4);
        expect(b.values.every((v) => v >= 1 && v <= 9), isTrue);
      }
    });

    test('alineación a la derecha tras cualquier movimiento válido', () {
      final rng = Random(7);
      for (var game = 0; game < 300; game++) {
        var board = Board.random(rng);
        var mode = game.isEven ? GameMode.normal : GameMode.hardcore;
        for (var step = 0; step < 50; step++) {
          final cands = allCandidateMoves(board, mode)
              .where((m) => apply(board, mode, m) is Applied)
              .toList();
          if (cands.isEmpty) break;
          final m = cands[rng.nextInt(cands.length)];
          board = (apply(board, mode, m) as Applied).board;
          // Vacías a la izquierda, valores a la derecha sin huecos.
          final firstValue = board.cells.indexWhere((c) => c != null);
          if (firstValue != -1) {
            expect(
              board.cells.sublist(firstValue).every((c) => c != null),
              isTrue,
              reason: 'Huecos en $board',
            );
          }
          if (outcome(board, mode) != Outcome.ongoing) break;
        }
      }
    });

    test('hardcore nunca deja un 0 en el tablero', () {
      final rng = Random(99);
      for (var game = 0; game < 300; game++) {
        var board = Board.random(rng);
        for (var step = 0; step < 50; step++) {
          final cands = allCandidateMoves(board, GameMode.hardcore)
              .where((m) => apply(board, GameMode.hardcore, m) is Applied)
              .toList();
          if (cands.isEmpty) break;
          board = (apply(board, GameMode.hardcore, cands[rng.nextInt(cands.length)])
                  as Applied)
              .board;
          expect(board.hasZero, isFalse);
        }
      }
    });
  });

  group('replay', () {
    test('secuencia válida devuelve tablero y resultado', () {
      final start = Board([null, null, 2, 3]);
      final moves = <Move>[
        const OpMove(Op.add, 2, 3), // 2+3 -> - - - 5
      ];
      final r = replay(start, GameMode.normal, moves);
      expect(r.isValid, isTrue);
      expect(r.board, Board([null, null, null, 5]));
      expect(r.outcome, Outcome.lost);
    });

    test('movimiento inválido indica índice y motivo', () {
      final start = Board([null, null, 3, 5]);
      final r = replay(start, GameMode.normal,
          [const OpMove(Op.div, 2, 3)]); // 3 y 5: división no exacta
      expect(r.isValid, isFalse);
      expect(r.failedAt, 0);
      expect(r.reason, InvalidReason.inexactDivision);
    });

    test('partida ganada: 2 + 5 = 7 en dos celdas', () {
      final start = Board([null, null, 2, 5]);
      final r = replay(start, GameMode.hardcore, [const OpMove(Op.add, 2, 3)]);
      expect(r.isValid, isTrue);
      expect(r.board, Board([null, null, null, 7]));
      expect(r.outcome, Outcome.won);
    });
  });

  group('orden de operandos', () {
    test('restar tocando primero la derecha: 5 - 3 = 2 en la celda izquierda',
        () {
      final board = Board([null, null, 3, 5]);
      final res = apply(board, GameMode.normal, const OpMove(Op.sub, 3, 2));
      expect(res, isA<Applied>());
      expect((res as Applied).board, Board([null, null, null, 2]));
    });

    test('resta 3 y 5 da 2 en ambos órdenes', () {
      final board = Board([null, null, 3, 5]);
      final a = apply(board, GameMode.normal, const OpMove(Op.sub, 2, 3));
      final b = apply(board, GameMode.normal, const OpMove(Op.sub, 3, 2));
      expect((a as Applied).board, (b as Applied).board);
    });

    test('mismo índice no es válido', () {
      final board = Board([null, null, 3, 5]);
      final res = apply(board, GameMode.normal, const OpMove(Op.add, 2, 2));
      expect((res as Invalid).reason, InvalidReason.badIndices);
    });
  });

  group('Move JSON', () {
    test('ida y vuelta', () {
      const m = OpMove(Op.mul, 1, 3);
      expect(Move.fromJson(m.toJson()), isA<OpMove>());
      const c = ConvertMove(7);
      expect((Move.fromJson(c.toJson()) as ConvertMove).digit, 7);
    });
  });
}
