import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/routing/app_router.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:buddy_tracker/database/app_database.dart';

/// Onboarding screen for first-launch identity creation.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String _generateShortCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 1, 0
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a display name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shortCode = _generateShortCode();
      final publicKey = 'pub_${shortCode}_${DateTime.now().millisecondsSinceEpoch}';

      // Save locally first (local-first per architecture.md)
      final db = ref.read(databaseProvider);
      await db.usersDao.insertOrUpdateUser(
        User(
          id: shortCode,
          displayName: name,
          publicKey: publicKey,
        ),
      );
      debugPrint('OnboardingScreen: Local user created: id=$shortCode, name=$name');

      // Upsert to Supabase cloud
      try {
        final supabaseService = ref.read(supabaseServiceProvider);
        await supabaseService.upsertUser(
          id: shortCode,
          displayName: name,
          publicKey: publicKey,
        );
        debugPrint('OnboardingScreen: Cloud user synced successfully');
      } catch (cloudErr) {
        // Log but don't block — local-first means we continue even if cloud fails
        debugPrint('OnboardingScreen: Cloud sync failed (non-blocking): $cloudErr');
      }

      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      debugPrint('OnboardingScreen: FATAL error creating profile: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to create profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🕷', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Welcome to', style: AppTextStyles.bodyMedium),
              Text('Buddy Tracker', style: AppTextStyles.splashLogo.copyWith(fontSize: 32)),
              const SizedBox(height: 32),
              Text(
                'What should your buddies call you?',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.white, fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'Display Name',
                  hintStyle: const TextStyle(color: AppColors.whiteMuted),
                  errorText: _error,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.whiteMuted),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.electricBlue),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepBlack),
                          ),
                        )
                      : Text(
                          'CONTINUE',
                          style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.deepBlack),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
