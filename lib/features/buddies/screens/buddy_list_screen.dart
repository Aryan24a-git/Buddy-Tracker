import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/features/buddies/widgets/buddy_card.dart';
import 'package:buddy_tracker/providers/buddy_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';

/// Full Buddy List & Search screen.
class BuddyListScreen extends ConsumerStatefulWidget {
  const BuddyListScreen({super.key});

  @override
  ConsumerState<BuddyListScreen> createState() => _BuddyListScreenState();
}

class _BuddyListScreenState extends ConsumerState<BuddyListScreen> {
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

    final filtered = _searchQuery.isEmpty
        ? buddies
        : buddies
            .where((b) =>
                b.label.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text('MY BUDDIES', style: AppTextStyles.screenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.spiderRed),
            tooltip: 'Add Buddy',
            onPressed: () => context.push('/my_qr'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: '🔍  Search by name or nickname...',
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
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No buddies added yet.' : 'No matches found.',
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final buddy = filtered[index];
                        return BuddyCard(
                          buddy: buddy,
                          isSelected: buddy.id == activeTargetId,
                          onTrack: () {
                            ref.read(activeTrackingTargetProvider.notifier).state = buddy.id;
                            context.go('/tracking/${buddy.id}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
