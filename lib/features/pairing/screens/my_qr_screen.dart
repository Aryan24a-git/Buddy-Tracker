import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/pairing_service.dart';

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate dummy payload for now since identity generation is in pairing_service
    // but not yet connected to Riverpod/Database state.
    final pairingService = PairingService();
    final qrPayload = pairingService.generateQRPayload(
      myBuddyId: 'user_123',
      publicKey: 'pub_key_xyz',
      pairingToken: 'token_789',
    );

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
      body: Center(
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
      ),
    );
  }
}
