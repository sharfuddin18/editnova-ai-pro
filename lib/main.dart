import 'package:flutter/material.dart';
import 'package:editnova/pages/home_page.dart';
import 'package:editnova/utils/theme.dart';

void main() {
  runApp(const EditNovaApp());
}

class EditNovaApp extends StatelessWidget {
  const EditNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
