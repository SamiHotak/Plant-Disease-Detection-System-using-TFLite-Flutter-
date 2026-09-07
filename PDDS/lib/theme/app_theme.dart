import 'package:flutter/material.dart';

/// Design system for the Plant Disease Detector.
///
/// All colours are declared as explicit ARGB constants — including their
/// translucent variants. That is deliberate: `Color.withOpacity()` and the
/// `.red` / `.green` / `.blue` accessors were deprecated in Flutter 3.27, so
/// avoiding them entirely keeps this file warning-free on both older and
/// newer SDKs.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color background = Color(0xFF0A0F0D);
  static const Color surface = Color(0xFF121A16);
  static const Color surfaceHigh = Color(0xFF1A241F);
  static const Color border = Color(0xFF243029);

  // Brand
  static const Color primary = Color(0xFF34D399);
  static const Color primaryDeep = Color(0xFF10B981);

  // Semantic
  static const Color healthy = Color(0xFF34D399);
  static const Color caution = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F3);
  static const Color textSecondary = Color(0xFF9CA8A2);
  static const Color textTertiary = Color(0xFF6B7873);

  // Pre-computed translucent variants
  static const Color primaryA08 = Color(0x1434D399);
  static const Color primaryA14 = Color(0x2434D399);
  static const Color primaryA24 = Color(0x3D34D399);
  static const Color primaryA40 = Color(0x6634D399);

  static const Color cautionA14 = Color(0x24FBBF24);
  static const Color cautionA40 = Color(0x66FBBF24);

  static const Color dangerA14 = Color(0x24F87171);
  static const Color dangerA40 = Color(0x66F87171);

  static const Color blackA40 = Color(0x66000000);
  static const Color blackA60 = Color(0x99000000);
  static const Color whiteA08 = Color(0x14FFFFFF);

  /// Colour that represents a severity level.
  static Color forSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'none':
        return healthy;
      case 'low':
        return primary;
      case 'moderate':
        return caution;
      case 'high':
      case 'severe':
        return danger;
      default:
        return textSecondary;
    }
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF04150E),
      secondary: AppColors.primaryDeep,
      onSecondary: Color(0xFF04150E),
      error: AppColors.danger,
      onError: Color(0xFF2A0A0A),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.55,
        color: AppColors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.55,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.5,
        color: AppColors.textTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      // NOTE: `cardTheme` is intentionally not set here. Its type changed from
      // CardTheme to CardThemeData in newer Flutter versions, which breaks the
      // build depending on the SDK. Cards are styled directly instead.
    );
  }
}
