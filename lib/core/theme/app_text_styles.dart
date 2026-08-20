import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale for Buddy Tracker.
///
/// Primary UI font  : Space Grotesk  (readable names, distances, timestamps).
/// Accent / HUD font: Rajdhani        (radar labels, splash — never body text).
///
/// Uses google_fonts for runtime font serving in Phase 1.
/// Bundled font assets will be added in Phase 1b for offline/production builds.
abstract class AppTextStyles {
  // ── Display / Hero ─────────────────────────────────────────────────────
  static TextStyle get splashLogo => GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 6,
      );

  static TextStyle get radarLabel => GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.electricBlue,
        letterSpacing: 2,
      );

  // ── Headings ───────────────────────────────────────────────────────────
  static TextStyle get screenTitle => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get sectionHeader => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.whiteMuted,
        letterSpacing: 2,
      );

  // ── Body ───────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );

  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      );

  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.whiteMuted,
      );

  // ── Distance / metric display ──────────────────────────────────────────
  static TextStyle get distanceValue => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      );

  static TextStyle get distanceUnit => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.whiteMuted,
      );

  // ── Status / badge ─────────────────────────────────────────────────────
  static TextStyle get statusBadge => GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      );

  // ── Button labels ──────────────────────────────────────────────────────
  static TextStyle get buttonPrimary => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 1.5,
      );

  static TextStyle get buttonSecondary => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.webBlue,
        letterSpacing: 1.2,
      );

  // ── Card / list ────────────────────────────────────────────────────────
  static TextStyle get buddyName => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get buddyMeta => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.whiteMuted,
      );

  // ── Search / input ─────────────────────────────────────────────────────
  static TextStyle get searchHint => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.whiteMuted,
      );
}
