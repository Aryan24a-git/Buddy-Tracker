import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Manager implementation per architecture.md §7.
/// Handles cloud database interaction and realtime subscriptions.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Initializes the Supabase client.
  /// Keys should be loaded from environment variables in a real app.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );
  }

  // ── Users Table ────────────────────────────────────────────────────────
  
  /// Upserts a user's identity into the cloud `users` table.
  Future<void> upsertUser({
    required String id,
    required String publicKey,
  }) async {
    await _client.from('users').upsert({
      'id': id,
      'public_key': publicKey,
      'last_active': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Buddy Relationships Table ──────────────────────────────────────────

  /// Adds a verified buddy relationship to the cloud.
  Future<void> addBuddyRelationship({
    required String user1Id,
    required String user2Id,
  }) async {
    await _client.from('buddy_relationships').upsert({
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Latest Locations Table ─────────────────────────────────────────────

  /// Upserts the user's latest location to the cloud.
  /// As per architecture.md §7, we store only the latest location per user.
  Future<void> upsertLatestLocation({
    required String buddyId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    double? speed,
    double? heading,
    required String transport,
  }) async {
    await _client.from('latest_locations').upsert({
      'buddy_id': buddyId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'speed': speed,
      'heading': heading,
      'transport': transport,
    });
  }

  /// Subscribes to realtime updates on the `latest_locations` table for a specific buddy.
  /// Returns a stream of location data payload maps.
  Stream<Map<String, dynamic>> subscribeToBuddyLocation(String buddyId) {
    // Note: The realtime channel needs to be configured in the Supabase dashboard
    // for the 'latest_locations' table.
    final streamController = StreamController<Map<String, dynamic>>();

    final channel = _client
        .channel('public:latest_locations:buddy_id=eq.$buddyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'latest_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buddy_id',
            value: buddyId,
          ),
          callback: (PostgresChangePayload payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              streamController.add(record);
            }
          },
        )
        .subscribe();

    streamController.onCancel = () {
      _client.removeChannel(channel);
      streamController.close();
    };

    return streamController.stream;
  }

  // ── Tracking Sessions Table ────────────────────────────────────────────

  /// Upserts a tracking session to the cloud.
  Future<void> upsertTrackingSession({
    required String sessionId,
    required String buddyId,
    required DateTime startTime,
    DateTime? endTime,
    required bool isActive,
    required String mode,
  }) async {
    await _client.from('tracking_sessions').upsert({
      'id': sessionId,
      'buddy_id': buddyId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'is_active': isActive,
      'mode': mode,
    });
  }
}
