import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/models/location.dart';

/// Provides the active buddy list for display on dashboard and radar.
final buddyListProvider = Provider<List<BuddyModel>>((ref) {
  final now = DateTime.now();
  return [
    BuddyModel(
      id: 'buddy-1',
      displayName: 'Rahul Mech',
      lastLocation: LocationModel(
        buddyId: 'buddy-1',
        latitude: 12.9720,
        longitude: 77.5946,
        timestamp: now.subtract(const Duration(minutes: 4)),
        accuracy: 12,
        speed: 0.58, // ~2.1 km/h
        transport: LocationTransport.internet,
      ),
    ),
    BuddyModel(
      id: 'buddy-2',
      displayName: 'Priya CS',
      lastLocation: LocationModel(
        buddyId: 'buddy-2',
        latitude: 12.9736,
        longitude: 77.5952,
        timestamp: now.subtract(const Duration(seconds: 18)),
        accuracy: 8,
        speed: 1.2,
        transport: LocationTransport.sms,
      ),
    ),
    BuddyModel(
      id: 'buddy-3',
      displayName: 'Arjun ECE',
      lastLocation: LocationModel(
        buddyId: 'buddy-3',
        latitude: 12.9650,
        longitude: 77.5890,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        accuracy: 20,
        transport: LocationTransport.cache,
      ),
    ),
  ];
});

/// Selected buddy ID for the active tracking screen.
final selectedBuddyIdProvider = StateProvider<String?>((ref) => null);
