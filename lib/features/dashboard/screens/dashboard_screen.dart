import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/core/utils/freshness.dart';
import 'package:buddy_tracker/features/buddies/widgets/buddy_card.dart';
import 'package:buddy_tracker/features/map/widgets/map_placeholder_widget.dart';
import 'package:buddy_tracker/features/radar/widgets/spider_sense_radar.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/providers/buddy_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:buddy_tracker/services/update_service.dart';

/// Main dashboard screen — design.md §6 Dashboard layout.
///
/// Layout (top → bottom):
///  1. App bar — 🕷 BUDDY TRACKER | ⚙ | ⟳
///  2. Search bar
///  3. Campus map (placeholder in Phase 1)
///  4. SPIDER SENSE section header
///  5. Buddy card list
///  6. Radar mini-view
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buddies = ref.watch(buddyListProvider);
    final activeTargetId = ref.watch(activeTrackingTargetProvider);

    // Filter buddies by search query
    final filtered = _searchQuery.isEmpty
        ? buddies
        : buddies
            .where((b) =>
                b.label.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final updateAsync = ref.watch(appUpdateCheckProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            _DashboardAppBar(
              onAddBuddyTap: () {
                context.push('/my_qr');
              },
              onSettingsTap: () {
                context.push('/buddies');
              },
              onRefreshTap: () async {
                // Phase 6: Call RefreshManager
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⟳  Refreshing locations...'),
                  ),
                );
                
                // Get buddy IDs to refresh
                final buddyIds = buddies.map((b) => b.id).toList();
                
                await ref.read(refreshServiceProvider).refreshAll('my_id_placeholder', buddyIds);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓  Locations refreshed'),
                    ),
                  );
                }
              },
            ),

            // ── Update Notification Banner (if newer release exists) ───
            updateAsync.when(
              data: (update) => update != null
                  ? _UpdateBanner(
                      updateInfo: update,
                      onUpdateTap: () => ref
                          .read(updateServiceProvider)
                          .launchDownload(update.downloadUrl),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: '🔍  Search targets...',
                  hintStyle: AppTextStyles.searchHint,
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.whiteMuted, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.whiteMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // ── Content (scrollable) ────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Campus map
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: MapPlaceholderWidget(
                            buddies: buddies,
                            lastSyncTime: DateTime.now()
                                .subtract(const Duration(minutes: 3)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // SPIDER SENSE header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('🕷', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'SPIDER SENSE',
                            style: AppTextStyles.sectionHeader,
                          ),
                          const Spacer(),
                          Text(
                            'Last Sync ${formatTime(DateTime.now().subtract(const Duration(minutes: 3)))}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Buddy cards
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyState(hasSearch: _searchQuery.isNotEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final buddy = filtered[i];
                          return BuddyCard(
                            buddy: buddy,
                            isSelected: buddy.id == activeTargetId,
                            onTrack: () => _onTrackTapped(buddy),
                          );
                        },
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Radar mini-view
                  SliverToBoxAdapter(
                    child: _RadarSection(buddies: buddies),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTrackTapped(BuddyModel buddy) {
    ref.read(activeTrackingTargetProvider.notifier).state = buddy.id;
    context.go('/tracking/${buddy.id}');
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({
    required this.onSettingsTap,
    required this.onRefreshTap,
    required this.onAddBuddyTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onRefreshTap;
  final VoidCallback onAddBuddyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('🕷', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'BUDDY TRACKER',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.person_add, color: AppColors.spiderRed, size: 20),
            tooltip: 'Add Buddy',
            onPressed: onAddBuddyTap,
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.refresh, color: AppColors.electricBlue, size: 20),
            tooltip: 'Refresh all',
            onPressed: onRefreshTap,
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.settings_outlined, color: AppColors.whiteMuted, size: 20),
            tooltip: 'Settings',
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _RadarSection extends StatelessWidget {
  const _RadarSection({required this.buddies});

  final List<BuddyModel> buddies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('🕷', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('RADAR VIEW', style: AppTextStyles.sectionHeader),
              const SizedBox(width: 8),
              Text(
                '500 m radius',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.spiderRed.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Center(
            child: SpiderSenseRadar(buddies: buddies, size: 260),
          ),
        ),
      ],
    );
  }
}

/// Empty state for the buddy list — design.md §7.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          // Subtle web illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.webBlue.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Center(
              child: Text('🕷', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No targets found' : 'Add your first buddy',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term.'
                : 'Pair with a buddy using QR code to start tracking.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                context.push('/scan_qr');
              },
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text('SCAN QR CODE'),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.updateInfo,
    required this.onUpdateTap,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback onUpdateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.spiderRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.spiderRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_rounded,
              color: AppColors.spiderRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ Update Available (v${updateInfo.latestVersion})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A newer build is ready on GitHub.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.whiteMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spiderRed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onUpdateTap,
            child: Text(
              'UPDATE',
              style: AppTextStyles.buttonPrimary.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
