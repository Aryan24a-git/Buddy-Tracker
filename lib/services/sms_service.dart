import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';

/// Service to handle SMS formatting, sending, and parsing.
/// Phase 9 — SMS Fallback.
class SmsService {
  int _sequenceNumber = 0;

  /// Compiles a compact location payload per architecture.md §7
  /// Format: lat,lon,timestamp,sequence,accuracy,CRC
  String encodeLocationPacket(
      double lat, double lon, double accuracy, DateTime timestamp) {
    _sequenceNumber++;
    
    // Using seconds since epoch for compactness
    final ts = timestamp.millisecondsSinceEpoch ~/ 1000;
    
    // Format coordinates to 5 decimal places (~1.1 meter precision)
    final latStr = lat.toStringAsFixed(5);
    final lonStr = lon.toStringAsFixed(5);
    final accStr = accuracy.toStringAsFixed(1);
    
    final payload = '$latStr,$lonStr,$ts,$_sequenceNumber,$accStr';
    final crc = _computeCrc16(payload);
    
    return '${AppConstants.smsLocationPrefix}$payload,$crc';
  }

  /// Parses an incoming SMS payload. Returns null if invalid or CRC fails.
  Map<String, dynamic>? decodeLocationPacket(String smsBody) {
    if (!smsBody.startsWith(AppConstants.smsLocationPrefix)) {
      return null;
    }
    
    final body = smsBody.substring(AppConstants.smsLocationPrefix.length);
    final parts = body.split(',');
    
    if (parts.length != 6) {
      debugPrint('SmsService: Invalid packet part count');
      return null;
    }
    
    final payloadToVerify = parts.sublist(0, 5).join(',');
    final providedCrc = int.tryParse(parts[5]);
    
    if (providedCrc == null || providedCrc != _computeCrc16(payloadToVerify)) {
      debugPrint('SmsService: CRC mismatch or invalid CRC');
      return null;
    }
    
    return {
      'latitude': double.tryParse(parts[0]),
      'longitude': double.tryParse(parts[1]),
      'timestamp': DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(parts[2]) ?? 0) * 1000),
      'sequence': int.tryParse(parts[3]),
      'accuracy': double.tryParse(parts[4]),
    };
  }

  /// Sends location SMS packet via cellular transport.
  /// Requires active SIM and real-device testing per architecture.md §15 Test B/C.
  Future<bool> sendSms(String phoneNumber, String message) async {
    debugPrint('SmsService: Transmitting packet to $phoneNumber -> $message');
    return true; // Simulating successful transmission
  }

  /// Basic CRC-16 (CCITT) implementation for integrity checking
  int _computeCrc16(String data) {
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
