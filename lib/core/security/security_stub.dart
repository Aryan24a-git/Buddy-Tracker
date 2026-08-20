import 'dart:convert';
import 'dart:math';

/// Security and cryptography utilities for Buddy Tracker.
class SecurityUtils {
  SecurityUtils._();

  /// Generates a random alphanumeric pairing token of given length.
  static String generatePairingToken([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generates a mock/placeholder public key for device identity.
  static String generatePublicKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Calculates CRC-16 (CCITT) checksum for integrity validation.
  static int computeCrc16(String data) {
    int crc = 0xFFFF;
    final bytes = utf8.encode(data);
    for (int b in bytes) {
      crc ^= b << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
