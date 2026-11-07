import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:editnova/pages/home_page.dart';

void main() {
  runApp(const EditNovaApp());
}

class EditNovaApp extends StatefulWidget {
  const EditNovaApp({super.key});

  @override
  State<EditNovaApp> createState() => _EditNovaAppState();
}

class _EditNovaAppState extends State<EditNovaApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _darkMode = preferences.getBool('darkMode') ?? false);
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('darkMode', enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData.dark(),
      home: HomePage(onDarkModeChanged: _setDarkMode),
    );
  }
}
