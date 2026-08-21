import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/buddy_providers.dart';
import 'package:buddy_tracker/database/app_database.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isNavigating = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;
      if (qrData != null) {
        _isNavigating = true;
        // Navigate to add buddy screen, passing the scanned QR data
        context.pushReplacement('/add_buddy', extra: qrData);
      }
    }
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: Text('Enter Buddy ID', style: AppTextStyles.screenTitle),
        content: TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. ABCDEF',
            hintStyle: TextStyle(color: AppColors.whiteMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.whiteMuted)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.whiteMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
            onPressed: () {
              final id = controller.text.trim().toUpperCase();
              Navigator.pop(context, id);
            },
            child: const Text('ADD BUDDY', style: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((id) async {
      if (id != null && id.isNotEmpty) {
        final myUser = await ref.read(currentUserProvider.future);
        if (myUser != null) {
          try {
            final supabase = ref.read(supabaseServiceProvider);
            final db = ref.read(databaseProvider);

            // Ensure both users exist in Supabase users table (satisfies foreign key)
            await supabase.upsertUser(
              id: myUser.id,
              displayName: myUser.displayName,
              publicKey: myUser.publicKey,
            );
            await supabase.upsertUser(
              id: id,
              displayName: 'Buddy $id',
              publicKey: 'manual_key',
            );

            // Instant mutual link in Supabase (both directions)
            await supabase.addBuddyRelationship(
              userId: myUser.id,
              buddyId: id,
              status: 'accepted',
            );
            await supabase.addBuddyRelationship(
              userId: id,
              buddyId: myUser.id,
              status: 'accepted',
            );

            // Add to local Drift DB
            await db.buddiesDao.insertOrUpdateBuddy(
              Buddy(id: id, publicKey: 'manual_entry'),
            );

            // Send in-app notification to the other user
            try {
              await supabase.sendNotification(
                toUserId: id,
                fromUserId: myUser.id,
                message: '${myUser.displayName} added you as a buddy',
              );
            } catch (_) {
              // Non-blocking — notification is informational only
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Buddy $id added!')),
              );
              context.pop();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add buddy: $e')),
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('SCAN BUDDY', style: AppTextStyles.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Tactical overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spiderRed, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ALIGN QR CODE WITHIN FRAME',
                  style: AppTextStyles.radarLabel,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard, color: AppColors.electricBlue),
                  label: Text('ENTER ID MANUALLY', style: AppTextStyles.buttonSecondary),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.electricBlue),
                    backgroundColor: AppColors.deepBlack.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
