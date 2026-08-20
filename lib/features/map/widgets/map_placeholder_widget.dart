import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/core/utils/freshness.dart';
import 'package:buddy_tracker/models/buddy.dart';

/// Campus map preview widget styled with tactical dark theme aesthetics.
class MapPlaceholderWidget extends StatelessWidget {
  const MapPlaceholderWidget({
    super.key,
    this.lastSyncTime,
    this.buddies = const [],
  });

  final DateTime? lastSyncTime;
  final List<BuddyModel> buddies;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1420), // slightly lighter than deep black
        border: Border.all(color: AppColors.webBlue.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // ── Subtle grid lines simulating a map ───────────────────────
          CustomPaint(
            painter: _MapGridPainter(),
            size: Size.infinite,
          ),

          // ── Real marker: YOU ─────────────────────────────────────────
          const Center(
            child: _BuddyMarker(
              label: 'YOU',
              color: AppColors.electricBlue,
              isYou: true,
            ),
          ),

          // ── Dynamic markers for connected buddies ────────────────────
          for (int i = 0; i < buddies.length && i < 4; i++)
            _buildBuddyPosition(context, buddies[i], i),

          // ── CAMPUS MAP label ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryDark.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 12, color: AppColors.electricBlue),
                  const SizedBox(width: 4),
                  Text(
                    'CAMPUS MAP',
                    style: AppTextStyles.radarLabel.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // ── Last sync badge ───────────────────────────────────────────
          if (lastSyncTime != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Last Sync ${formatTime(lastSyncTime!)}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ),
            ),

          // ── Map engine notice ───────────────────────────────
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.spiderRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.spiderRed.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Text(
                'OSM CACHED TILES',
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 9, color: AppColors.spiderRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddyPosition(BuildContext context, BuddyModel buddy, int index) {
    // Relative layout offsets for up to 4 buddies around the center
    final offsets = [
      const Alignment(0.6, -0.5),
      const Alignment(-0.6, 0.5),
      const Alignment(-0.5, -0.6),
      const Alignment(0.5, 0.6),
    ];

    final align = offsets[index % offsets.length];

    String? distanceText;
    if (buddy.lastLocation != null) {
      distanceText = '${buddy.lastLocation!.accuracy?.round() ?? 0}m acc';
    }

    return Align(
      alignment: align,
      child: _BuddyMarker(
        label: buddy.displayName,
        color: AppColors.webBlue,
        distanceLabel: distanceText,
      ),
    );
  }
}

// ── Private helpers ─────────────────────────────────────────────────────────

class _BuddyMarker extends StatelessWidget {
  const _BuddyMarker({
    required this.label,
    required this.color,
    this.distanceLabel,
    this.isYou = false,
  });

  final String label;
  final Color color;
  final String? distanceLabel;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Marker dot
        Container(
          width: isYou ? 14 : 10,
          height: isYou ? 14 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: isYou ? 12 : 8,
                spreadRadius: isYou ? 2 : 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          distanceLabel != null ? '$label  $distanceLabel' : label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            color: isYou ? AppColors.electricBlue : AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.webLineStroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter _) => false;
}
