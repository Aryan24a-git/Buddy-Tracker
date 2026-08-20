import 'package:flutter/material.dart';

/// Buddy Tracker color palette — deep black tactical theme.
/// All hex values are from design.md §2.
abstract class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────
  static const Color deepBlack = Color(0xFF05070D);
  static const Color secondaryDark = Color(0xFF101722);

  // ── Accents ────────────────────────────────────────────────────────────
  /// Spider Red — primary accent, alerts, TRACKING ACTIVE, stop actions.
  static const Color spiderRed = Color(0xFFE21B2D);

  /// Web Blue — secondary accent, buddy markers, links.
  static const Color webBlue = Color(0xFF1479D1);

  /// Electric Blue — highlights, active states, pulse rings.
  static const Color electricBlue = Color(0xFF3FA9F5);

  // ── Text ───────────────────────────────────────────────────────────────
  /// Primary text on dark surfaces.
  static const Color white = Color(0xFFF5F7FA);

  /// Subdued text / secondary labels.
  static const Color whiteMuted = Color(0xFFB0B8CC);

  // ── Freshness indicator colors ─────────────────────────────────────────
  static const Color freshGreen = Color(0xFF2DD36F);
  static const Color agingYellow = Color(0xFFFFC409);
  static const Color staleRed = spiderRed;

  // ── Utility ────────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color divider = Color(0x33FFFFFF); // white 20 %

  // ── Web-line geometry tint ─────────────────────────────────────────────
  static const Color webLineStroke = Color(0x1A3FA9F5); // electricBlue @ 10 %
}
