import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:seven/features/game/game_notifier.dart';
import 'package:seven/features/game/game_state.dart';
import 'package:seven_engine/seven_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(LocalStore(prefs)),
      rankingBackendProvider.overrideWithValue(null),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  late ProviderContainer c;
  GameNotifier notifier() => c.read(gameProvider.notifier);
  GameState state() => c.read(gameProvider);

  setUp(() async => c = await _container());

  group('números primero, operación después', () {
    test('dos números y luego la operación ejecuta', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapCell(2)
        ..tapCell(3)
        ..tapOp(Op.mul);
      expect(state().board, Board([null, null, 1, 5]));
      expect(state().firstIndex, isNull);
      expect(state().secondIndex, isNull);
      expect(state().pendingOp, isNull);
    });

    test(
      'dos números sin operación no ejecutan ni cambian el tablero',
      () async {
        await notifier().start(
          GameMode.normal,
          board: Board([null, null, 3, 5]),
        );
        notifier()
          ..tapCell(2)
          ..tapCell(3);
        expect(state().board, Board([null, null, 3, 5]));
        expect(state().firstIndex, 2);
        expect(state().secondIndex, 3);
        expect(state().hint, 'Elige una operación');
      },
    );

    test('el orden de toque sigue importando para la resta', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapCell(3)
        ..tapCell(2)
        ..tapOp(Op.sub);
      // 5 primero, 3 después: 5 − 3 = 2 (la resta es |a − b|, da igual el orden)
      expect(state().board, Board([null, null, null, 2]));
    });

    test(
      'operación inválida con números primero: no cambia y limpia selección',
      () async {
        await notifier().start(
          GameMode.normal,
          board: Board([null, null, 3, 5]),
        );
        notifier()
          ..tapCell(2)
          ..tapCell(3)
          ..tapOp(Op.div); // 5 ÷ 3 no exacta
        expect(state().board, Board([null, null, 3, 5]));
        expect(state().flash, {2, 3});
        expect(state().firstIndex, isNull);
        expect(state().secondIndex, isNull);
      },
    );

    test('tocar una celda ya seleccionada la deselecciona', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapCell(2)
        ..tapCell(2);
      expect(state().firstIndex, isNull);
      expect(state().secondIndex, isNull);
    });

    test(
      'con dos seleccionadas, una tercera sustituye a la más antigua',
      () async {
        await notifier().start(GameMode.normal, board: Board([null, 6, 3, 5]));
        notifier()
          ..tapCell(1)
          ..tapCell(2)
          ..tapCell(3);
        expect(state().firstIndex, 2);
        expect(state().secondIndex, 3);
      },
    );

    test('operación primero sigue funcionando', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapOp(Op.mul)
        ..tapCell(2)
        ..tapCell(3);
      expect(state().board, Board([null, null, 1, 5]));
    });

    test(
      'mezcla: número, operación, número ejecuta con el segundo número',
      () async {
        await notifier().start(
          GameMode.normal,
          board: Board([null, null, 3, 5]),
        );
        notifier()
          ..tapCell(2)
          ..tapOp(Op.mul)
          ..tapCell(3);
        expect(state().board, Board([null, null, 1, 5]));
      },
    );
  });
}
