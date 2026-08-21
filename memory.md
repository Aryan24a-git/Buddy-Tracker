# memory.md — Buddy Tracker Build Memory

**This file is auto-maintained by the AI coding agent.** Read it first, every session.
Update it after every meaningful unit of work per `agent.md` §5.

Structure: a rewritten **Current State** summary at the top, followed by an append-only,
dated **Build Log** below it. Never delete Build Log entries — only append.

---

## Current State (rewrite this block each update — keep it short)

- **Phase:** Major Scope Change v1.0.3 (Continuous Background Tracking + SMS Removal)
- **Last worked on:** Removed SMS fallback transport tier completely across all services, models, constants, and UI. Implemented continuous online tracking with foreground service support, connectivity monitoring, and last-known location caching. Fixed Onboarding profile creation (Issue A), instant mutual pairing via QR & Manual ID (Issue B), editable nicknames (Issue C), Background location permissions & global Stop Sharing toggle in Settings & Dashboard (Issue D), and (0,0) GPS failure guard (Issue E).
- **Working / done:** Full app builds cleanly (`flutter analyze` 0 issues, all 8 unit & widget tests passing). Complete architecture, agent, design, and code-structure docs updated.
- **Known issues / TODOs:** Sideload APK to physical devices to test real-time foreground service notification & mutual background updates.
- **Next step:** Build APK or commit and release to GitHub.

---

## Build Log (append-only, newest at the bottom)

### 2026-08-20 — Phase 1: Core UI & App Scaffold
- **Did:** Created Flutter project and aligned directory structure with `code-structure.md`. Implemented `AppTheme`, `AppColors`, and `AppTextStyles`. Built the three core screens (Splash, Dashboard, Active Tracking) with static mock data. Implemented the Spider-Sense radar as a custom painter and wired up basic `go_router` navigation.
- **Decisions:** Used `google_fonts` package to serve fonts at runtime during development since we can't bundle raw binary fonts via the agent prompt right now. Added it to `pubspec.yaml`. Created `.gitkeep`-like structure for asset folders but commented them out in `pubspec.yaml` until actual assets are added to prevent Flutter build errors.
- **Deviations:** Deferred the bundling of Space Grotesk and Rajdhani `.ttf` files to Phase 1b for the reason above.
- **Files touched:** Created full `buddy_tracker/lib/` tree matching `code-structure.md` exactly, updated `main.dart`, `pubspec.yaml`, and `test/widget_test.dart`.
- **Open TODOs:** All services (database, networking, supabase, pairing, sms) are stubs with Phase-specific TODO comments.
- **Next step:** Wait for user instruction to begin Phase 2 (Drift database setup).

### 2026-08-20 — Phase 2: Local Database (Drift)
- **Did:** Implemented Phase 2 local database setup using `drift` and `sqlite3_flutter_libs`. Created schema matching `architecture.md` §7 for tables: `users`, `buddies`, `last_locations`, `tracking_sessions`, `pending_requests`, and `settings`.
- **Decisions:** Created individual DAO classes for each table to cleanly separate database access logic.
- **Deviations:** None.
- **Files touched:** `pubspec.yaml`, `lib/database/tables.dart`, `lib/database/app_database.dart`, and `lib/database/daos/*.dart`.
- **Open TODOs:** Need to wire DAOs to Riverpod providers (likely in the upcoming phases when real logic is added).
- **Next step:** Wait for user instruction to begin Phase 3 (GPS).

### 2026-08-20 — Phase 3: GPS & Location Services
- **Did:** Implemented `LocationService` with `geolocator` matching the `LocationManager` requirements from `architecture.md` §4 (`getCurrentLocation`, `getAccuracy`, `getSpeed`, `getHeading`, `validateLocation`). Confirmed Haversine formula distance util is correctly implemented in `core/utils/distance.dart` (created in Phase 1).
- **Decisions:** Defaulted to passing 'self' as `buddyId` for the `LocationModel` returned by `getCurrentLocation` since it represents the user's device. Used `LocationTransport.internet` for the default local transport as it maps best to standard LocationModel schema fields.
- **Deviations:** None.
- **Files touched:** `pubspec.yaml`, `lib/services/location_service.dart`.
- **Open TODOs:** Integration with real Riverpod state and periodic tracking intervals (Phase 7).
- **Next step:** Wait for user instruction to begin Phase 4 (QR Pairing).

### 2026-08-20 — Phase 4: QR Pairing
- **Did:** Added `qr_flutter`, `mobile_scanner`, and `uuid` to `pubspec.yaml`. Built the `PairingManager` logic in `lib/services/pairing_service.dart`. Created the 3 pairing UI screens (`my_qr_screen`, `scan_qr_screen`, `add_buddy_screen`) matching the Spider-Sense styling. Hooked these screens up to `app_router.dart` and added navigation from the Dashboard.
- **Decisions:** Used a minimal JSON format for the QR payload (`v`, `id`, `pk`, `tk`) as specified in the docs. The Add Buddy screen parses this JSON and creates a `Buddy` object containing the assigned nickname.
- **Deviations:** Turned off the `mobile_scanner` torch feature to fix a package versioning error, ensuring the build continues successfully.
- **Files touched:** `pubspec.yaml`, `lib/services/pairing_service.dart`, `lib/routing/app_router.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`, and created `lib/features/pairing/screens/*.dart`.
- **Open TODOs:** The Add Buddy screen creates the Buddy object but needs to save it using Riverpod/Drift logic in the next phases.
- **Next step:** Wait for user instruction to begin Phase 5 (Supabase Cloud).

### 2026-08-20 — Phase 5: Supabase Cloud
- **Did:** Added `supabase_flutter` to `pubspec.yaml`. Built `SupabaseService` (`lib/services/supabase_service.dart`) mapping to the tables in `architecture.md` §7: `users`, `buddy_relationships`, `latest_locations`, and `tracking_sessions`. Implemented `upsert` methods for all and a realtime `subscribeToBuddyLocation` stream.
- **Decisions:** Used standard `upsert` for all cloud insertions since they're mostly idempotently keyed. Ignored the `anonKey` deprecation warning since we're using standard `initialize` per `supabase_flutter` docs.
- **Deviations:** None.
- **Files touched:** `pubspec.yaml`, `lib/services/supabase_service.dart`.
- **Open TODOs:** We need to initialize Supabase with real URL/Keys at startup via Riverpod.

### 2026-08-20 — Phase 6: Refresh Engine & Map Integration
- **Did:** Implemented `RefreshService` combining GPS, `TransportService`, local database, and `SupabaseService`. Added `refreshServiceProvider` and wired the refresh button on `DashboardScreen`.
- **Files touched:** `lib/services/refresh_service.dart`, `lib/providers/service_providers.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`.

### 2026-08-20 — Phase 7: Active Tracking Loop
- **Did:** Implemented active tracking in `TrackingService` using `Timer.periodic(15s)` and `SupabaseService.subscribeToBuddyLocation`. Wired active tracking screen and target status card.
- **Files touched:** `lib/services/tracking_service.dart`, `lib/features/tracking/screens/active_tracking_screen.dart`.

### 2026-08-20 — Phase 8: App Lifecycle & Background Rules
- **Did:** Added `handleAppLifecycle` to `TrackingService` to safely cancel the `Timer` polling loop when backgrounded. Converted `BuddyTrackerApp` inside `main.dart` to a `ConsumerStatefulWidget` using `WidgetsBindingObserver` to watch system lifecycle changes (paused, inactive, hidden, detached). On those states, the tracking loop is stopped and `activeTrackingTargetProvider` is set to `null`. Added a Riverpod listener in `active_tracking_screen.dart` that triggers a pop to the Dashboard if the tracking target becomes null.
- **Decisions:** Put the provider mutation and lifecycle hooking at the root (`main.dart`) to ensure it intercepts regardless of which screen the user is currently looking at. 
- **Deviations:** None.
- **Files touched:** Modified `lib/services/tracking_service.dart`, `lib/features/tracking/screens/active_tracking_screen.dart`, and `lib/main.dart`.
- **Open TODOs:** The underlying GPS polling via `geolocator` will also be naturally suspended unless a background service is added (which is explicitly omitted by architecture for this app).
- **Next step:** Wait for user instruction to begin Phase 9 (SMS Fallback).

### 2026-08-20 — Phase 9: SMS Fallback
- **Did:** Created `SmsService` to handle encoding and decoding of compact location packets containing latitude, longitude, timestamp, sequence number, and accuracy, along with a CRC-16 check for data integrity (not authentication, as per design). Updated `TransportService` to use a hierarchical network decision tree: Internet first, SMS second, and finally cache (no-op). Hooked `SmsService` into Riverpod via `smsServiceProvider` in `service_providers.dart`. 
- **Decisions:** Used standard `dart:convert` for UTF-8 encoding and implemented a manual CRC-16 CCITT logic to keep the dependency footprint low. Connectivity checking is mocked out via `_isInternetAvailable` and `_isSmsAvailable` stubs to allow structured progression.
- **Deviations:** None.
- **Files touched:** Created `lib/services/sms_service.dart`, modified `lib/services/transport_service.dart`, and `lib/providers/service_providers.dart`.
- **Open TODOs:** **NEEDS REAL-DEVICE TESTING** per `architecture.md` §15 Test B (Data OFF) and Test C (No comms). Must wire up `connectivity_plus` and an SMS package like `telephony` or `background_sms` to replace the stubs.
- **Next step:** Phase 1-9 are complete. Ready for real-device deployment and testing!

### 2026-08-20 — Phase 5: Live Supabase Backend & Production Configuration
- **Did:** Configured live Supabase project `https://xmjumotmtmrisfhhvbhn.supabase.co`. Deployed schema SQL with RLS policies and Realtime publications on `latest_locations` and `tracking_sessions`. Created `.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`, added `.env*` to `.gitignore` to prevent secret leaks, and added `flutter_dotenv` to `pubspec.yaml`. Initialized Supabase in `lib/main.dart`. Created and executed `test/services/supabase_live_test.dart`, successfully verifying live round-trip CRUD operations on all 4 tables (Test A per `architecture.md` §15).
- **Decisions:** Aligned `SupabaseService` column names with Postgres table schema (`user_id`, `buddy_id`, `started_at`, `ended_at`). Used `flutter_dotenv` for configuration injection.
- **Deviations:** None.
- **Files touched:** Created `.env`, updated `.gitignore`, `pubspec.yaml`, `lib/main.dart`, `lib/services/supabase_service.dart`, `test/services/supabase_live_test.dart`, and `memory.md`.
- **Open TODOs / Manual Actions Required:**
  1. Production RLS hardening before public store release.
  2. Release signing key creation for Play Store publishing (testing currently uses debug keystore).
- **Next step:** Sideload and test on dual physical Android devices for end-to-end multi-device pairing and tracking.

### 2026-08-21 — Production Release v1.0.1: Mock Data Removal & In-App Update Engine
- **Did:** Removed all hardcoded mock buddies (Rahul, Priya, Arjun) and mock map markers. Converted `buddyListProvider` into a reactive Drift SQLite database stream (`buddyListStreamProvider`) that joins `buddies` with `last_locations`. Updated `MapPlaceholderWidget` to render dynamically based on connected buddies. Implemented `UpdateService` and `_UpdateBanner` on `DashboardScreen` querying `https://api.github.com/repos/Aryan24a-git/Buddy-Tracker/releases/latest`. Bumped version to `1.0.1+2` and pushed tag `v1.0.1` to trigger automated GitHub Actions multi-architecture APK release.
- **Decisions:** Integrated in-app update checks on app startup with direct browser APK download launching. Drift reactive stream ensures instant UI updates whenever a buddy is scanned or refreshed.
- **Deviations:** None.
- **Files touched:** `pubspec.yaml`, `lib/core/constants/app_constants.dart`, `lib/services/update_service.dart`, `lib/providers/service_providers.dart`, `lib/providers/buddy_providers.dart`, `lib/features/map/widgets/map_placeholder_widget.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`, `memory.md`.
- **Next step:** Sideload generated APK from GitHub Releases to physical phones.

### 2026-08-21 — Feature Polish: Onboarding, Nicknames, and Pairing Modes
- **Did:** Built `OnboardingScreen` providing a first-launch UI for generating the local user identity (`Users` table) and syncing it to Supabase. Enhanced `ScanQrScreen` with a manual Buddy ID entry dialogue. Differentiated pairing logic: QR scans now instantly create a mutual `accepted` relationship on both sides in Supabase, while manual ID entry creates a `pending` buddy request to prevent spam. Surfaced pending requests on the `BuddyListScreen` using a realtime Riverpod stream. Enabled local nickname overriding on `BuddyCard` by updating `BuddiesDao` with an `updateNickname` function and Drift column.
- **Decisions:** Manual IDs generate a pending relationship in `buddy_relationships` which the receiving user must explicitly accept in the UI. Accepted relationships are synced back into the local Drift database during `RefreshService.refreshAll`.
- **Deviations:** None.
- **Files touched:** Created `lib/features/onboarding/screens/onboarding_screen.dart`, updated `app_router.dart`, `splash_screen.dart`, `my_qr_screen.dart`, `scan_qr_screen.dart`, `add_buddy_screen.dart`, `buddy_list_screen.dart`, `buddy_providers.dart`, `supabase_service.dart`, `refresh_service.dart`, `users_dao.dart`, and `buddies_dao.dart`.
- **Next step:** Testing on real devices.

### 2026-08-21 — Major Scope Change v1.0.3: Continuous Background Tracking, SMS Removal & Architecture Alignment
- **Did:**
  1. **SMS Removal:** Deleted `sms_service.dart`. Rewrote `transport_service.dart` to use internet-only transport to Supabase. Removed `smsLocationPrefix` constant and `LocationTransport.sms` enum. Removed `smsServiceProvider`.
  2. **Issue A (Onboarding & Unique ID):** Fixed `OnboardingScreen` to save locally first (local-first) before syncing to Supabase, with comprehensive debug logging. Enhanced `MyQrScreen` to display user Display Name + Unique ID badge (with tap-to-copy) + QR Code.
  3. **Issue B (Instant Mutual Pairing):** Rewrote `ScanQrScreen` manual ID entry to immediately create mutual `accepted` relationships in Supabase and save to local SQLite. Removed pending-requests accept/reject UI. Added in-app notification support (`sendNotification`, `getUnreadNotifications`).
  4. **Issue C (Local Nicknames):** Verified and retained editable nickname support across `BuddiesDao`, `BuddyCard`, and `BuddyListScreen`.
  5. **Issue D (Continuous Background Location & Settings):** Added `connectivity_plus` to `pubspec.yaml`. Added `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_LOCATION` to `AndroidManifest.xml`. Built `ConnectivityService` for network state monitoring and offline caching. Rewrote `TrackingService` to manage continuous location broadcast via `getPositionStream` with Android foreground notification config. Created `SettingsScreen` with a global "Share My Location" switch, background permission request helper, and app info. Added a persistent glowing "● SHARING ACTIVE" privacy banner with a one-tap [STOP] action on `DashboardScreen`.
  6. **Issue E (Fix (0,0) GPS Bug):** Added guards against (0,0) coordinates across `getCurrentLocation`, `getPositionStream`, and `validateLocation` in `LocationService`.
  7. **Documentation Updates:** Completely updated `architecture.md`, `agent.md`, `design.md`, `code-structure.md`, and `memory.md` to reflect the new continuous online tracking architecture.
- **Decisions:** Location sharing is controlled globally through the Settings switch and the Dashboard privacy indicator banner.
- **Files touched:** Deleted `sms_service.dart`. Created `connectivity_service.dart`, `settings_screen.dart`, `core_unit_test.dart`. Modified `pubspec.yaml`, `AndroidManifest.xml`, `app_constants.dart`, `location.dart`, `tables.dart`, `location_service.dart`, `transport_service.dart`, `tracking_service.dart`, `supabase_service.dart`, `service_providers.dart`, `buddy_providers.dart`, `tracking_providers.dart`, `onboarding_screen.dart`, `my_qr_screen.dart`, `scan_qr_screen.dart`, `buddy_list_screen.dart`, `active_tracking_screen.dart`, `buddy_card.dart`, `target_status_card.dart`, `dashboard_screen.dart`, `app_router.dart`, `main.dart`, `widget_test.dart`, `architecture.md`, `agent.md`, `design.md`, `code-structure.md`, `memory.md`.
- **Validation:** `flutter analyze` passed with 0 issues. `flutter test` passed 8/8 unit and widget tests.
- **Next step:** Sideload to physical devices or release v1.0.3 to GitHub.
