import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF6F8F7);

  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF12312D),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      // ... other text styles ...
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF1F2A28),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
