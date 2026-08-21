import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/database/app_database.dart';
import 'package:buddy_tracker/services/location_service.dart';
import 'package:buddy_tracker/services/supabase_service.dart';
import 'package:buddy_tracker/services/transport_service.dart';
import 'package:buddy_tracker/services/refresh_service.dart';
import 'package:buddy_tracker/services/tracking_service.dart';
import 'package:buddy_tracker/services/connectivity_service.dart';
import 'package:buddy_tracker/services/update_service.dart';

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

/// Provides the Connectivity monitor.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provides the Transport engine (internet-only, SMS removed).
final transportServiceProvider = Provider<TransportService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return TransportService(supabaseService);
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

/// Provides the Tracking manager (continuous location sharing).
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final database = ref.watch(databaseProvider);
  return TrackingService(locationService, supabaseService, connectivityService, database);
});

/// Provides the GitHub update checker service.
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// Asynchronously checks for new updates from GitHub on app startup.
final appUpdateCheckProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return updateService.checkForUpdate();
});
