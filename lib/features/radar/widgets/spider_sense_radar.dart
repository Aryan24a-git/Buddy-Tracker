import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';
import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/core/utils/distance.dart';
import 'package:buddy_tracker/models/buddy.dart';

/// Spider-Sense radar component — design.md §4 and §6.
///
/// Renders:
/// - Three concentric rings at 100 m / 250 m / 500 m
/// - Subtle web-spoke geometry background
/// - Buddy dot markers positioned by haversine bearing
/// - "YOU" center dot
/// - Ring distance labels (Rajdhani font)
///
/// Renders markers computed via spherical forward-azimuth bearing from GPS.
class SpiderSenseRadar extends StatelessWidget {
  const SpiderSenseRadar({
    super.key,
    required this.buddies,
    this.myLat = 12.9726,
    this.myLon = 77.5946,
    this.size = 280,
  });

  final List<BuddyModel> buddies;

  /// Current user position (mock in Phase 1).
  final double myLat;
  final double myLon;

  /// Diameter of the radar widget in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          buddies: buddies,
          myLat: myLat,
          myLon: myLon,
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.buddies,
    required this.myLat,
    required this.myLon,
  });

  final List<BuddyModel> buddies;
  final double myLat;
  final double myLon;

  static const double _maxRadiusMeters = AppConstants.spiderSenseRadiusMeters;
  static const _rings = [
    AppConstants.radarRing1Meters,
    AppConstants.radarRing2Meters,
    AppConstants.spiderSenseRadiusMeters,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxPx = size.width / 2 - 4;

    _drawSpokes(canvas, cx, cy, maxPx);
    _drawRings(canvas, cx, cy, maxPx);
    _drawRingLabels(canvas, cx, cy, maxPx, size);
    _drawBuddies(canvas, cx, cy, maxPx);
    _drawYouDot(canvas, cx, cy);
  }

  void _drawSpokes(Canvas canvas, double cx, double cy, double maxPx) {
    final paint = Paint()
      ..color = AppColors.webLineStroke
      ..strokeWidth = 0.6;

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxPx * math.cos(angle), cy + maxPx * math.sin(angle)),
        paint,
      );
    }
  }

  void _drawRings(Canvas canvas, double cx, double cy, double maxPx) {
    for (int i = 0; i < _rings.length; i++) {
      final frac = _rings[i] / _maxRadiusMeters;
      final r = maxPx * frac;
      final isOuter = i == _rings.length - 1;

      final paint = Paint()
        ..color = isOuter
            ? AppColors.spiderRed.withValues(alpha: 0.5)
            : AppColors.electricBlue.withValues(alpha: 0.25)
        ..strokeWidth = isOuter ? 1.2 : 0.7
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _drawRingLabels(
      Canvas canvas, double cx, double cy, double maxPx, Size size) {
    for (int i = 0; i < _rings.length; i++) {
      final frac = _rings[i] / _maxRadiusMeters;
      final r = maxPx * frac;
      final label = formatDistance(_rings[i]);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: AppTextStyles.radarLabel.copyWith(fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(cx + 4, cy - r - tp.height - 2),
      );
    }
  }

  void _drawBuddies(Canvas canvas, double cx, double cy, double maxPx) {
    for (int i = 0; i < buddies.length; i++) {
      final buddy = buddies[i];
      final loc = buddy.lastLocation;
      if (loc == null) continue;

      final distMeters = haversineDistance(
        lat1: myLat,
        lon1: myLon,
        lat2: loc.latitude,
        lon2: loc.longitude,
      );

      final clampedDist = distMeters.clamp(0, _maxRadiusMeters);
      final frac = clampedDist / _maxRadiusMeters;
      
      // Calculate true spherical bearing from my position to buddy position
      final phi1 = myLat * math.pi / 180.0;
      final phi2 = loc.latitude * math.pi / 180.0;
      final deltaLambda = (loc.longitude - myLon) * math.pi / 180.0;

      final y = math.sin(deltaLambda) * math.cos(phi2);
      final x = math.cos(phi1) * math.sin(phi2) -
          math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
      final bearingRadians = math.atan2(y, x);
      
      // Convert bearing (0° North) to screen coordinates (0° East, clockwise, so angle = bearing - pi/2)
      final screenAngle = bearingRadians - (math.pi / 2);

      final px = cx + maxPx * frac * math.cos(screenAngle);
      final py = cy + maxPx * frac * math.sin(screenAngle);

      // Dot
      canvas.drawCircle(
        Offset(px, py),
        5,
        Paint()..color = AppColors.webBlue,
      );
      // Glow
      canvas.drawCircle(
        Offset(px, py),
        9,
        Paint()
          ..color = AppColors.webBlue.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: buddy.label.split(' ').first,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(px + 8, py - tp.height / 2));
    }
  }

  void _drawYouDot(Canvas canvas, double cx, double cy) {
    // Outer glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..color = AppColors.electricBlue.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // White/electric dot
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()..color = AppColors.electricBlue,
    );
    // "YOU" label
    final tp = TextPainter(
      text: TextSpan(
        text: 'YOU',
        style: AppTextStyles.radarLabel.copyWith(
          fontSize: 9,
          color: AppColors.electricBlue,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 10));
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.buddies != buddies ||
      old.myLat != myLat ||
      old.myLon != myLon;
}
