import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// The single [ThemeData] for Buddy Tracker.
/// Import this and pass [AppTheme.darkTheme] to [MaterialApp.theme].
abstract class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.deepBlack,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.deepBlack,
          primary: AppColors.spiderRed,
          secondary: AppColors.webBlue,
          tertiary: AppColors.electricBlue,
          onSurface: AppColors.white,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          error: AppColors.spiderRed,
          outline: AppColors.webBlue,
        ),

        // ── AppBar ──────────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepBlack,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.screenTitle,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),

        // ── Cards ───────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.secondaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.webBlue, width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Input / Search ──────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.secondaryDark,
          hintStyle: AppTextStyles.searchHint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.webBlue, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.webBlue, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.electricBlue, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // ── Elevated button (Spider Red primary action) ─────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.spiderRed,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonPrimary,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),

        // ── Outlined button (Web Blue secondary) ────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.webBlue,
            side: const BorderSide(color: AppColors.webBlue, width: 1.2),
            textStyle: AppTextStyles.buttonSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // ── Divider ─────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.5,
          space: 0,
        ),

        // ── Icon ────────────────────────────────────────────────────────
        iconTheme: const IconThemeData(color: AppColors.white, size: 22),

        // ── Bottom navigation (unused in Phase 1 but scaffolded) ─────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.secondaryDark,
          selectedItemColor: AppColors.electricBlue,
          unselectedItemColor: AppColors.whiteMuted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

        // ── Snackbar ────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.secondaryDark,
          contentTextStyle: AppTextStyles.bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
