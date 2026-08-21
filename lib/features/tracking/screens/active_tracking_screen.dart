import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/features/map/widgets/map_placeholder_widget.dart';
import 'package:buddy_tracker/features/tracking/widgets/target_status_card.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/providers/buddy_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';
import 'package:buddy_tracker/routing/app_router.dart';

/// Active Tracking Screen — design.md §6 Active Tracking Screen.
///
/// Shows:
/// - Top bar: ← BUDDY NAME   ● TRACKING
/// - Map (placeholder, Phase 1)
/// - Target status card (distance, speed, accuracy, last signal, transport)
/// - STOP TRACKING button
/// - Privacy indicator if user is also being tracked
class ActiveTrackingScreen extends ConsumerStatefulWidget {
  const ActiveTrackingScreen({super.key, required this.buddyId});

  final String buddyId;

  @override
  ConsumerState<ActiveTrackingScreen> createState() =>
      _ActiveTrackingScreenState();
}

class _ActiveTrackingScreenState extends ConsumerState<ActiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Tracking pulse animation — subtle, ~1.5 s cycle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Mark as actively viewing this buddy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeTrackingTargetProvider.notifier).state = widget.buddyId;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _stopTracking(BuildContext context) {
    ref.read(activeTrackingTargetProvider.notifier).state = null;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final buddies = ref.watch(buddyListProvider);
    final buddy = buddies.where((b) => b.id == widget.buddyId).firstOrNull;
    final beingTracked = ref.watch(beingTrackedProvider);

    // Phase 8: If tracking state is cleared (e.g. from backgrounding), pop out
    ref.listen(activeTrackingTargetProvider, (previous, next) {
      if (next == null && mounted) {
        context.go(AppRoutes.dashboard);
      }
    });

    if (buddy == null) {
      return _BuddyNotFound(onBack: () => context.go(AppRoutes.dashboard));
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────
            _TrackingAppBar(
              buddy: buddy,
              pulseController: _pulseController,
              onBack: () => _stopTracking(context),
            ),

            // ── Map ───────────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MapPlaceholderWidget(lastSyncTime: DateTime.now()),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Privacy indicator (if being tracked) ──────────────────
            if (beingTracked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _PrivacyIndicator(
                  onStopSharing: () {
                    ref.read(beingTrackedProvider.notifier).state = false;
                  },
                ),
              ),

            // ── Target status card ────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TargetStatusCard(
                  buddy: buddy,
                  pulseController: _pulseController,
                ),
              ),
            ),

            // ── STOP TRACKING button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _stopTracking(context),
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('■  STOP TRACKING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.spiderRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TrackingAppBar extends StatelessWidget {
  const _TrackingAppBar({
    required this.buddy,
    required this.pulseController,
    required this.onBack,
  });

  final BuddyModel buddy;
  final AnimationController pulseController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: onBack,
            tooltip: 'Stop tracking and go back',
          ),
          Expanded(
            child: Text(
              buddy.label.toUpperCase(),
              style: AppTextStyles.screenTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ● TRACKING badge with pulse
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, _) {
              final opacity = 0.6 + 0.4 * pulseController.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.spiderRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.spiderRed.withValues(alpha: opacity),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.spiderRed.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'TRACKING',
                      style: AppTextStyles.statusBadge.copyWith(
                        color: AppColors.spiderRed,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Privacy indicator — design.md §9.
/// Un-hideable; always visible when the user is being tracked.
class _PrivacyIndicator extends StatelessWidget {
  const _PrivacyIndicator({required this.onStopSharing});

  final VoidCallback onStopSharing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.spiderRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.spiderRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.spiderRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ACTIVE — sharing location',
              style: AppTextStyles.statusBadge.copyWith(
                color: AppColors.spiderRed,
                fontSize: 11,
              ),
            ),
          ),
          TextButton(
            onPressed: onStopSharing,
            child: Text(
              'STOP',
              style: AppTextStyles.buttonSecondary.copyWith(
                color: AppColors.spiderRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyNotFound extends StatelessWidget {
  const _BuddyNotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Target not found', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('BACK TO DASHBOARD'),
            ),
          ],
        ),
      ),
    );
  }
}
