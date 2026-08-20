import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'last_locations_dao.g.dart';

@DriftAccessor(tables: [LastLocations])
class LastLocationsDao extends DatabaseAccessor<AppDatabase> with _$LastLocationsDaoMixin {
  LastLocationsDao(super.db);

  Future<LastLocation?> getLocationForBuddy(String buddyId) =>
      (select(lastLocations)..where((l) => l.buddyId.equals(buddyId))).getSingleOrNull();

  Stream<LastLocation?> watchLocationForBuddy(String buddyId) =>
      (select(lastLocations)..where((l) => l.buddyId.equals(buddyId))).watchSingleOrNull();

  Future<void> insertOrUpdateLocation(LastLocation location) =>
      into(lastLocations).insertOnConflictUpdate(location);

  Future<void> deleteLocationForBuddy(String buddyId) =>
      (delete(lastLocations)..where((l) => l.buddyId.equals(buddyId))).go();
}
