/// Tracking session state per architecture.md §6 state machine.
enum TrackingSessionState { cached, refreshing, updated, tracking }

/// Lightweight tracking session model (Phase 1 — no Drift yet).
class TrackingSession {
  const TrackingSession({
    required this.sessionId,
    required this.buddyId,
    required this.state,
    this.startedAt,
    this.stoppedAt,
  });

  final String sessionId;
  final String buddyId;
  final TrackingSessionState state;
  final DateTime? startedAt;
  final DateTime? stoppedAt;

  bool get isActive => state == TrackingSessionState.tracking;
}
