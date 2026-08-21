import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'routing/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:buddy_tracker/services/supabase_service.dart';

/// Buddy Tracker — app bootstrap.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment credentials from .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  // Initialize Supabase with loaded credentials
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://xmjumotmtmrisfhhvbhn.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await SupabaseService.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('✓ Supabase initialized successfully with live backend');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

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
    // Note: With continuous background tracking via foreground service,
    // we do NOT stop sharing when the app is backgrounded.
    // The foreground service keeps location updates running.
    // Only explicitly stopping via Settings toggle or the privacy indicator
    // will stop sharing. This is the new design per architecture.md.
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
