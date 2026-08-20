import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'tracking_sessions_dao.g.dart';

@DriftAccessor(tables: [TrackingSessions])
class TrackingSessionsDao extends DatabaseAccessor<AppDatabase> with _$TrackingSessionsDaoMixin {
  TrackingSessionsDao(super.db);

  Future<List<TrackingSession>> getActiveSessions() =>
      (select(trackingSessions)..where((t) => t.isActive.equals(true))).get();

  Stream<List<TrackingSession>> watchActiveSessions() =>
      (select(trackingSessions)..where((t) => t.isActive.equals(true))).watch();

  Future<TrackingSession?> getSession(String id) =>
      (select(trackingSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertOrUpdateSession(TrackingSession session) =>
      into(trackingSessions).insertOnConflictUpdate(session);

  Future<void> endSession(String id) =>
      (update(trackingSessions)..where((t) => t.id.equals(id)))
          .write(TrackingSessionsCompanion(
            isActive: const Value(false),
            endTime: Value(DateTime.now()),
          ));
}
