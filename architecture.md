# architecture.md — Buddy Tracker System Architecture

## 1. Guiding Priority Order

```
1. Consent
2. Privacy
3. Reliability
4. Low battery consumption
5. Low network usage
6. Offline resilience
7. Spider-themed experience
```

Foundation: **LOCAL-FIRST + CONTINUOUS ONLINE TRACKING + LAST-KNOWN CACHING +
CONSENT.**

## 2. Technology Stack

| Layer            | Technology                | Cost |
|-------------------|---------------------------|------|
| App               | Flutter                   | ₹0 |
| Language          | Dart                      | ₹0 |
| State management  | Riverpod                  | ₹0 |
| Local database    | Drift + SQLite            | ₹0 |
| Backend           | Supabase Free tier        | ₹0 within limits |
| Cloud database    | PostgreSQL (via Supabase) | ₹0 within limits |
| Realtime          | Supabase Realtime         | ₹0 within limits |
| Map engine        | MapLibre                  | ₹0 |
| Map data          | OSM-compatible source     | ₹0 at appropriate free usage |
| QR                | Flutter packages          | ₹0 |
| GPS               | Android platform APIs     | ₹0 |
| Connectivity      | connectivity_plus         | ₹0 |

Costs the user still owns: optional Google Play developer fee for publishing
(not required for sideloaded test APKs).

## 3. Layered Architecture

```
┌──────────────────────────────────────────────────┐
│                    UI LAYER                       │
│  Dashboard │ Map │ Search │ Buddy │ Settings       │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                APPLICATION LAYER                   │
│  Buddy Manager │ Location Manager │ Refresh Manager │
│  Tracking Manager │ Connectivity Manager           │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                 LOCATION ENGINE                    │
│  GPS │ Accuracy │ Speed │ Heading │ Distance        │
│  Position Stream │ (0,0) Guard                      │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                TRANSPORT ENGINE                     │
│  Supabase │ Retry │ Cache                           │
└──────────────────────┬────────────────────────────┘
                    Internet
                       │
                    Supabase
                       │
                  Friend Device
```

## 4. Core Services & Responsibilities

- **LocationManager**: `getCurrentLocation()`, `getPositionStream()`,
  `getAccuracy()`, `getSpeed()`, `getHeading()`, `validateLocation()`.
  Guards against (0,0) coordinates from GPS failure.
- **TrackingManager**: `startSharing()`, `stopSharing()`, `subscribeToBuddy()`.
  Owns the continuous location broadcast loop. Runs as foreground service for
  background operation.
- **RefreshManager**: `refreshAll()`, `requestBuddyLocation()`,
  `updateDatabase()` — one-shot sync.
- **TransportService**: `sendLocation()`, `requestLocation()` — internet-only
  transport to Supabase. When offline, locations are cached locally.
- **ConnectivityService**: Monitors network state. On disconnect → cache mode.
  On reconnect → resume cloud sync.
- **PairingManager**: `generateIdentity()`, `generateQR()`, `scanQR()`,
  `establishBuddy()` — instant mutual pairing, no pending/accept flow.

## 5. Transport Decision Logic

```
               LOCATION UPDATE
                      │
               Internet available?
                  /          \
                YES           NO
                 │             │
            SUPABASE        CACHE
                 │         (last-known)
            LOCATION RESULT
```

When connectivity returns, cached location is synced to cloud automatically.

## 6. State Machine (per buddy/session)

```
CACHED LOCATION → (Refresh) → REFRESH → UPDATED → (Continuous) → SHARING ⟲ (~15s loop)
                                                                       │
                                                         (Stop via Settings)
                                                                       ▼
                                                                    CACHED
```

## 7. Data Model

### Local database (Drift/SQLite)

Tables: `users`, `buddies`, `last_locations`, `tracking_sessions`, `settings`.

`last_locations` columns:
```
buddy_id
latitude
longitude
accuracy
timestamp
speed
heading
transport      -- 'internet' | 'cache'
```

### Cloud database (Supabase / Postgres)

Tables: `users`, `buddy_relationships`, `latest_locations`, `tracking_sessions`,
`notifications`.
Store only the **latest** location per user — do not persist an unbounded GPS history.

### Location object (transport payload)

```
latitude, longitude, accuracy, timestamp, speed, heading, transport, sequence
```

## 8. Distance & Nearby Logic

- Haversine formula, Earth radius R ≈ 6,371,000 m — avoids any paid routing API.
- **Spider Sense radius: 500 meters.** Buddies beyond this remain searchable, never removed.
- Radar visual rings at 100m / 250m / 500m.

## 9. Identity, Pairing & Security Model

- Identity: `User ID (6-char short code), Display Name, Public Key`.
  Local nicknames are private to the user who set them.
- Pairing: physical QR exchange OR manual ID entry → **instant mutual link**.
  Both directions created atomically. Informational in-app notification sent
  ("X added you as a buddy"). No pending/accept flow.
- QR payload: `Protocol Version, Buddy ID, Public Key, Pairing Token`.
- Authorization: only established buddies may see location.
- Privacy indicator: when sharing location, show a persistent, un-hideable
  "● ACTIVE — sharing location" indicator with a stop-sharing control.

## 10. Battery & Network Strategy

```
Normal mode : no tracking → no continuous GPS → no continuous network
Refresh     : one sync → STOP
Sharing ON  : continuous ~15s updates via foreground service (background OK)
Sharing OFF : app not broadcasting → cached data only
Offline     : last-known location cached, marked STALE, synced on reconnect
```
Tracking interval is a configurable constant (default ~15s).

## 11. Offline / Map Data

- Map engine: MapLibre with OSM-compatible tiles. Cache the college campus region.
- Two offline cases: (a) cached tiles → map still renders; (b) never-cached area →
  detailed map may be unavailable; UI must communicate this.
- When a buddy goes offline, their last-known location is cached locally and
  displayed with freshness indicators (FRESH/AGING/STALE).

## 12. What Buddy Tracker Is / Is Not

**Is**: a consent-based buddy location-sharing system for college students,
local-first, with on-demand refresh, continuous tracking with foreground service,
and internet transport with last-known caching for offline resilience.

**Is not**: 24/7 surveillance, a hidden tracker, an emergency/disaster-response
replacement, or a system able to transmit location with zero communication path.

## 13. What NOT to Build in V1 (strict ₹0 MVP)

Paid map APIs, Google Maps billing, Twilio, paid SMS gateways, paid VPS/databases,
AI, chat, social feed, advertising, BLE mesh, Wi-Fi Direct, satellite communication,
disaster-comm features, SMS fallback transport.

## 14. Development Phases (build in this order)

```
Phase 1 — Design: theme, splash, dashboard, map, cards, radar, tracking UI
Phase 2 — Local database: users, buddies, locations, tracking sessions
Phase 3 — GPS: current location, accuracy, distance, speed, heading
Phase 4 — QR pairing: generation, scanning, instant mutual buddy relationship
Phase 5 — Supabase: cloud database, realtime, location sync
Phase 6 — Refresh: refresh → location → server → map
Phase 7 — Continuous tracking: foreground service → ~15s → update loop
Phase 8 — Lifecycle: foreground service keeps running in background
Phase 9 — Connectivity: last-known caching, online/offline state management
```

## 15. Testing Strategy (needs ≥2 physical Android devices)

- **Test A — Internet**: both phones data ON → pairing, refresh, search, tracking, map.
- **Test B — Data OFF**: phone B data OFF → cached locations, stale-state UI.
- **Test C — Background**: tracking → home → verify foreground service keeps running.
- **Test D — Reopen**: open app → last location visible, sharing state preserved.
- **Test E — Stop Sharing**: toggle off in Settings → verify location stops broadcasting.

## 16. Permission Strategy

Two-step location permission request:
1. First: `ACCESS_FINE_LOCATION` — for basic GPS functionality.
2. Second: `ACCESS_BACKGROUND_LOCATION` — for foreground service background tracking.

Each permission request includes an in-UI explanation of why it's needed.
`FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` declared in manifest.
