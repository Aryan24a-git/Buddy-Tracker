import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/pairing_service.dart';
import '../../../providers/buddy_providers.dart';

class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryDark,
        title: Text('MY QR', style: AppTextStyles.screenTitle),
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
            pairingToken: 'token_${DateTime.now().millisecondsSinceEpoch}', // Dummy ephemeral token
          );

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(
              'Have your buddy scan this',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteMuted),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 240.0,
                // Using standard black for QR code for scanning reliability
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
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.pushReplacement('/scan_qr'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.electricBlue),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('SCAN A BUDDY INSTEAD', style: AppTextStyles.buttonSecondary),
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
