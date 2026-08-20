import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user is currently being tracked by a buddy (privacy indicator state).
final beingTrackedProvider = StateProvider<bool>((ref) => false);

/// Active tracking session target buddy ID (the buddy currently being tracked).
/// Null indicates no active tracking session.
final activeTrackingTargetProvider = StateProvider<String?>((ref) => null);
