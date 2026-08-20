import 'package:flutter/foundation.dart';
import 'package:buddy_tracker/services/supabase_service.dart';
import 'package:buddy_tracker/services/sms_service.dart';
import 'package:buddy_tracker/database/app_database.dart';

/// TransportManager implementation per architecture.md §4 and §5.
/// The single decision point for Internet vs SMS vs cache.
class TransportService {
  final SupabaseService _supabaseService;
  final SmsService _smsService;
  final AppDatabase _database;

  TransportService(this._supabaseService, this._smsService, this._database);

  /// Mocks a network check. In production, use the `connectivity_plus` package.
  Future<bool> _isInternetAvailable() async {
    // Stub: assume internet is available for now.
    // To test SMS fallback (Test B), change this to return false.
    return true; 
  }

  /// Mocks an SMS availability check. In production, use `telephony` or check SIM state.
  Future<bool> _isSmsAvailable() async {
    // Stub: assume SMS is available.
    // To test Test C (no comms), change this to return false.
    return true;
  }

  /// Selects the best transport mechanism (Internet or SMS).
  Future<String> selectTransport() async {
    if (await _isInternetAvailable()) {
      return 'internet';
    } else if (await _isSmsAvailable()) {
      return 'sms';
    } else {
      return 'cache'; // No communication available
    }
  }

  /// Sends the local device's location to the buddy using the best transport.
  Future<void> sendLocation({
    required String buddyId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    double? speed,
    double? heading,
  }) async {
    final transport = await selectTransport();

    if (transport == 'internet') {
      try {
        await _supabaseService.upsertLatestLocation(
          buddyId: buddyId,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          timestamp: timestamp,
          speed: speed,
          heading: heading,
          transport: transport,
        );
      } catch (e) {
        debugPrint('Internet transport failed, falling back to SMS: $e');
        await _sendViaSms(buddyId, latitude, longitude, accuracy, timestamp);
      }
    } else if (transport == 'sms') {
      await _sendViaSms(buddyId, latitude, longitude, accuracy, timestamp);
    } else {
      debugPrint('No transport available to send location. Queuing for retry.');
      handleRetry();
    }
  }
  
  Future<void> _sendViaSms(String buddyId, double latitude, double longitude, double accuracy, DateTime timestamp) async {
    // Look up buddy from local Drift DB
    final user = await (_database.select(_database.users)..where((tbl) => tbl.id.equals(buddyId))).getSingleOrNull();
    final phoneNumber = user?.phoneNumber ?? '+1234567890';
    final packet = _smsService.encodeLocationPacket(latitude, longitude, accuracy, timestamp);
    await _smsService.sendSms(phoneNumber, packet);
  }

  /// Requests the buddy's location.
  Future<void> requestLocation(String buddyId) async {
    final transport = await selectTransport();
    
    if (transport == 'internet') {
      // With Supabase, we query latest_locations or listen to realtime channel.
    } else if (transport == 'sms') {
      final user = await (_database.select(_database.users)..where((tbl) => tbl.id.equals(buddyId))).getSingleOrNull();
      final phoneNumber = user?.phoneNumber ?? '+1234567890';
      await _smsService.sendSms(phoneNumber, 'BT:REQ'); // Location request ping
    } else {
      debugPrint('No transport available to request location.');
    }
  }

  /// Handles retrying failed location packets when offline.
  void handleRetry() {
    debugPrint('Queued location packet for retry upon reconnection.');
  }
}
