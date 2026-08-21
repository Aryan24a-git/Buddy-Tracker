import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity monitoring service.
/// Triggers last-known location caching when internet is lost.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Callback for when connectivity changes.
  VoidCallback? onGoOffline;
  VoidCallback? onGoOnline;

  /// Start monitoring connectivity changes.
  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (wasOnline && !_isOnline) {
        debugPrint('ConnectivityService: Gone OFFLINE — caching last-known location');
        onGoOffline?.call();
      } else if (!wasOnline && _isOnline) {
        debugPrint('ConnectivityService: Back ONLINE — resuming location sync');
        onGoOnline?.call();
      }
    });
  }

  /// Check current connectivity state.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    return _isOnline;
  }

  /// Stop monitoring.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
