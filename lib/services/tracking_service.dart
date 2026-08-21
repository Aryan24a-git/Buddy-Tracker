import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';
import 'package:buddy_tracker/services/location_service.dart';
import 'package:buddy_tracker/services/supabase_service.dart';
import 'package:buddy_tracker/services/connectivity_service.dart';
import 'package:buddy_tracker/database/app_database.dart';

/// TrackingService — continuous background location sharing.
/// Owns the location broadcast loop. NOT per-buddy sessions — one global
/// "share my location" state controlled by Settings toggle.
class TrackingService {
  final LocationService _locationService;
  final SupabaseService _supabaseService;
  final ConnectivityService _connectivityService;
  final AppDatabase _database;

  bool _isSharingLocation = false;
  String? _myUserId;
  StreamSubscription? _positionSubscription;

  TrackingService(
    this._locationService,
    this._supabaseService,
    this._connectivityService,
    this._database,
  );

  bool get isSharingLocation => _isSharingLocation;

  /// Start sharing location continuously.
  Future<void> startSharing(String myUserId) async {
    if (_isSharingLocation) return;

    _myUserId = myUserId;
    _isSharingLocation = true;

    debugPrint('TrackingService: Started sharing location for user $myUserId');

    // Start connectivity monitoring for offline caching
    _connectivityService.onGoOffline = _handleGoOffline;
    _connectivityService.onGoOnline = _handleGoOnline;
    _connectivityService.startMonitoring();

    // Subscribe to position stream
    _positionSubscription = _locationService
        .getPositionStream(interval: AppConstants.trackingInterval)
        .listen(
      (location) async {
        if (!_isSharingLocation || _myUserId == null) return;

        try {
          if (_connectivityService.isOnline) {
            // Push to Supabase
            await _supabaseService.upsertLatestLocation(
              buddyId: _myUserId!,
              latitude: location.latitude,
              longitude: location.longitude,
              accuracy: location.accuracy ?? 0.0,
              timestamp: location.timestamp,
              speed: location.speed,
              heading: location.heading,
              transport: 'internet',
            );
          }
        } catch (e) {
          debugPrint('TrackingService: Failed to push location: $e');
        }

        // Always cache locally regardless of connectivity
        try {
          await _database.into(_database.lastLocations).insertOnConflictUpdate(
            LastLocationsCompanion.insert(
              buddyId: _myUserId!,
              latitude: location.latitude,
              longitude: location.longitude,
              accuracy: location.accuracy ?? 0.0,
              timestamp: location.timestamp,
              speed: Value(location.speed),
              heading: Value(location.heading),
              transport: _connectivityService.isOnline ? 'internet' : 'cache',
            ),
          );
        } catch (e) {
          debugPrint('TrackingService: Failed to cache location: $e');
        }
      },
      onError: (e) {
        debugPrint('TrackingService: Position stream error: $e');
      },
    );
  }

  /// Stop sharing location globally.
  void stopSharing() {
    if (!_isSharingLocation) return;

    debugPrint('TrackingService: Stopped sharing location');
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _connectivityService.dispose();
    _isSharingLocation = false;
    _myUserId = null;
  }

  /// Subscribe to a specific buddy's realtime location updates.
  StreamSubscription<Map<String, dynamic>>? subscribeToBuddy(String buddyId) {
    return _supabaseService.subscribeToBuddyLocation(buddyId).listen(
      (loc) async {
        debugPrint('TrackingService: Realtime update for buddy $buddyId');
        try {
          await _database.into(_database.lastLocations).insertOnConflictUpdate(
            LastLocationsCompanion.insert(
              buddyId: buddyId,
              latitude: (loc['latitude'] as num).toDouble(),
              longitude: (loc['longitude'] as num).toDouble(),
              accuracy: (loc['accuracy'] as num).toDouble(),
              timestamp: DateTime.parse(loc['timestamp'] as String).toLocal(),
              speed: Value(loc['speed'] != null ? (loc['speed'] as num).toDouble() : null),
              heading: Value(loc['heading'] != null ? (loc['heading'] as num).toDouble() : null),
              transport: 'internet',
            ),
          );
        } catch (e) {
          debugPrint('TrackingService: Error inserting realtime location: $e');
        }
      },
    );
  }

  void _handleGoOffline() {
    debugPrint('TrackingService: Went offline — locations will be cached locally');
  }

  void _handleGoOnline() {
    debugPrint('TrackingService: Back online — resuming cloud sync');
  }
}
