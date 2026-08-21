import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:buddy_tracker/providers/buddy_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';

/// Settings & Privacy Control Screen — Issue D.
/// Provides global "Stop Sharing My Location" toggle, permissions manager, and profile details.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  LocationPermission? _permissionStatus;
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _permissionStatus = status;
        _isLoadingPermission = false;
      });
    }
  }

  Future<void> _requestBackgroundPermission() async {
    final locationService = ref.read(locationServiceProvider);
    final granted = await locationService.requestBackgroundPermission();
    await _checkPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? '✓ Background location access enabled'
              : 'Background location permission not granted'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isSharing = ref.watch(isSharingLocationProvider);
    final trackingService = ref.watch(trackingServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryDark,
        title: Text('SETTINGS & PRIVACY', style: AppTextStyles.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.staleRed))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── 1. Profile Section ──
              _SectionHeader(title: 'IDENTITY'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('🕷', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName, style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text('Unique ID: ${user.id}', style: AppTextStyles.radarLabel.copyWith(color: AppColors.electricBlue)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: AppColors.electricBlue),
                          tooltip: 'View QR Code',
                          onPressed: () => context.push('/my_qr'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 2. Location Sharing (Global Toggle) ──
              _SectionHeader(title: 'LOCATION SHARING'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSharing ? AppColors.electricBlue : AppColors.divider,
                    width: isSharing ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share My Location',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSharing ? '● Broadcasting every ~15s' : '○ Location sharing paused',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSharing ? AppColors.freshGreen : AppColors.whiteMuted,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isSharing,
                          activeThumbColor: AppColors.electricBlue,
                          activeTrackColor: AppColors.electricBlue.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.whiteMuted,
                          inactiveTrackColor: AppColors.deepBlack,
                          onChanged: (val) async {
                            if (val) {
                              // Start sharing
                              await trackingService.startSharing(user.id);
                              ref.read(isSharingLocationProvider.notifier).state = true;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✓ Continuous location sharing started')),
                                );
                              }
                            } else {
                              // Stop sharing immediately
                              trackingService.stopSharing();
                              ref.read(isSharingLocationProvider.notifier).state = false;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Stopped sharing location')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.divider, height: 24),
                    Text(
                      'When active, your location is continuously synced to Supabase for your mutual buddies. Last-known location is cached locally when disconnected.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.whiteMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 3. Background Permissions ──
              _SectionHeader(title: 'BACKGROUND TRACKING PERMISSIONS'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _permissionStatus == LocationPermission.always
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _permissionStatus == LocationPermission.always
                              ? AppColors.freshGreen
                              : AppColors.agingYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isLoadingPermission
                                ? 'Checking permission...'
                                : _permissionStatus == LocationPermission.always
                                    ? 'Background location: Granted (Always)'
                                    : 'Background location: While In Use Only',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_permissionStatus != LocationPermission.always) ...[
                      Text(
                        'To keep sharing your location when the app is minimized, allow "All the time" location access in Android settings.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.whiteMuted),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _requestBackgroundPermission,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.electricBlue),
                        ),
                        child: Text('ENABLE BACKGROUND LOCATION', style: AppTextStyles.buttonSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. App Info ──
              _SectionHeader(title: 'ABOUT'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Version', style: AppTextStyles.bodyMedium),
                        Text(AppConstants.appVersion, style: AppTextStyles.radarLabel.copyWith(color: AppColors.electricBlue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transport', style: AppTextStyles.bodyMedium),
                        Text('Supabase Realtime + Cache', style: AppTextStyles.bodySmall.copyWith(color: AppColors.whiteMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Radar Range', style: AppTextStyles.bodyMedium),
                        Text('500 meters', style: AppTextStyles.bodySmall.copyWith(color: AppColors.whiteMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.radarLabel.copyWith(
          color: AppColors.whiteMuted,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
