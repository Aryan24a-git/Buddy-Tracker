# code-structure.md — Buddy Tracker Project Structure

Follow this layout exactly. If a new top-level folder feels necessary, update this doc first,
then create it — don't drift silently.

## 1. Folder Tree

```
buddy_tracker/
│
├── android/
├── ios/
│
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants/        # spider-sense radius, tracking interval, freshness thresholds
│   │   ├── errors/           # typed failures (LocationError, TransportError, PairingError...)
│   │   ├── utils/            # haversine distance, formatting, id/token helpers
│   │   ├── theme/            # color system, typography, spacing, component themes
│   │   └── security/         # key generation/storage, CRC, pairing-token crypto
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── buddy.dart
│   │   ├── location.dart
│   │   └── tracking_session.dart
│   │
│   ├── database/              # Drift / local SQLite
│   │   ├── app_database.dart
│   │   ├── tables/            # users, buddies, last_locations, tracking_sessions,
│   │   │                      # pending_requests, settings
│   │   └── daos/
│   │
│   ├── services/
│   │   ├── location_service.dart    # LocationManager
│   │   ├── network_service.dart     # connectivity detection
│   │   ├── sms_service.dart         # SMS transport (Phase 9)
│   │   ├── supabase_service.dart    # Supabase client + realtime
│   │   ├── pairing_service.dart     # PairingManager (QR)
│   │   └── tracking_service.dart    # TrackingManager + TransportManager glue
│   │
│   ├── features/
│   │   ├── onboarding/        # splash, create profile, permissions
│   │   ├── dashboard/         # main console: map + spider sense list
│   │   ├── map/                # MapLibre widget, markers, camera, radar rings
│   │   ├── buddies/            # buddy list, friend profile, search
│   │   ├── pairing/            # my QR, scan QR, add-buddy flow
│   │   ├── profile/            # user profile / settings
│   │   ├── tracking/           # active tracking screen, target status card
│   │   └── radar/              # spider-sense radar visual component
│   │
│   ├── providers/              # Riverpod providers wiring services → UI
│   │
│   └── routing/                # app router / navigation
│
├── test/
│
├── assets/
│   ├── icons/
│   ├── backgrounds/            # web-geometry backgrounds
│   └── animations/
│
├── pubspec.yaml
└── README.md
```

## 2. Layer Responsibilities (mapping to architecture.md)

| Folder                | Architecture layer |
|------------------------|---------------------|
| `features/`             | UI layer |
| `providers/`            | Bridges UI ↔ Application layer |
| `services/`             | Application + Transport engine (`TransportManager` lives in `tracking_service.dart` or a dedicated `transport_manager.dart` once it grows) |
| `services/location_service.dart` | Location engine |
| `database/`             | Local persistence (Drift/SQLite) |
| `supabase_service.dart` | Cloud/Realtime transport |
| `sms_service.dart`      | SMS transport |
| `core/security/`        | Pairing keys, CRC, auth |

## 3. Naming Conventions

- Files: `snake_case.dart`. Classes: `PascalCase`. Providers: `camelCaseProvider`.
- One public widget/class per file where reasonable; keep screens under `features/<name>/screens/`
  and their widgets under `features/<name>/widgets/` if a feature grows beyond 1–2 files.
- Riverpod providers are grouped by domain: `locationProviders.dart`, `buddyProviders.dart`,
  `trackingProviders.dart` inside `providers/`.
- Constants (tracking interval, spider-sense radius = 500m, freshness thresholds) live only in
  `core/constants/` — never hardcode these values inline in widgets or services.

## 4. Key Files & Their Single Responsibility

- `main.dart` — app bootstrap, Riverpod `ProviderScope`, Supabase init, routing entry.
- `database/app_database.dart` — Drift database definition, migrations.
- `services/tracking_service.dart` — owns the tracking state machine and lifecycle hook
  (`handleAppLifecycle`) that enforces "minimize = stop."
- `services/supabase_service.dart` — Supabase client, realtime channel subscriptions, upserts to
  `latest_locations`.
- `services/sms_service.dart` — builds/parses the compact location packet, sends/receives SMS,
  CRC check (Phase 9 only — do not build early).
- `core/utils/distance.dart` — Haversine implementation, single source of truth for distance calc.

## 5. Testing Layout

`test/` mirrors `lib/` (e.g. `test/services/tracking_service_test.dart`). Prioritize unit tests for
`core/utils` (distance/freshness), `services/tracking_service.dart` (state transitions,
minimize→stop rule), and `services/transport` selection logic — these are the rules most likely to
regress silently.

## 6. What Not to Add

No `lib/widgets_global/` dumping ground, no business logic inside `features/*/screens` files
(keep it in services/providers), no direct Supabase/Drift calls from widgets — always go through a
provider.
