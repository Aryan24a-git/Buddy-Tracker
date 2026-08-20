import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart' show Buddy;

/// PairingManager implementation per architecture.md §9.
/// Handles identity generation, QR payload creation, scanning, and buddy establishment.
class PairingService {
  final Uuid _uuid = const Uuid();

  /// The version of the pairing protocol for forwards compatibility.
  static const String protocolVersion = 'v1';

  /// Generates a new identity consisting of buddy ID and keys.
  Map<String, String> generateIdentity() {
    return {
      'id': _uuid.v4(),
      'pk': 'pub_key_TODO', // Phase 5 or later
    };
  }

  /// Generates the payload to be embedded in a QR code.
  /// Payload = protocol version, buddy ID, public key, pairing token only.
  String generateQRPayload({
    required String myBuddyId,
    required String publicKey,
    required String pairingToken,
  }) {
    final Map<String, dynamic> payload = {
      'v': protocolVersion,
      'id': myBuddyId,
      'pk': publicKey,
      'tk': pairingToken,
    };
    return jsonEncode(payload);
  }

  /// Parses a scanned QR code payload and validates it.
  /// Returns a map with the parsed data if valid, or null if invalid.
  Map<String, dynamic>? parseScannedQR(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      
      // Validate schema
      if (data['v'] == null ||
          data['id'] == null ||
          data['pk'] == null ||
          data['tk'] == null) {
        return null;
      }
      
      return data;
    } catch (e) {
      return null; // Not a valid JSON or not our format
    }
  }

  /// Establishes a buddy relationship from parsed QR data and a chosen nickname.
  /// Generates a local Buddy object that can be inserted into the database.
  Buddy establishBuddy({
    required Map<String, dynamic> parsedQrData,
    required String nickname,
  }) {
    // In a real app, we might do a cryptographic handshake here using the public key and token.
    return Buddy(
      id: parsedQrData['id'] as String,
      nickname: nickname,
      publicKey: parsedQrData['pk'] as String,
    );
  }
}
