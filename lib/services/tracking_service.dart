import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';
import 'package:buddy_tracker/services/refresh_service.dart';
import 'package:buddy_tracker/database/app_database.dart';

/// TrackingManager implementation per architecture.md §4 and §10.
/// Owns the ~15s loop for active tracking.
class TrackingService {
  final RefreshService _refreshService;
  final AppDatabase _database;
  
  bool _isTracking = false;
  String? _activeTargetId;
  Timer? _trackingTimer;
  
  TrackingService(this._refreshService, this._database);

  bool get isTracking => _isTracking;
  String? get activeTargetId => _activeTargetId;

  /// Starts tracking the given buddy with a ~15s loop.
  void startTracking(String buddyId) {
    if (_isTracking && _activeTargetId == buddyId) return;
    
    stopTracking(); // Ensure any existing tracking is stopped first.
    
    _isTracking = true;
    _activeTargetId = buddyId;
    
    debugPrint('TrackingService: Started tracking buddy $buddyId');
    
    // Log the session to DB
    _logSessionStart(buddyId);
    
    // Perform initial immediate request
    _requestUpdate();
    
    // Schedule loop
    _trackingTimer = Timer.periodic(AppConstants.trackingInterval, (_) {
      _requestUpdate();
    });
  }

  /// Stops any active tracking session.
  void stopTracking() {
    if (!_isTracking) return;
    
    debugPrint('TrackingService: Stopped tracking');
    
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    if (_activeTargetId != null) {
      _logSessionEnd(_activeTargetId!);
    }
    
    _isTracking = false;
    _activeTargetId = null;
  }
  
  /// Handles app lifecycle changes to stop tracking when backgrounded.
  void handleAppLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached || 
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      if (_isTracking) {
        debugPrint('TrackingService: App backgrounded/inactive, stopping tracking.');
        stopTracking();
      }
    }
  }
  
  Future<void> _requestUpdate() async {
    if (!_isTracking || _activeTargetId == null) return;
    
    debugPrint('TrackingService: Requesting update for $_activeTargetId');
    try {
      // In a real active tracking session, we also push our own location.
      // We could use refreshAll which does exactly this: get own GPS -> push to cloud -> request buddy.
      // If we only want to pull, we'd just use requestBuddyLocation.
      // But buddy tracking is a two-way visible state, so sending our location is expected.
      await _refreshService.refreshAll('my_id_placeholder', [_activeTargetId!]);
    } catch (e) {
      debugPrint('TrackingService error during loop: $e');
    }
  }
  
  Future<void> _logSessionStart(String buddyId) async {
    try {
      await _database.into(_database.trackingSessions).insert(
        TrackingSessionsCompanion.insert(
          id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
          buddyId: buddyId,
          startTime: DateTime.now(),
          mode: 'active',
        ),
      );
    } catch (e) {
      debugPrint('Error logging tracking session start: $e');
    }
  }
  
  Future<void> _logSessionEnd(String buddyId) async {
    try {
      final now = DateTime.now();
      await (_database.update(_database.trackingSessions)
            ..where((tbl) => tbl.buddyId.equals(buddyId) & tbl.endTime.isNull()))
          .write(TrackingSessionsCompanion(
            endTime: Value(now),
            isActive: const Value(false),
          ));
    } catch (e) {
      debugPrint('Error logging tracking session end: $e');
    }
  }
}
