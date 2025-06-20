import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get mainTheme => ThemeData(
    fontFamily: 'AstaSans', // 메인 포트: 잘난체
    primaryColor: const Color(0xFF1E6FD9), // 기본 파랑
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E6FD9),
      primary: const Color(0xFF1E6FD9),   // 기본 파랑
      secondary: const Color(0xFFFACC15), // 포인트 노랑
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'AstaSans'),
      titleLarge: TextStyle(fontFamily: 'AstaSans'),
      bodyLarge: TextStyle(fontFamily: 'AstaSans'),
      bodyMedium: TextStyle(fontFamily: 'AstaSans'),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E6FD9),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E6FD9),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: 'AstaSans'),
      ),
    ),
  );
}