import 'package:flutter_test/flutter_test.dart';
import 'package:buddy_tracker/core/utils/distance.dart';
import 'package:buddy_tracker/core/utils/freshness.dart';
import 'package:buddy_tracker/services/location_service.dart';
import 'package:buddy_tracker/models/location.dart';

void main() {
  group('Distance (Haversine) Unit Tests', () {
    test('Calculates zero distance for identical coordinates', () {
      final dist = haversineDistance(
        lat1: 12.9716,
        lon1: 77.5946,
        lat2: 12.9716,
        lon2: 77.5946,
      );
      expect(dist, closeTo(0.0, 0.01));
    });

    test('Formats distance correctly for meters and kilometers', () {
      expect(formatDistance(45.0), '45 m');
      expect(formatDistance(320.0), '320 m');
      expect(formatDistance(1250.0), '1.3 km');
    });
  });

  group('Freshness Unit Tests', () {
    test('Calculates freshness state correctly', () {
      expect(freshnessOf(const Duration(seconds: 10)), FreshnessState.fresh);
      expect(freshnessOf(const Duration(minutes: 2)), FreshnessState.aging);
      expect(freshnessOf(const Duration(minutes: 10)), FreshnessState.stale);
    });

    test('Formats time and age strings accurately', () {
      final now = DateTime.now();
      expect(formatAge(now.subtract(const Duration(seconds: 15))), '15 sec ago');
      expect(formatAge(now.subtract(const Duration(minutes: 3))), '3 min ago');
      expect(formatAge(now.subtract(const Duration(hours: 2))), '2 hr ago');
    });
  });

  group('LocationService (0,0) Guard Unit Tests', () {
    final locationService = LocationService();

    test('validateLocation rejects (0,0) coordinate', () {
      final invalidLoc = LocationModel(
        buddyId: 'test',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
      expect(locationService.validateLocation(invalidLoc), isFalse);
    });

    test('validateLocation accepts valid non-zero coordinate', () {
      final validLoc = LocationModel(
        buddyId: 'test',
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime.now(),
      );
      expect(locationService.validateLocation(validLoc), isTrue);
    });

    test('validateLocation rejects out-of-bounds coordinates', () {
      final outOfBoundsLoc = LocationModel(
        buddyId: 'test',
        latitude: 95.0,
        longitude: 77.5946,
        timestamp: DateTime.now(),
      );
      expect(locationService.validateLocation(outOfBoundsLoc), isFalse);
    });
  });
}
