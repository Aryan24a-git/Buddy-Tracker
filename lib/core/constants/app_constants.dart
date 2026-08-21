/// Core application constants for Buddy Tracker.
/// All configurable values live here — never hardcode these inline.
library;

class AppConstants {
  AppConstants._();

  // ── Version & GitHub Updates ─────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static const String githubRepo = 'Aryan24a-git/Buddy-Tracker';
  static const String githubLatestReleaseApi =
      'https://api.github.com/repos/Aryan24a-git/Buddy-Tracker/releases/latest';

  // ── Spider-Sense radar ───────────────────────────────────────────────────
  /// Inner ring — "you're very close" zone (meters).
  static const double radarRing1Meters = 100.0;

  /// Middle ring (meters).
  static const double radarRing2Meters = 250.0;

  /// Outer ring — Spider-Sense boundary (meters).
  static const double spiderSenseRadiusMeters = 500.0;

  // ── Active-tracking interval ─────────────────────────────────────────────
  /// Default interval between location update requests during active tracking.
  /// Never set this below 5 s in production; 15 s is the design target.
  static const Duration trackingInterval = Duration(seconds: 15);

  // ── Location freshness thresholds ────────────────────────────────────────
  /// A location is "fresh" when its age is less than this.
  static const Duration freshnessThresholdFresh = Duration(seconds: 30);

  /// A location is "aging" when its age is between fresh and this.
  static const Duration freshnessThresholdAging = Duration(minutes: 5);

  // Older than aging threshold → STALE.

  // ── Earth radius (Haversine) ─────────────────────────────────────────────
  static const double earthRadiusMeters = 6371000.0;

  // ── QR / Pairing ─────────────────────────────────────────────────────────
  static const int pairingQrVersion = 1;
}
