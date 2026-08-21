import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' hide Column;
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
    } catch (e) {
      debugPrint('Error getting own location during refresh: $e');
    }

    // 2. Request buddy locations
    for (final buddyId in myBuddies) {
      await requestBuddyLocation(buddyId);
    }
    
    // 3. Sync accepted buddy relationships
    try {
      final acceptedRequests = await _supabaseService.getAcceptedRequests(myBuddyId);
      for (final req in acceptedRequests) {
        final buddyId = req['buddy_id'] as String?;
        if (buddyId != null) {
          // Add to local database if not exists
          final existing = await _database.buddiesDao.getBuddy(buddyId);
          if (existing == null) {
             await _database.buddiesDao.insertOrUpdateBuddy(
               Buddy(id: buddyId, publicKey: 'unknown'),
             );
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing accepted buddies: $e');
    }
    
    // 4. Update the local database with latest from cloud
    await updateDatabase(myBuddies);
  }

  /// Requests a specific buddy's location via the transport engine.
  Future<void> requestBuddyLocation(String buddyId) async {
    await _transportService.requestLocation(buddyId);
  }

  /// Updates the local database with fetched locations from Supabase.
  Future<void> updateDatabase(List<String> buddyIds) async {
    try {
      final latestLocations = await _supabaseService.getLatestLocations(buddyIds);
      
      for (final loc in latestLocations) {
        final buddyId = loc['buddy_id'] as String?;
        if (buddyId == null) continue;
        
        await _database.into(_database.lastLocations).insertOnConflictUpdate(
          LastLocationsCompanion.insert(
            buddyId: buddyId,
            latitude: (loc['latitude'] as num).toDouble(),
            longitude: (loc['longitude'] as num).toDouble(),
            accuracy: (loc['accuracy'] as num).toDouble(),
            timestamp: DateTime.parse(loc['timestamp'] as String).toLocal(),
            speed: Value(loc['speed'] != null ? (loc['speed'] as num).toDouble() : null),
            heading: Value(loc['heading'] != null ? (loc['heading'] as num).toDouble() : null),
            transport: loc['transport'] as String? ?? 'internet',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating database from Supabase: $e');
    }
  }
}
