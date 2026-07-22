import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praktikum1/pages/admin_page.dart';

void main() {
  testWidgets('admin form includes student profile fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminPage()));

    expect(find.text('Buat Akun Mahasiswa'), findsOneWidget);
    expect(find.text('NIM'), findsOneWidget);
    expect(find.text('Jurusan'), findsOneWidget);
    expect(find.text('Alamat'), findsOneWidget);
    expect(find.text('Password akun'), findsOneWidget);
  });
}
