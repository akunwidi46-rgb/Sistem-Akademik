import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIAKAD - Sistem Informasi Akademik',
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}