import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven/app/app.dart';
import 'package:seven/app/providers.dart';
import 'package:seven/data/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('inicio muestra modos de juego', (tester) async {
    SharedPreferences.setMockInitialValues({'nickname': 'Tester'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
        child: const SevenApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('JUGAR NORMAL'), findsOneWidget);
    expect(find.text('JUGAR HARDCORE'), findsOneWidget);
  });

  testWidgets('sin apodo redirige a onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
        child: const SevenApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Elige tu apodo'), findsOneWidget);
  });
}
