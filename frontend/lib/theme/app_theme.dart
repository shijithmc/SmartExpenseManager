import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;

  static const spacingXS = 8.0;
  static const spacingSM = 16.0;
  static const spacingMD = 24.0;
  static const spacingLG = 32.0;
  static const spacingXL = 40.0;

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color gradientEnd = Color(0xFF8B5CF6);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);

  static final shadowLow = [
    BoxShadow(
      color: Colors.black.withAlpha(18),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static final shadowMedium = [
    BoxShadow(
      color: Colors.black.withAlpha(25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      colorSchemeSeed: AppTokens.primaryColor,
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: const Color(0xFFE8EAF0)),
        ),
        surfaceTintColor: Colors.transparent,
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F6FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: base.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F1F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTokens.primaryColor.withAlpha(25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.primaryColor, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTokens.primaryColor,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTokens.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      colorSchemeSeed: AppTokens.primaryColor,
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0F14),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        surfaceTintColor: Colors.transparent,
        color: const Color(0xFF181B25),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0F14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181B25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: const Color(0xFF181B25),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTokens.primaryColor.withAlpha(35),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTokens.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(15),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
