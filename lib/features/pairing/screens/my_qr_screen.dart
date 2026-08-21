import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/pairing_service.dart';
import '../../../providers/buddy_providers.dart';

/// Profile & QR Screen — Issue A.
/// Shows Name + auto-generated Unique ID + that user's QR code.
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryDark,
        title: Text('MY PROFILE & QR', style: AppTextStyles.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.staleRed))),
        data: (user) {
          if (user == null) {
            return Center(child: Text('User profile not found', style: AppTextStyles.bodyMedium));
          }

          final pairingService = PairingService();
          final qrPayload = pairingService.generateQRPayload(
            myBuddyId: user.id,
            publicKey: user.publicKey,
            pairingToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Profile Header ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.deepBlack,
                          border: Border.all(color: AppColors.electricBlue),
                        ),
                        child: const Center(
                          child: Text('🕷', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'ID: ${user.id}',
                                  style: AppTextStyles.radarLabel.copyWith(
                                    color: AppColors.electricBlue,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: user.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied ID "${user.id}" to clipboard!')),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: AppColors.whiteMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Have your buddy scan this QR code',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteMuted),
                ),
                const SizedBox(height: 16),

                // ── QR Code ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricBlue.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    size: 220.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Action Buttons ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pushReplacement('/scan_qr'),
                    icon: const Icon(Icons.qr_code_scanner, color: AppColors.electricBlue),
                    label: Text('SCAN A BUDDY INSTEAD', style: AppTextStyles.buttonSecondary),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.electricBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
