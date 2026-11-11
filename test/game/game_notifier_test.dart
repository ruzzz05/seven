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

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late ProviderContainer c;
  GameNotifier notifier() => c.read(gameProvider.notifier);
  GameState state() => c.read(gameProvider);

  setUp(() async => c = await _container());

  group('movimientos', () {
    test('multiplicar 3x5 reparte 1 y 5 en las celdas', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapOp(Op.mul)
        ..tapCell(2)
        ..tapCell(3);
      expect(state().board, Board([null, null, 1, 5]));
      expect(state().moves.length, 1);
    });

    test(
      'división no exacta no cambia tablero y marca celdas en flash',
      () async {
        await notifier().start(
          GameMode.normal,
          board: Board([null, null, 3, 5]),
        );
        notifier()
          ..tapOp(Op.div)
          ..tapCell(2)
          ..tapCell(3);
        expect(state().board, Board([null, null, 3, 5]));
        expect(state().flash, {2, 3});
        expect(state().pendingOp, isNull);
        expect(state().hint, 'División no exacta: no permitida');
      },
    );

    test(
      'tocar el segundo operando antes que el primero invierte el orden',
      () async {
        await notifier().start(
          GameMode.normal,
          board: Board([null, null, 3, 5]),
        );
        notifier()
          ..tapOp(Op.sub)
          ..tapCell(3) // 5 primero
          ..tapCell(2); // 3 segundo → 5 - 3 = 2
        expect(state().board, Board([null, null, null, 2]));
      },
    );

    test('cancelar operación con el mismo botón limpia selección', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier()
        ..tapOp(Op.add)
        ..tapCell(2)
        ..tapOp(Op.add);
      expect(state().pendingOp, isNull);
      expect(state().firstIndex, isNull);
    });

    test('tocar celda sin operación pide elegir operación', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 5]));
      notifier().tapCell(2);
      expect(state().hint, 'Elige primero una operación');
      expect(state().board, Board([null, null, 3, 5]));
    });
  });

  group('fin de partida', () {
    test('2+5 deja 7 y gana', () async {
      await notifier().start(
        GameMode.hardcore,
        board: Board([null, null, 2, 5]),
      );
      notifier()
        ..tapOp(Op.add)
        ..tapCell(2)
        ..tapCell(3);
      await _flush();
      expect(state().phase, GamePhase.won);
      expect(state().board, Board([null, null, null, 7]));
    });

    test('2+3 deja 5 y pierde', () async {
      await notifier().start(
        GameMode.hardcore,
        board: Board([null, null, 2, 3]),
      );
      notifier()
        ..tapOp(Op.add)
        ..tapCell(2)
        ..tapCell(3);
      await _flush();
      expect(state().phase, GamePhase.lost);
    });

    test('normal: último número 0 no termina, pide convertir', () async {
      await notifier().start(GameMode.normal, board: Board([null, null, 3, 3]));
      notifier()
        ..tapOp(Op.sub)
        ..tapCell(2)
        ..tapCell(3);
      await _flush();
      expect(state().phase, GamePhase.playing);
      expect(state().board, Board([null, null, null, 0]));
      expect(state().hint, 'Convierte el 0 para terminar');
    });
  });

  group('convertir (solo normal)', () {
    test('elegir 7 cambia todos los ceros', () async {
      await notifier().start(GameMode.normal, board: Board([null, 0, 4, 0]));
      notifier().openDigitPad();
      expect(state().showDigitPad, isTrue);
      notifier().pickDigit(7);
      expect(state().board, Board([null, 7, 4, 7]));
      expect(state().showDigitPad, isFalse);
    });

    test('hardcore no abre el panel', () async {
      await notifier().start(
        GameMode.hardcore,
        board: Board([null, null, 4, 3]),
      );
      notifier().openDigitPad();
      expect(state().showDigitPad, isFalse);
    });
  });

  group('partida sin backend', () {
    test('ganar sin backend marca submit notSent', () async {
      await notifier().start(
        GameMode.hardcore,
        board: Board([null, null, 2, 5]),
      );
      notifier()
        ..tapOp(Op.add)
        ..tapCell(2)
        ..tapCell(3);
      await _flush();
      expect(state().submit, SubmitState.notSent);
    });

    test('mejor tiempo local se guarda al ganar', () async {
      await notifier().start(
        GameMode.hardcore,
        board: Board([null, null, 2, 5]),
      );
      notifier()
        ..tapOp(Op.add)
        ..tapCell(2)
        ..tapCell(3);
      await _flush();
      expect(c.read(localStoreProvider).bestMs(GameMode.hardcore), isNotNull);
    });
  });
}
