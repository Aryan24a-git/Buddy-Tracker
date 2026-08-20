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

Foundation: **LOCAL-FIRST + ON-DEMAND LOCATION + TEMPORARY TRACKING + DUAL TRANSPORT +
CACHED MAP + CONSENT.**

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
| SMS fallback      | Android platform APIs     | No separate API server |

Costs the user still owns: normal carrier SMS charges (if any), optional Google Play developer
fee for publishing (not required for sideloaded test APKs).

## 3. Layered Architecture

```
┌──────────────────────────────────────────────────┐
│                    UI LAYER                       │
│  Dashboard │ Map │ Search │ Buddy │ Tracking       │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                APPLICATION LAYER                   │
│  Buddy Manager │ Location Manager │ Refresh Manager │
│  Tracking Manager │ Network Manager                │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                 LOCATION ENGINE                    │
│  GPS │ Accuracy │ Speed │ Heading │ Distance        │
└──────────────────────┬────────────────────────────┘
┌──────────────────────▼────────────────────────────┐
│                TRANSPORT ENGINE                     │
│  Supabase │ SMS │ Retry │ Queue                     │
└──────────────────────┬────────────────────────────┘
              ┌─────────┴─────────┐
           Internet               SMS
              │                    │
           Supabase             Cellular
              └─────────┬─────────┘
                    Friend Device
```

## 4. Core Services & Responsibilities

- **LocationManager**: `getCurrentLocation()`, `getAccuracy()`, `getSpeed()`, `getHeading()`,
  `validateLocation()`.
- **TrackingManager**: `startTracking()`, `requestLocation()`, `scheduleNextRequest()`,
  `stopTracking()`, `handleAppLifecycle()` — owns the ~15s loop and the "minimize = stop" rule.
- **RefreshManager**: `refreshAll()`, `requestBuddyLocation()`, `updateDatabase()` — one-shot only.
- **TransportManager**: `sendLocation()`, `requestLocation()`, `selectTransport()`,
  `handleRetry()` — the single decision point for Internet vs SMS vs cache.
- **PairingManager**: `generateIdentity()`, `generateQR()`, `scanQR()`, `establishBuddy()`.

## 5. Transport Manager Decision Logic

```
                 LOCATION REQUEST
                        │
                 Internet available?
                    /          \
                  YES           NO
                   │             │
              SUPABASE      SMS available?
                                /      \
                              YES       NO
                               │         │
                              SMS      CACHE
                               └────┬────┘
                              LOCATION RESULT
```

The UI only ever calls `requestLocation(friendId)`; transport selection is fully encapsulated.

## 6. State Machine (per buddy/session)

```
CACHED LOCATION → (Refresh) → REFRESH → UPDATED → (Track Friend) → TRACKING ⟲ (~15s loop)
                                                                        │
                                                          (Stop / Background)
                                                                        ▼
                                                                     CACHED
```

## 7. Data Model

### Local database (Drift/SQLite)

Tables: `users`, `buddies`, `last_locations`, `tracking_sessions`, `pending_requests`, `settings`.

`last_locations` columns:
```
buddy_id
latitude
longitude
accuracy
timestamp
speed
heading
transport      -- 'internet' | 'sms' | 'cache'
```

### Cloud database (Supabase / Postgres)

Suggested tables: `users`, `buddy_relationships`, `latest_locations`, `tracking_sessions`.
Store only the **latest** location per user — do not persist an unbounded GPS history.

### Location object (transport payload)

```
latitude, longitude, accuracy, timestamp, speed, heading, transport, sequence
```

### SMS location packet (compact)

```
latitude, longitude, timestamp, sequence_number, accuracy, integrity_check (CRC)
```
CRC = corruption/integrity detection only, **not** authentication. Authentication relies on
cryptographic keys established during QR pairing.

## 8. Distance & Nearby Logic

- Haversine formula, Earth radius R ≈ 6,371,000 m — avoids any paid routing API.
- **Spider Sense radius: 500 meters.** Buddies beyond this remain searchable, never removed.
- Radar visual rings at 100m / 250m / 500m.

## 9. Identity, Pairing & Security Model

- Identity: `User ID, Display Name, Phone Number, Public Key, Avatar`. Local nicknames are
  private to the user who set them.
- Pairing: physical QR exchange → identity verification → buddy relationship. QR payload is
  minimal: `Protocol Version, Buddy ID, Public Key, Pairing Token` — no unnecessary sensitive data.
- Authorization: only established buddies may request location per the app's permission model.
- Tracking requires explicit user action; the tracked device must visibly indicate active sharing
  (see design.md §9 privacy indicator). No silent/hidden surveillance path may exist.

## 10. Battery & Network Strategy

```
Normal mode : no tracking → no continuous GPS → no continuous network
Refresh     : one sync → STOP
Tracking    : one update → ~15s → repeat, only while foregrounded
Background  : app minimized → STOP immediately
```
Tracking interval is a configurable constant (default ~15s) — never hardcode sub-second polling.

## 11. Offline / Map Data

- Map engine: MapLibre with OSM-compatible tiles. Cache the college campus region for offline use.
- Public OSM tile servers are not an unlimited production backend — pick a free-tier provider
  whose terms match the app's expected scale.
- Two offline cases: (a) previously cached tiles → map still renders; (b) never-cached area →
  detailed map may be unavailable; UI must communicate this rather than fail silently.

## 12. What Buddy Tracker Is / Is Not

**Is**: a consent-based buddy location-sharing system for college students, local-first, with
on-demand refresh, temporary explicit tracking, and dual transport (Internet + SMS fallback).

**Is not**: 24/7 surveillance, a hidden tracker, an emergency/disaster-response replacement, or a
system able to transmit location with zero communication path (GPS alone cannot reach another
phone — a network path, Internet or SMS, is always required for remote sharing).

## 13. What NOT to Build in V1 (strict ₹0 MVP)

Paid map APIs, Google Maps billing, Twilio, paid SMS gateways, paid VPS/databases, AI, chat,
social feed, advertising, BLE mesh, Wi-Fi Direct, satellite communication, disaster-comm features.

## 14. Development Phases (build in this order)

```
Phase 1 — Design: theme, splash, dashboard, map, cards, radar, tracking UI
Phase 2 — Local database: users, buddies, locations, tracking sessions
Phase 3 — GPS: current location, accuracy, distance, speed, heading
Phase 4 — QR pairing: generation, scanning, buddy relationship, nicknames
Phase 5 — Supabase: cloud database, realtime, location sync
Phase 6 — Refresh: refresh → location → server → map
Phase 7 — Active tracking: track → ~15s → update loop
Phase 8 — Lifecycle: foreground → tracking; background → stop
Phase 9 — SMS: internet-unavailable fallback (build & test last — most device-variable component)
```

## 15. Testing Strategy (needs ≥2 physical Android devices)

- **Test A — Internet**: both phones data ON → pairing, refresh, search, tracking, map, distance.
- **Test B — Data OFF**: phone B data OFF, SMS available → refresh, tracking, SMS fallback.
- **Test C — No comms**: data OFF + SMS unavailable → cached locations, offline map, stale-state UI.
- **Test D — Minimize**: tracking → home → tracking OFF.
- **Test E — Reopen**: open app → last location visible → tracking OFF.

## 16. Permission Strategy

Request Location and SMS permissions only when required for the feature being used, each with an
in-UI explanation of why it's needed. Never request unrelated permissions.
