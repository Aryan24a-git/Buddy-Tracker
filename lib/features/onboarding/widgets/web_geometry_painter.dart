import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/theme/theme.dart';

/// Paints a subtle spider-web geometry pattern on a canvas.
/// Used on the splash screen, radar background, and empty states.
class WebGeometryPainter extends CustomPainter {
  const WebGeometryPainter({
    this.strokeColor = AppColors.webLineStroke,
    this.rings = 6,
    this.spokes = 8,
  });

  final Color strokeColor;

  /// Number of concentric rings.
  final int rings;

  /// Number of radial spokes.
  final int spokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.sqrt(cx * cx + cy * cy);

    // ── Concentric rings ─────────────────────────────────────────────
    for (int i = 1; i <= rings; i++) {
      canvas.drawCircle(
        Offset(cx, cy),
        maxR * i / rings,
        paint,
      );
    }

    // ── Radial spokes ────────────────────────────────────────────────
    for (int s = 0; s < spokes; s++) {
      final angle = (2 * math.pi / spokes) * s - math.pi / 2;
      final dx = maxR * math.cos(angle);
      final dy = maxR * math.sin(angle);
      canvas.drawLine(Offset(cx, cy), Offset(cx + dx, cy + dy), paint);
    }

    // ── Cross-spoke web threads (between adjacent spokes, per ring) ──
    for (int i = 1; i <= rings; i++) {
      final r = maxR * i / rings;
      for (int s = 0; s < spokes; s++) {
        final a1 = (2 * math.pi / spokes) * s - math.pi / 2;
        final a2 = (2 * math.pi / spokes) * (s + 1) - math.pi / 2;
        canvas.drawLine(
          Offset(cx + r * math.cos(a1), cy + r * math.sin(a1)),
          Offset(cx + r * math.cos(a2), cy + r * math.sin(a2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WebGeometryPainter old) =>
      old.strokeColor != strokeColor ||
      old.rings != rings ||
      old.spokes != spokes;
}
