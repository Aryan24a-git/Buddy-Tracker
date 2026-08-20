import 'package:buddy_tracker/core/constants/app_constants.dart';

/// Location freshness states, per design.md §8.
enum FreshnessState { fresh, aging, stale }

/// Returns the [FreshnessState] for a location with the given [age].
FreshnessState freshnessOf(Duration age) {
  if (age <= AppConstants.freshnessThresholdFresh) return FreshnessState.fresh;
  if (age <= AppConstants.freshnessThresholdAging) return FreshnessState.aging;
  return FreshnessState.stale;
}

/// Human-readable "X sec/min ago" label.
String formatAge(DateTime timestamp) {
  final age = DateTime.now().difference(timestamp);
  if (age.inSeconds < 60) return '${age.inSeconds} sec ago';
  if (age.inMinutes < 60) return '${age.inMinutes} min ago';
  return '${age.inHours} hr ago';
}

/// Short time string for "Last Sync: 10:42 PM".
String formatTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $suffix';
}
