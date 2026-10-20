import 'package:flutter_test/flutter_test.dart';
import 'package:carpinteria_movil_sw2/main.dart';

void main() {
  testWidgets('Renderiza pantalla de Login de Carpintería por defecto',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Carpintería El Roble'), findsOneWidget);
  });
}
