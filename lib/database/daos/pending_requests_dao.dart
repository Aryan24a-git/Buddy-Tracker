import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'pending_requests_dao.g.dart';

@DriftAccessor(tables: [PendingRequests])
class PendingRequestsDao extends DatabaseAccessor<AppDatabase> with _$PendingRequestsDaoMixin {
  PendingRequestsDao(super.db);

  Future<List<PendingRequest>> getAllPendingRequests() =>
      (select(pendingRequests)..where((p) => p.status.equals('pending'))).get();

  Stream<List<PendingRequest>> watchAllPendingRequests() =>
      (select(pendingRequests)..where((p) => p.status.equals('pending'))).watch();

  Future<void> insertRequest(PendingRequest request) =>
      into(pendingRequests).insertOnConflictUpdate(request);

  Future<void> updateRequestStatus(String id, String status) =>
      (update(pendingRequests)..where((p) => p.id.equals(id)))
          .write(PendingRequestsCompanion(status: Value(status)));

  Future<void> deleteRequest(String id) =>
      (delete(pendingRequests)..where((p) => p.id.equals(id))).go();
}
