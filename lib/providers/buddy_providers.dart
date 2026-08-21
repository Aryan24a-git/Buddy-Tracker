import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddy_tracker/models/buddy.dart';
import 'package:buddy_tracker/models/location.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:buddy_tracker/database/app_database.dart';

/// Reactive provider that streams real buddies and their latest locations directly from Drift SQLite.
final buddyListStreamProvider = StreamProvider<List<BuddyModel>>((ref) {
  final db = ref.watch(databaseProvider);

  // Watch buddies and join with their last known locations
  final query = db.select(db.buddies).join([
    leftOuterJoin(
      db.lastLocations,
      db.lastLocations.buddyId.equalsExp(db.buddies.id),
    ),
  ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      final buddyData = row.readTable(db.buddies);
      final locationData = row.readTableOrNull(db.lastLocations);

      LocationModel? location;
      if (locationData != null) {
        LocationTransport transport;
        switch (locationData.transport) {
          case 'internet':
            transport = LocationTransport.internet;
            break;
          case 'sms':
            transport = LocationTransport.sms;
            break;
          default:
            transport = LocationTransport.cache;
        }

        location = LocationModel(
          buddyId: locationData.buddyId,
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          timestamp: locationData.timestamp,
          accuracy: locationData.accuracy,
          speed: locationData.speed,
          heading: locationData.heading,
          transport: transport,
        );
      }

      return BuddyModel(
        id: buddyData.id,
        displayName: buddyData.nickname ?? 'Buddy ${buddyData.id.substring(0, buddyData.id.length.clamp(0, 6))}',
        nickname: buddyData.nickname,
        lastLocation: location,
      );
    }).toList();
  });
});

/// Convenience synchronous list provider providing the current data (or empty list if uninitialized).
final buddyListProvider = Provider<List<BuddyModel>>((ref) {
  final asyncValue = ref.watch(buddyListStreamProvider);
  return asyncValue.value ?? const [];
});

/// Selected buddy ID for active tracking.
final selectedBuddyIdProvider = StateProvider<String?>((ref) => null);

/// Provides the current local user identity.
final currentUserProvider = FutureProvider<User?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.usersDao.getFirstUser();
});

/// Stream of incoming pending buddy requests from Supabase.
final pendingBuddyRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }
  
  final supabase = ref.watch(supabaseServiceProvider);
  yield* supabase.subscribeToBuddyRequests(user.id);
});
