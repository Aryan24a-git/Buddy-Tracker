import 'dart:io';

/// Network status classification per architecture.md §5.
enum NetworkStatus { online, offlineSmsPossible, offlineCacheOnly }

/// Service to monitor and detect internet and cellular connectivity.
class NetworkService {
  /// Checks whether internet connectivity is currently operational.
  Future<bool> isInternetReachable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Evaluates current connection status for transport selection.
  Future<NetworkStatus> currentStatus() async {
    final hasInternet = await isInternetReachable();
    if (hasInternet) {
      return NetworkStatus.online;
    }
    // If no internet, fallback to SMS if mobile platform, else cache only.
    if (Platform.isAndroid || Platform.isIOS) {
      return NetworkStatus.offlineSmsPossible;
    }
    return NetworkStatus.offlineCacheOnly;
  }
}
