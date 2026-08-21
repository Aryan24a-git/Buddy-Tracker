import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/pairing_service.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:buddy_tracker/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/buddy_providers.dart';

class AddBuddyScreen extends ConsumerStatefulWidget {
  final String qrData;

  const AddBuddyScreen({super.key, required this.qrData});

  @override
  ConsumerState<AddBuddyScreen> createState() => _AddBuddyScreenState();
}

class _AddBuddyScreenState extends ConsumerState<AddBuddyScreen> {
  final _nicknameController = TextEditingController();
  final _pairingService = PairingService();
  Map<String, dynamic>? _parsedData;

  @override
  void initState() {
    super.initState();
    _parsedData = _pairingService.parseScannedQR(widget.qrData);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveBuddy() async {
    if (_parsedData == null) return;
    
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
      return;
    }

    final newBuddy = _pairingService.establishBuddy(
      parsedQrData: _parsedData!,
      nickname: nickname,
    );

    // Save into Drift AppDatabase
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.buddies).insertOnConflictUpdate(
        BuddiesCompanion.insert(
          id: newBuddy.id,
          nickname: Value(nickname),
          publicKey: _parsedData!['pk'] as String? ?? '', // FIXED from 'publicKey'
        ),
      );

      // Create instant mutual link in Supabase
      final myUser = await ref.read(currentUserProvider.future);
      if (myUser != null) {
        final supabase = ref.read(supabaseServiceProvider);
        
        // Ensure both users exist in Supabase users table (satisfies foreign key)
        await supabase.upsertUser(
          id: myUser.id,
          displayName: myUser.displayName,
          publicKey: myUser.publicKey,
        );
        await supabase.upsertUser(
          id: newBuddy.id,
          displayName: nickname,
          publicKey: _parsedData!['pk'] as String? ?? 'pub_key',
        );

        await supabase.addBuddyRelationship(
          userId: myUser.id,
          buddyId: newBuddy.id,
          status: 'accepted',
        );
        await supabase.addBuddyRelationship(
          userId: newBuddy.id,
          buddyId: myUser.id,
          status: 'accepted',
        );
      }
    } catch (e) {
      debugPrint('Database insert error: $e');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buddy "$nickname" added!')),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_parsedData == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.secondaryDark,
          title: Text('INVALID QR', style: AppTextStyles.screenTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.spiderRed, size: 64),
              const SizedBox(height: 16),
              Text('Unrecognized QR code format.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryDark),
                onPressed: () => context.pop(),
                child: Text('GO BACK', style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.white)),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryDark,
        title: Text('ADD BUDDY', style: AppTextStyles.screenTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Identity verified.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.electricBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Buddy ID: ${_parsedData!['id']}',
              style: AppTextStyles.radarLabel,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nicknameController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Nickname',
                labelStyle: AppTextStyles.radarLabel,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.electricBlue),
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveBuddy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.spiderRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('SAVE BUDDY', style: AppTextStyles.buttonPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
