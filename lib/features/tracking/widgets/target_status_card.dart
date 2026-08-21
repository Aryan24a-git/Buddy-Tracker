import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/core/utils/distance.dart';
import 'package:buddy_tracker/core/utils/freshness.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/models/location.dart';

/// TARGET STATUS card shown on the Active Tracking screen — design.md §6.
///
/// Displays: Distance · Speed · Accuracy · Last Signal · Transport
class TargetStatusCard extends StatelessWidget {
  const TargetStatusCard({
    super.key,
    required this.buddy,
    required this.pulseController,
  });

  final BuddyModel buddy;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final loc = buddy.lastLocation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.webBlue.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text('🕷', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('TARGET STATUS', style: AppTextStyles.sectionHeader),
                const Spacer(),
                if (loc != null) _FreshnessChip(loc.age),
              ],
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Stats grid ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: loc == null
                  ? _NoSignalState()
                  : _StatsGrid(
                      loc: loc,
                      pulseController: pulseController,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.loc, required this.pulseController});

  final LocationModel loc;
  final AnimationController pulseController;

  static const double _myLat = 12.9726;
  static const double _myLon = 77.5946;

  @override
  Widget build(BuildContext context) {
    final distMeters = haversineDistance(
      lat1: _myLat,
      lon1: _myLon,
      lat2: loc.latitude,
      lon2: loc.longitude,
    );

    return Column(
      children: [
        Row(
          children: [
            _StatCell(label: 'Distance', value: formatDistance(distMeters)),
            _StatCell(
              label: 'Speed',
              value: loc.speedKmh != null
                  ? '${loc.speedKmh!.toStringAsFixed(1)} km/h'
                  : '—',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCell(
              label: 'Accuracy',
              value: loc.accuracy != null ? '±${loc.accuracy!.round()} m' : '—',
            ),
            _StatCell(
              label: 'Last Signal',
              value: formatAge(loc.timestamp),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCell(
              label: 'Transport',
              value: _transportLabel(loc.transport),
              valueColor: _transportColor(loc.transport),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  String _transportLabel(LocationTransport t) => switch (t) {
        LocationTransport.internet => 'Internet',
        LocationTransport.cache => 'Cache',
      };

  Color _transportColor(LocationTransport t) => switch (t) {
        LocationTransport.internet => AppColors.electricBlue,
        LocationTransport.cache => AppColors.staleRed,
      };
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.distanceValue.copyWith(
              fontSize: 18,
              color: valueColor ?? AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshnessChip extends StatelessWidget {
  const _FreshnessChip(this.age);

  final Duration age;

  @override
  Widget build(BuildContext context) {
    final state = freshnessOf(age);
    final (emoji, label, color) = switch (state) {
      FreshnessState.fresh => ('🟢', 'FRESH', AppColors.freshGreen),
      FreshnessState.aging => ('🟡', 'AGING', AppColors.agingYellow),
      FreshnessState.stale => ('🔴', 'STALE', AppColors.staleRed),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji $label',
        style: AppTextStyles.statusBadge.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _NoSignalState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_wifi_off, color: AppColors.whiteMuted, size: 40),
          const SizedBox(height: 12),
          Text('No Signal', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 6),
          Text(
            'Request sent — waiting for response.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
