/// Typed failure types for Buddy Tracker.
/// Expanded in Phase 3+ as real services are added.
sealed class BuddyTrackerError {
  const BuddyTrackerError(this.message);
  final String message;
}

class LocationError extends BuddyTrackerError {
  const LocationError(super.message);
}

class TransportError extends BuddyTrackerError {
  const TransportError(super.message);
}

class PairingError extends BuddyTrackerError {
  const PairingError(super.message);
}

class DatabaseError extends BuddyTrackerError {
  const DatabaseError(super.message);
}
