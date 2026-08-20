import 'package:flutter/foundation.dart';
import 'package:buddy_tracker/database/app_database.dart';
import 'package:buddy_tracker/services/location_service.dart';
import 'package:buddy_tracker/services/transport_service.dart';
import 'package:buddy_tracker/services/supabase_service.dart';

/// RefreshManager implementation per architecture.md §4 and §11.
/// Handles one-shot refresh of locations.
class RefreshService {
  final LocationService _locationService;
  final TransportService _transportService;
  final AppDatabase _database;
  final SupabaseService _supabaseService;

  RefreshService(
    this._locationService,
    this._transportService,
    this._database,
    this._supabaseService,
  );

  /// Performs a one-shot refresh of all data.
  /// 1. Gets own GPS.
  /// 2. Requests buddy locations (and sends own location to cloud).
  /// 3. Updates local DB.
  /// 4. Map updates automatically via DB streams in providers.
  Future<void> refreshAll(String myBuddyId, List<String> myBuddies) async {
    try {
      // 1. Get own GPS
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        // Broadcast our location to the transport layer
        await _transportService.sendLocation(
          buddyId: myBuddyId,
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          accuracy: currentLocation.accuracy ?? 0.0,
          timestamp: currentLocation.timestamp,
          speed: currentLocation.speed,
          heading: currentLocation.heading,
        );
      }
    } catch (e) {
      debugPrint('Error getting own location during refresh: $e');
    }

    // 2. Request buddy locations
    for (final buddyId in myBuddies) {
      await requestBuddyLocation(buddyId);
    }
    
    // In a real implementation with Supabase, we would do a direct query to latest_locations
    // to fetch the latest state of all buddies for the one-shot refresh.
    // For Phase 6, we'll simulate an update loop if necessary, or let Supabase realtime
    // streams handle the database updates.
    await updateDatabase();
  }

  /// Requests a specific buddy's location via the transport engine.
  Future<void> requestBuddyLocation(String buddyId) async {
    await _transportService.requestLocation(buddyId);
  }

  /// Updates the local database with fetched locations.
  Future<void> updateDatabase() async {
    // Phase 6 placeholder: Supabase fetching and Drift updating logic.
    // We would query Supabase for latest_locations of our buddies and update Drift.
    debugPrint('Database updated from RefreshService using ${_database.runtimeType} and ${_supabaseService.runtimeType}');
  }
}
