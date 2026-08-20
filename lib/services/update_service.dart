import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buddy_tracker/core/constants/app_constants.dart';

/// Represents available release info from GitHub.
class AppUpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
  });
}

/// Service to check for new app releases on GitHub and prompt the user.
class UpdateService {
  /// Checks whether a newer release exists on GitHub Releases.
  /// Returns [AppUpdateInfo] if a newer version is available, or `null` if up to date.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.userAgent = 'BuddyTrackerApp';
      final request = await client.getUrl(Uri.parse(AppConstants.githubLatestReleaseApi));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(responseBody);

        final tagName = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
        final releaseNotes = json['body'] as String? ?? 'New version available.';
        final releasePageUrl = json['html_url'] as String? ??
            'https://github.com/${AppConstants.githubRepo}/releases/latest';

        // Find direct APK download asset if present, else fallback to release page
        String downloadUrl = releasePageUrl;
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.contains('arm64-v8a') || name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] as String? ?? releasePageUrl;
              break;
            }
          }
        }

        if (_isNewerVersion(tagName, AppConstants.appVersion)) {
          debugPrint('UpdateService: Found newer version v$tagName (current: v${AppConstants.appVersion})');
          return AppUpdateInfo(
            latestVersion: tagName,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            releasePageUrl: releasePageUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error checking for updates: $e');
    }
    return null;
  }

  /// Opens the download / release page in the system browser.
  Future<bool> launchDownload(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UpdateService: Failed to launch update URL: $e');
      return false;
    }
  }

  /// Compares semantic version strings (e.g. "1.0.1" > "1.0.0").
  bool _isNewerVersion(String latest, String current) {
    if (latest.isEmpty || current.isEmpty) return false;
    final latestParts = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final currentParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }
}
