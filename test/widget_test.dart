import 'package:flutter_test/flutter_test.dart';

import 'package:app_biblioteca/main.dart';

void main() {
  testWidgets('App Biblioteca loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BibliotecaApp());

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
   expect(find.text('Login'), findsOneWidget);
  });
}
