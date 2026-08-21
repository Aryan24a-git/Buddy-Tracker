import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:buddy_tracker/features/onboarding/screens/splash_screen.dart';
import 'package:buddy_tracker/features/dashboard/screens/dashboard_screen.dart';
import 'package:buddy_tracker/features/tracking/screens/active_tracking_screen.dart';
import 'package:buddy_tracker/features/pairing/screens/my_qr_screen.dart';
import 'package:buddy_tracker/features/pairing/screens/scan_qr_screen.dart';
import 'package:buddy_tracker/features/pairing/screens/add_buddy_screen.dart';
import 'package:buddy_tracker/features/buddies/screens/buddy_list_screen.dart';
import 'package:buddy_tracker/features/profile/screens/settings_screen.dart';

import 'package:buddy_tracker/features/onboarding/screens/onboarding_screen.dart';

/// Named route paths.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String tracking = '/tracking/:buddyId';
  static const String myQr = '/my_qr';
  static const String scanQr = '/scan_qr';
  static const String addBuddy = '/add_buddy';
  static const String buddies = '/buddies';
  static const String settings = '/settings';
}

/// Application router using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.buddies,
      builder: (BuildContext context, GoRouterState state) =>
          const BuddyListScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.tracking,
      builder: (BuildContext context, GoRouterState state) {
        final buddyId = state.pathParameters['buddyId'] ?? '';
        return ActiveTrackingScreen(buddyId: buddyId);
      },
    ),
    GoRoute(
      path: AppRoutes.myQr,
      builder: (BuildContext context, GoRouterState state) =>
          const MyQrScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanQr,
      builder: (BuildContext context, GoRouterState state) =>
          const ScanQrScreen(),
    ),
    GoRoute(
      path: AppRoutes.addBuddy,
      builder: (BuildContext context, GoRouterState state) {
        final qrData = state.extra as String? ?? '';
        return AddBuddyScreen(qrData: qrData);
      },
    ),
  ],
);
