import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Manager implementation per architecture.md §7.
/// Handles cloud database interaction and realtime subscriptions.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Initializes the Supabase client.
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
    required String displayName,
    required String publicKey,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    await _client.from('users').upsert({
      'id': id,
      'display_name': displayName,
      'public_key': publicKey,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
    });
  }

  // ── Buddy Relationships Table ──────────────────────────────────────────

  /// Adds a verified buddy relationship to the cloud.
  Future<void> addBuddyRelationship({
    required String userId,
    required String buddyId,
    String status = 'accepted',
  }) async {
    await _client.from('buddy_relationships').upsert({
      'id': '${userId}_$buddyId',
      'user_id': userId,
      'buddy_id': buddyId,
      'status': status,
    });
  }

  /// Subscribes to incoming buddy requests where this user is the target (buddy_id).
  Stream<List<Map<String, dynamic>>> subscribeToBuddyRequests(String myUserId) {
    return _client
        .from('buddy_relationships')
        .stream(primaryKey: ['id'])
        .eq('buddy_id', myUserId)
        .eq('status', 'pending');
  }

  /// Subscribes to accepted relationships where this user is the requester (user_id).
  Stream<List<Map<String, dynamic>>> subscribeToAcceptedRequests(String myUserId) {
    return _client
        .from('buddy_relationships')
        .stream(primaryKey: ['id'])
        .eq('user_id', myUserId)
        .eq('status', 'accepted');
  }

  /// Fetches accepted relationships where this user is the requester.
  Future<List<Map<String, dynamic>>> getAcceptedRequests(String myUserId) async {
    final response = await _client
        .from('buddy_relationships')
        .select()
        .eq('user_id', myUserId)
        .eq('status', 'accepted');
    return List<Map<String, dynamic>>.from(response);
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
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Fetches the latest locations for a list of buddies.
  Future<List<Map<String, dynamic>>> getLatestLocations(List<String> buddyIds) async {
    if (buddyIds.isEmpty) return [];
    
    final response = await _client
        .from('latest_locations')
        .select()
        .inFilter('buddy_id', buddyIds);
        
    return List<Map<String, dynamic>>.from(response);
  }

  /// Subscribes to realtime updates on the `latest_locations` table for a specific buddy.
  /// Returns a stream of location data payload maps.
  Stream<Map<String, dynamic>> subscribeToBuddyLocation(String buddyId) {
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
    required String userId,
    required String buddyId,
    required DateTime startedAt,
    DateTime? endedAt,
    required bool isActive,
    required String mode,
  }) async {
    await _client.from('tracking_sessions').upsert({
      'id': sessionId,
      'user_id': userId,
      'buddy_id': buddyId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'is_active': isActive,
      'mode': mode,
    });
  }

  // ── Notifications Table ─────────────────────────────────────────────────

  /// Sends an in-app notification to a user (informational only, non-blocking).
  Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String message,
  }) async {
    await _client.from('notifications').insert({
      'to_user_id': toUserId,
      'from_user_id': fromUserId,
      'message': message,
    });
  }

  /// Fetches unread notifications for the current user.
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('to_user_id', userId)
        .eq('read', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

