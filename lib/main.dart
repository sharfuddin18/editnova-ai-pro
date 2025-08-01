import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/splash_screen.dart';
import 'utils/theme.dart';
import 'ai_assistant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(EditNovaApp());
}

class EditNovaApp extends StatelessWidget {
  final NovaAssistant novaAssistant = NovaAssistant();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova - AI Editor',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomePage(novaAssistant: novaAssistant),
      debugShowCheckedModeBanner: false,
    );
  }
}
