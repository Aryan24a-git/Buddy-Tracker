import 'dart:math' as math;

import 'package:buddy_tracker/core/constants/app_constants.dart';

/// Haversine distance between two GPS coordinates (meters).
/// Single source of truth — see code-structure.md §4.
///
/// Returns distance in **meters**.
double haversineDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const r = AppConstants.earthRadiusMeters;

  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * math.pi / 180;

/// Human-readable distance string ("320 m" / "3.2 km").
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}
