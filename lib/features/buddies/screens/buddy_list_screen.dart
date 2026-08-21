import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/features/buddies/widgets/buddy_card.dart';
import 'package:buddy_tracker/providers/buddy_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';
import 'package:buddy_tracker/providers/service_providers.dart';

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

            // ── Buddy List ───────────────────────────────────────────────────
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
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final buddy = filtered[index];
                        return BuddyCard(
                          buddy: buddy,
                          isSelected: buddy.id == activeTargetId,
                          onTrack: () {
                            // Tapping buddy → map/radar centered on their location
                            context.go('/tracking/${buddy.id}');
                          },
                          onEditNickname: () async {
                            final controller = TextEditingController(text: buddy.nickname);
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.secondaryDark,
                                title: Text('Set Nickname', style: TextStyle(color: AppColors.white)),
                                content: TextField(
                                  controller: controller,
                                  style: const TextStyle(color: AppColors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter nickname...',
                                    hintStyle: TextStyle(color: AppColors.whiteMuted),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.whiteMuted),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.electricBlue),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CANCEL', style: TextStyle(color: AppColors.whiteMuted)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, ''),
                                    child: const Text('CLEAR', style: TextStyle(color: AppColors.staleRed)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
                                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                                    child: const Text('SAVE', style: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (result != null) {
                              final newNickname = result.isEmpty ? null : result;
                              final db = ref.read(databaseProvider);
                              await db.buddiesDao.updateNickname(buddy.id, newNickname);
                            }
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
