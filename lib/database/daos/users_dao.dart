import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<User?> getUser(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<User?> getFirstUser() =>
      (select(users)..limit(1)).getSingleOrNull();

  Future<void> insertOrUpdateUser(User user) =>
      into(users).insertOnConflictUpdate(user);

  Future<void> deleteUser(String id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();
}
