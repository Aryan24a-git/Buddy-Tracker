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

  Future<app.LocationModel> getCurrentLocation() async {
    try {
      await _checkPermissions();
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return app.LocationModel(
        buddyId: 'self', // Represents the current user's location
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        speed: position.speed,
        heading: position.heading,
        transport: app.LocationTransport.internet, // Defaulting to internet for local GPS source
      );
    } on TimeoutException {
      throw const LocationError('Location request timed out. No signal.');
    } catch (e) {
      if (e is LocationError) rethrow;
      throw LocationError('Failed to get location: $e');
    }
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
    // Additional validation logic per architecture can go here.
    return true;
  }
}
