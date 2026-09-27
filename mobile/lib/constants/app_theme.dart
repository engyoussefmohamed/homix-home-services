import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF123A5D);
  static const primaryDark = Color(0xFF0A1E31);
  static const primarySoft = Color(0xFFDCEAF8);
  static const accent = Color(0xFFD89B2D);
  static const accentDark = Color(0xFF8C5D14);
  static const accentSoft = Color(0xFFF7E7C5);
  static const secondary = Color(0xFF2D8B7A);
  static const secondarySoft = Color(0xFFDDF3EE);
  static const success = Color(0xFF1D8A59);
  static const successSoft = Color(0xFFDFF3E7);
  static const error = Color(0xFFC54B48);
  static const errorSoft = Color(0xFFF9E1DE);
  static const info = Color(0xFF6C87A3);
  static const background = Color(0xFFF3E8D8);
  static const backgroundSecondary = Color(0xFFE3D1B7);
  static const backgroundTertiary = Color(0xFFFFFBF5);
  static const cardWhite = Color(0xFFFFFCF8);
  static const glass = Color(0xFFF8F1E7);
  static const textDark = Color(0xFF182938);
  static const textMuted = Color(0xFF6A7888);
  static const border = Color(0xFFD8CAB4);
  static const bottomBar = Color(0xFF10283E);
  static const shadow = Color(0xFF091725);
  static const iconBlueSoft = Color(0xFFD7E9F7);
  static const iconGreenSoft = Color(0xFFDCEFE3);
  static const iconRedSoft = Color(0xFFF5DFDF);
  static const iconGoldSoft = Color(0xFFF5E7D0);
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      tertiary: AppColors.secondary,
      surface: AppColors.cardWhite,
      onSurface: AppColors.textDark,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      surfaceContainerHigh: AppColors.backgroundTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: AppColors.backgroundTertiary,
      canvasColor: AppColors.backgroundTertiary,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
          height: 1.15,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.7,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.65,
          color: AppColors.textDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.55,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textDark,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: AppColors.cardWhite.withValues(alpha: 0.86),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.backgroundTertiary.withValues(alpha: 0.92),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardWhite.withValues(alpha: 0.92),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 78,
        indicatorColor: AppColors.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textMuted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundTertiary.withValues(alpha: 0.96),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 19,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.95),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.primarySoft,
      ),
      dividerColor: AppColors.border,
      dividerTheme: DividerThemeData(
        color: AppColors.border.withValues(alpha: 0.8),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
