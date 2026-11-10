import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webpro2/screens/login_screen.dart';

void main() {
  testWidgets('login screen validates empty fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onLogin: (username, password) async => false),
      ),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Username wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
  });

  testWidgets('login screen reports invalid credentials', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onLogin: (username, password) async => false),
      ),
    );

    await tester.enterText(find.byKey(const Key('login-username')), 'salah');
    await tester.enterText(find.byKey(const Key('login-password')), 'salah');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username atau password tidak sesuai.'), findsOneWidget);
  });
}
