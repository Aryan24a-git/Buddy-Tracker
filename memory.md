# memory.md — Buddy Tracker Build Memory

**This file is auto-maintained by the AI coding agent.** Read it first, every session.
Update it after every meaningful unit of work per `agent.md` §5.

Structure: a rewritten **Current State** summary at the top, followed by an append-only,
dated **Build Log** below it. Never delete Build Log entries — only append.

---

## Current State (rewrite this block each update — keep it short)

- **Phase:** Phase 9 Complete (SMS Fallback)
- **Last worked on:** Phase 9 - SMS location packet encoding/decoding and fallback decision logic
- **Working / done:** UI scaffold (Phase 1). Drift local DB (Phase 2). Location/GPS engine (Phase 3). QR pairing flow (Phase 4). Supabase integration (Phase 5). Refresh system (Phase 6). Active Tracking polling loop (Phase 7). Lifecycle & background stopping (Phase 8). For Phase 9, built `SmsService` with the compact location packet string format and CRC checks. Updated `TransportService` to use an `Internet -> SMS -> cache` fallback decision tree.
- **Known issues / TODOs:** Bundled font files deferred to Phase 1b. The actual Android SMS platform integration and connectivity detection are stubbed. This implementation explicitly requires real-device testing via `architecture.md` §15 Test B (Data OFF) and Test C (No comms).
- **Next step:** Phase 1-9 are complete. Ready for real-device testing and integration of actual plugins (network, SMS).

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
- **Next step:** Wait for user instruction to begin Phase 6 (Refresh).

### 2026-08-20 — Phase 6: Refresh
- **Did:** Created `RefreshService` (`refreshAll()`, `requestBuddyLocation()`, `updateDatabase()`) and `TransportService` (`selectTransport()`, `sendLocation()`, `requestLocation()`). Grouped singleton providers into a new file `lib/providers/service_providers.dart`. Hooked up the dashboard refresh button to trigger `RefreshService.refreshAll()`.
- **Decisions:** Structured `TransportService` as the gatekeeper for network selection, returning 'internet' for now. `RefreshService` grabs local GPS via `LocationService` and pushes it to Supabase via `TransportService` when triggered.
- **Deviations:** None.
- **Files touched:** Created `lib/services/refresh_service.dart`, `lib/services/transport_service.dart`, `lib/providers/service_providers.dart`, and modified `lib/features/dashboard/screens/dashboard_screen.dart`.
- **Open TODOs:** Need to test e2e data fetching and syncing with actual Supabase DB in a real deployment scenario.
- **Next step:** Wait for user instruction to begin Phase 7 (Active Tracking).

### 2026-08-20 — Phase 7: Active Tracking Loop
- **Did:** Re-implemented `TrackingService` to include a `Timer.periodic` loop running every 15s (using `AppConstants.trackingInterval`). Wired this service into the `active_tracking_screen.dart` to start the polling loop in `initState` and stop it in `_stopTracking` (and on dispose implicitly, though handled securely in the service).
- **Decisions:** Used the existing `RefreshService.refreshAll` inside the tracking loop so we send our location and request the target's location simultaneously.
- **Deviations:** None.
- **Files touched:** Modified `lib/services/tracking_service.dart`, `lib/features/tracking/screens/active_tracking_screen.dart`, and `lib/providers/service_providers.dart`.
- **Open TODOs:** Ensure tracking session state is synchronized visually (e.g. tracking indicator on maps/dashboard).
- **Next step:** Wait for user instruction to begin Phase 8 (Lifecycle & Backgrounding).

### 2026-08-20 — Phase 8: Lifecycle Handling
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

<!--
AGENT INSTRUCTIONS (do not delete this comment block):
1. After finishing work, add a new "### YYYY-MM-DD — <short title>" entry below the last one.
2. Update the "Current State" block above to reflect the new reality.
3. If a decision changes something recorded earlier, add a new entry that says so explicitly —
   do not edit/erase the old entry.
4. Keep entries factual and short; this is a build log, not prose documentation.
-->
