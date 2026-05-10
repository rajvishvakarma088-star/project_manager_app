import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFFF8427);
  static const primaryDark = Color(0xFFDD6413);
  static const accent = Color(0xFF159A78);
  static const bgBase = Color(0xFFF5F1E9);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF5E5A55);
  static const textMuted = Color(0xFF8D877F);
  static const error = Color(0xFFD34A3A);
  static const success = Color(0xFF159A78);
  static const warning = Color(0xFFD4AC4F);
  static const mint = Color(0xFFEAF4D9);
  static const cream = Color(0xFFFFF4E5);

  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF4E5),
      Color(0xFFF7F1DC),
      Color(0xFFEAF4D9),
      Color(0xFFF8F8F5),
    ],
  );

  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFFA552)],
  );

  static const fabGradient = LinearGradient(
    colors: [primary, Color(0xFFFFA552)],
  );
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get appTextPrimary =>
      isDarkMode ? const Color(0xFFF7F1EA) : AppColors.textPrimary;
  Color get appTextSecondary =>
      isDarkMode ? const Color(0xFFC9BFAF) : AppColors.textSecondary;
  Color get appTextMuted =>
      isDarkMode ? const Color(0xFF9E9488) : AppColors.textMuted;
  Color get appSurface => isDarkMode ? const Color(0xFF201D19) : Colors.white;
  Color get appSurfaceSoft =>
      isDarkMode ? const Color(0xFF29241F) : AppColors.cream;
  Color get appBorder =>
      isDarkMode ? const Color(0xFF40372E) : const Color(0xFFE1D8CA);
}

ThemeData buildAppTheme({bool dark = false}) {
  final scheme = dark
      ? const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Color(0xFF1E1C19),
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: Color(0xFFF7F1EA),
        )
      : const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        );
  final textTheme = GoogleFonts.poppinsTextTheme().apply(
    bodyColor: dark ? const Color(0xFFF7F1EA) : AppColors.textPrimary,
    displayColor: dark ? const Color(0xFFF7F1EA) : AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: GoogleFonts.poppins().fontFamily,
    textTheme: textTheme,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF11100F) : AppColors.bgBase,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? const Color(0xFF24211D).withOpacity(0.9)
          : Colors.white.withOpacity(0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark
              ? const Color(0xFF40372E)
              : const Color(0xFFE1D8CA).withOpacity(0.8),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF11100F),
                  Color(0xFF1C1915),
                  Color(0xFF17251F),
                  Color(0xFF11100F),
                ],
              )
            : AppColors.bgGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: const SizedBox(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
