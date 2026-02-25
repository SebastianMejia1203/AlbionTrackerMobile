import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E2E);
  static const Color cardColor = Color(0xFF252540);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color damageColor = Color(0xFFE53935);
  static const Color healColor = Color(0xFF43A047);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color fameColor = Color(0xFFFFD54F);
  static const Color respecColor = Color(0xFF7E57C2);
  static const Color mightColor = Color(0xFFFF7043);
  static const Color favorColor = Color(0xFF42A5F5);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
    ),
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      labelSmall: TextStyle(color: textSecondary, fontSize: 10),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333355),
      thickness: 0.5,
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFF212121),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFF212121)),
      bodyMedium: TextStyle(color: Color(0xFF757575)),
      labelSmall: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 0.5,
    ),
  );
}
