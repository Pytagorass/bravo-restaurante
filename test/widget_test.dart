import 'package:bravo_restaurante/pages/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeView renders the main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeView()));

    expect(find.text('BRAVO Restaurante'), findsOneWidget);
    expect(find.text('Registrar Pedido'), findsWidgets);
  });
}
