import 'package:flutter/foundation.dart';
import 'package:buddy_tracker/services/supabase_service.dart';

/// TransportManager — simplified for internet-only transport.
/// SMS fallback has been removed. When internet is unavailable,
/// last-known location is cached locally (handled by ConnectivityService).
class TransportService {
  final SupabaseService _supabaseService;

  TransportService(this._supabaseService);

  /// Sends the local device's location to Supabase.
  Future<void> sendLocation({
    required String buddyId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    double? speed,
    double? heading,
  }) async {
    try {
      await _supabaseService.upsertLatestLocation(
        buddyId: buddyId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        timestamp: timestamp,
        speed: speed,
        heading: heading,
        transport: 'internet',
      );
    } catch (e) {
      debugPrint('TransportService: Failed to send location: $e');
      rethrow;
    }
  }

  /// Requests a buddy's location via Supabase query.
  Future<void> requestLocation(String buddyId) async {
    // With Supabase, we query latest_locations or listen to realtime channel.
    // No explicit request needed — the realtime subscription handles this.
  }
}
