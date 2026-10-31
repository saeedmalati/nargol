import 'package:flutter/material.dart';

/// تم سبزآبی ملایم (کم‌کنتراست و آرام برای چشم)
class NColors {
  static const olive = Color(0xFF2A7D78);
  static const oliveDark = Color(0xFF1C5652);
  static const orange = Color(0xFF37998F);
  static const brown = Color(0xFF3F6E6A);
  static const cream = Color(0xFFF1F7F6);
  static const card = Colors.white;
  static const text = Color(0xFF1F302E);
  static const muted = Color(0xFF66807C);
  static const warm = Color(0xFFE39A3B); // فقط برای نشان تعداد سبد
  static const danger = Color(0xFFC0392B);
  static const success = Color(0xFF3E8E41);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NColors.olive,
    primary: NColors.olive,
    secondary: NColors.orange,
    surface: NColors.cream,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Vazirmatn');
  return base.copyWith(
    scaffoldBackgroundColor: NColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: NColors.cream,
      foregroundColor: NColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 17, fontWeight: FontWeight.w700, color: NColors.text),
    ),
    textTheme: base.textTheme.apply(bodyColor: NColors.text, displayColor: NColors.text),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NColors.olive,
        minimumSize: const Size(48, 46),
        side: const BorderSide(color: NColors.olive),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5E6E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5E6E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NColors.olive, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDDEBE8)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
      side: const BorderSide(color: Color(0xFFD5E6E3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
