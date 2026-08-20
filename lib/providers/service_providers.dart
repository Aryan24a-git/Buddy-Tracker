import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/database/app_database.dart';
import 'package:buddy_tracker/services/location_service.dart';
import 'package:buddy_tracker/services/supabase_service.dart';
import 'package:buddy_tracker/services/transport_service.dart';
import 'package:buddy_tracker/services/refresh_service.dart';
import 'package:buddy_tracker/services/tracking_service.dart';

import 'package:buddy_tracker/services/sms_service.dart';

/// Provides the local Drift database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provides the Location engine.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provides the Supabase cloud engine.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provides the SMS fallback engine.
final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

/// Provides the Transport engine.
final transportServiceProvider = Provider<TransportService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final smsService = ref.watch(smsServiceProvider);
  final database = ref.watch(databaseProvider);
  return TransportService(supabaseService, smsService, database);
});

/// Provides the Refresh manager (one-shot updates).
final refreshServiceProvider = Provider<RefreshService>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final transportService = ref.watch(transportServiceProvider);
  final database = ref.watch(databaseProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);

  return RefreshService(
    locationService,
    transportService,
    database,
    supabaseService,
  );
});

/// Provides the Tracking manager.
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final refreshService = ref.watch(refreshServiceProvider);
  final database = ref.watch(databaseProvider);
  return TrackingService(refreshService, database);
});
