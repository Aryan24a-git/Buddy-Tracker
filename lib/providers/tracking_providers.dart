import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user is currently sharing their location with buddies.
final isSharingLocationProvider = StateProvider<bool>((ref) => false);

/// Whether the user is currently being tracked by a buddy (privacy indicator state).
final beingTrackedProvider = StateProvider<bool>((ref) => false);

/// Active tracking session target buddy ID (the buddy currently being viewed on map).
/// Null indicates no active buddy view.
final activeTrackingTargetProvider = StateProvider<String?>((ref) => null);
