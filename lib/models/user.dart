/// Lightweight user model used in Phase 1 (mock/static data).
/// Full Drift-backed model built in Phase 2.
class UserModel {
  const UserModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.avatarInitials,
  });

  final String id;
  final String displayName;
  final String phoneNumber;

  /// Two-letter initials for avatar fallback.
  final String? avatarInitials;

  String get initials =>
      avatarInitials ??
      displayName
          .split(' ')
          .take(2)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join();
}
