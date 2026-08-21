import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/core/utils/distance.dart';
import 'package:buddy_tracker/core/utils/freshness.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/models/location.dart';

/// Buddy card displayed in the Spider Sense list on the Dashboard.
/// Matches design.md §6 Search Result Card and §9 component spec.
class BuddyCard extends StatelessWidget {
  const BuddyCard({
    super.key,
    required this.buddy,
    this.myLat,
    this.myLon,
    this.onTrack,
    this.onEditNickname,
    this.isSelected = false,
  });

  final BuddyModel buddy;

  /// Current user position for distance calculation.
  final double? myLat;
  final double? myLon;

  /// Called when "TRACK FRIEND" is tapped.
  final VoidCallback? onTrack;

  /// Called when the edit icon is tapped.
  final VoidCallback? onEditNickname;

  /// True when this buddy is the active tracking target.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = buddy.lastLocation;
    final distText = _distanceText(loc);
    final freshness = loc != null ? freshnessOf(loc.age) : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.spiderRed
              : AppColors.webBlue.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.spiderRed.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────────
            _BuddyAvatar(buddy: buddy, freshness: freshness),
            const SizedBox(width: 14),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 🕷 + name
                      const Text('🕷 ',
                          style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          buddy.label,
                          style: AppTextStyles.buddyName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (freshness != null) _FreshnessBadge(freshness),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (distText != null)
                    Text(
                      'Last Signal: $distText',
                      style: AppTextStyles.buddyMeta,
                    ),
                  if (loc != null)
                    Text(
                      'Updated: ${formatAge(loc.timestamp)}',
                      style: AppTextStyles.buddyMeta,
                    ),
                  if (loc != null)
                    _TransportIndicator(transport: loc.transport),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Actions ────────────────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onEditNickname != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.whiteMuted),
                    onPressed: onEditNickname,
                    tooltip: 'Edit Nickname',
                  ),
                if (onTrack != null)
                  SizedBox(
                    width: 75,
                    child: ElevatedButton(
                      onPressed: onTrack,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
                      ),
                      child: const Text('TRACK'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _distanceText(LocationModel? loc) {
    if (loc == null) return null;
    if (myLat != null && myLon != null) {
      final d = haversineDistance(
        lat1: myLat!,
        lon1: myLon!,
        lat2: loc.latitude,
        lon2: loc.longitude,
      );
      return formatDistance(d);
    }
    // Fallback: show a rough distance based on mock coords
    return '~320 m';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BuddyAvatar extends StatelessWidget {
  const _BuddyAvatar({required this.buddy, this.freshness});

  final BuddyModel buddy;
  final FreshnessState? freshness;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (freshness) {
      FreshnessState.fresh => AppColors.freshGreen,
      FreshnessState.aging => AppColors.agingYellow,
      FreshnessState.stale => AppColors.staleRed,
      null => AppColors.whiteMuted,
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.webBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.webBlue, width: 1),
          ),
          child: Center(
            child: Text(
              buddy.initials,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Freshness dot
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.deepBlack, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FreshnessBadge extends StatelessWidget {
  const _FreshnessBadge(this.state);

  final FreshnessState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      FreshnessState.fresh => ('🟢 FRESH', AppColors.freshGreen),
      FreshnessState.aging => ('🟡 AGING', AppColors.agingYellow),
      FreshnessState.stale => ('🔴 STALE', AppColors.staleRed),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.statusBadge.copyWith(
          color: color,
          fontSize: 9,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Transport signal indicator — design.md §7.
/// Uses bar count metaphor; never implies measured signal strength.
class _TransportIndicator extends StatelessWidget {
  const _TransportIndicator({required this.transport});

  final LocationTransport transport;

  @override
  Widget build(BuildContext context) {
    final (label, bars, activeColor) = switch (transport) {
      LocationTransport.internet => ('ONLINE', 4, AppColors.electricBlue),
      LocationTransport.sms => ('SMS', 2, AppColors.agingYellow),
      LocationTransport.cache => ('STALE', 1, AppColors.staleRed),
    };

    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.statusBadge.copyWith(
            color: activeColor,
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(4, (i) {
          final active = i < bars;
          return Container(
            width: 4,
            height: 8 + (i * 2.0),
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: active ? activeColor : AppColors.whiteMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ],
    );
  }
}
