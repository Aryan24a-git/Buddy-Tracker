/// Transport channel used to obtain this location reading.
enum LocationTransport { internet, sms, cache }

/// Immutable location snapshot — matches the transport payload schema
/// defined in architecture.md §7.
class LocationModel {
  const LocationModel({
    required this.buddyId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
    this.transport = LocationTransport.cache,
    this.sequence = 0,
  });

  final String buddyId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Horizontal accuracy in meters (null if unknown).
  final double? accuracy;

  /// Speed in m/s (null if unknown).
  final double? speed;

  /// Heading in degrees (null if unknown).
  final double? heading;

  final LocationTransport transport;
  final int sequence;

  /// Speed in km/h for display purposes.
  double? get speedKmh => speed != null ? speed! * 3.6 : null;

  Duration get age => DateTime.now().difference(timestamp);
}
