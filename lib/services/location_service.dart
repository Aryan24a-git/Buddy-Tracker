import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/errors/app_errors.dart';
import '../models/location.dart' as app;

/// LocationManager implementation per architecture.md §4.
/// Handles current location, accuracy, speed, heading, and validation.
class LocationService {
  /// Ensures location services are enabled and permissions are granted.
  /// Throws an exception if permissions are permanently denied.
  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationError('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationError('PERMISSION_DENIED');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationError(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  /// Requests permission from the OS. Should be called by UI after showing rationale.
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  /// Requests background location permission (must be called AFTER fine location is granted).
  Future<bool> requestBackgroundPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always;
  }

  Future<app.LocationModel> getCurrentLocation() async {
    try {
      await _checkPermissions();
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Issue E fix: Guard against (0,0) — GPS/network provider failure
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw const LocationError(
            'GPS returned (0,0) — no valid signal. Treating as no location.');
      }

      return app.LocationModel(
        buddyId: 'self',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        speed: position.speed,
        heading: position.heading,
        transport: app.LocationTransport.internet,
      );
    } on TimeoutException {
      throw const LocationError('Location request timed out. No signal.');
    } catch (e) {
      if (e is LocationError) rethrow;
      throw LocationError('Failed to get location: $e');
    }
  }

  /// Returns a stream of position updates for continuous tracking.
  Stream<app.LocationModel> getPositionStream({
    Duration interval = const Duration(seconds: 15),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Buddy Tracker',
          notificationText: 'Sharing your location with buddies',
          enableWakeLock: true,
        ),
      ),
    ).where((position) {
      // Issue E: Filter out (0,0) positions
      return !(position.latitude == 0.0 && position.longitude == 0.0);
    }).map((position) {
      return app.LocationModel(
        buddyId: 'self',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        speed: position.speed,
        heading: position.heading,
        transport: app.LocationTransport.internet,
      );
    });
  }

  /// Returns the estimated accuracy (in meters) of the current location.
  Future<double?> getAccuracy() async {
    final loc = await getCurrentLocation();
    return loc.accuracy;
  }

  /// Returns the current speed (in m/s).
  Future<double?> getSpeed() async {
    final loc = await getCurrentLocation();
    return loc.speed;
  }

  /// Returns the current heading (in degrees).
  Future<double?> getHeading() async {
    final loc = await getCurrentLocation();
    return loc.heading;
  }

  /// Validates a location (e.g. checks if it's within bounds or not spoofed/invalid).
  bool validateLocation(app.LocationModel location) {
    if (location.latitude < -90 || location.latitude > 90) return false;
    if (location.longitude < -180 || location.longitude > 180) return false;
    // Issue E: Reject (0,0)
    if (location.latitude == 0.0 && location.longitude == 0.0) return false;
    return true;
  }
}
