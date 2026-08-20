import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'routing/app_router.dart';
import 'package:buddy_tracker/providers/service_providers.dart';
import 'package:buddy_tracker/providers/tracking_providers.dart';

/// Buddy Tracker — app bootstrap.
///
/// Phase 1: theme + UI scaffold only.
/// Phase 2 will add Drift database init.
/// Phase 5 will add Supabase.initialize() here.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for campus-use UX.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Deep black status/nav bar to match the theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // Riverpod ProviderScope wraps the entire app.
    const ProviderScope(
      child: BuddyTrackerApp(),
    ),
  );
}

/// Root widget. All navigation is handled by [appRouter].
class BuddyTrackerApp extends ConsumerStatefulWidget {
  const BuddyTrackerApp({super.key});

  @override
  ConsumerState<BuddyTrackerApp> createState() => _BuddyTrackerAppState();
}

class _BuddyTrackerAppState extends ConsumerState<BuddyTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached || 
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      
      // Stop the tracking loop
      ref.read(trackingServiceProvider).stopTracking();
      
      // Reset the tracking UI state globally
      ref.read(activeTrackingTargetProvider.notifier).state = null;
      
      // We don't automatically pop the router here; the go_router could be configured
      // to redirect, or the active_tracking_screen could listen to activeTrackingTargetProvider 
      // and pop if it becomes null. For Phase 8, ensuring the tracking loop stops and 
      // state is reset is the hard rule.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Buddy Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
