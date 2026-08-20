import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'buddies_dao.g.dart';

@DriftAccessor(tables: [Buddies])
class BuddiesDao extends DatabaseAccessor<AppDatabase> with _$BuddiesDaoMixin {
  BuddiesDao(super.db);

  Future<List<Buddy>> getAllBuddies() => select(buddies).get();

  Stream<List<Buddy>> watchAllBuddies() => select(buddies).watch();

  Future<Buddy?> getBuddy(String id) =>
      (select(buddies)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> insertOrUpdateBuddy(Buddy buddy) =>
      into(buddies).insertOnConflictUpdate(buddy);

  Future<void> deleteBuddy(String id) =>
      (delete(buddies)..where((b) => b.id.equals(id))).go();
}
