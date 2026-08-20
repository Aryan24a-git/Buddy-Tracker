import 'location.dart';

/// Lightweight buddy model used in Phase 1 (mock/static data).
/// Full Drift-backed model built in Phase 2.
class BuddyModel {
  const BuddyModel({
    required this.id,
    required this.displayName,
    this.nickname,
    this.lastLocation,
  });

  final String id;
  final String displayName;

  /// Private nickname set by the current user (not shared).
  final String? nickname;

  final LocationModel? lastLocation;

  /// The name shown in the UI (nickname overrides displayName).
  String get label => nickname ?? displayName;

  String get initials =>
      label
          .split(' ')
          .take(2)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join();
}
