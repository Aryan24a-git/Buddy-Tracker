import 'package:flutter/material.dart';
import 'package:buddy_tracker/core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:geolocator/geolocator.dart';

/// Checks and requests location permission, showing a rationale dialog if needed.
/// Returns true if permission is granted.
Future<bool> requestLocationPermission(BuildContext context, WidgetRef ref) async {
  final permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
    return true;
  }
  
  if (permission == LocationPermission.deniedForever) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in OS Settings.')),
      );
    }
    return false;
  }
  
  // Show rationale dialog before requesting
  if (!context.mounted) return false;
  
  final shouldRequest = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.secondaryDark,
      title: const Row(
        children: [
          Icon(Icons.location_on, color: AppColors.electricBlue),
          SizedBox(width: 8),
          Text('Location Required', style: TextStyle(color: AppColors.white)),
        ],
      ),
      content: const Text(
        'Buddy Tracker needs access to your location to share it with your paired buddies when you explicitly refresh or start a tracking session. We only access your location while the app is open.',
        style: TextStyle(color: AppColors.whiteMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL', style: TextStyle(color: AppColors.whiteMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ALLOW', style: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  
  if (shouldRequest == true) {
    final locationService = ref.read(locationServiceProvider);
    return await locationService.requestPermission();
  }
  
  return false;
}
