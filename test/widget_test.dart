import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_externa/app.dart';

void main() {
  testWidgets('App arranca con pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GestionExternaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Probar conexion'), findsOneWidget);
  });
}
