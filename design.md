# design.md — Buddy Tracker Design System

Spider-themed tactical tracking UI. Inspired by Spider-Man's HUD language — **never** using
copyrighted logos, artwork, or fonts. Original spider-web/radar geometry only.

---

## 1. Design Feeling

Dark tactical interface + futuristic spider-sense radar + campus map as hero + glowing markers +
subtle web-line geometry. On open, the user should feel: *"This is my personal Spider-Sense for
finding my buddies around campus."* Still a serious utility, not a game/gimmick.

## 2. Color System

| Name           | Hex       | Usage |
|----------------|-----------|-------|
| Deep Black     | `#05070D` | Primary background |
| Secondary Dark | `#101722` | Cards, sheets, elevated surfaces |
| Spider Red     | `#E21B2D` | Primary accent, alerts, "TRACKING ACTIVE", stop actions |
| Web Blue       | `#1479D1` | Secondary accent, buddy markers, links |
| Electric Blue  | `#3FA9F5` | Highlights, active states, pulse rings |
| White          | `#F5F7FA` | Primary text on dark surfaces |

Exact values may be refined during implementation but must stay within this red/blue-on-black
family — no unrelated brand colors.

## 3. Typography

- Primary UI font: **Inter** or **Space Grotesk** (highly readable — names, distances, timestamps,
  settings, buttons).
- Secondary/futuristic accent font: **Rajdhani** or **Orbitron**, used sparingly for small HUD-style
  display elements (e.g. radar labels, splash logo) — never for body text or long labels.

## 4. Visual Language

- **Spider-web geometry**: subtle thin web-line patterns in empty states, backgrounds, radar
  screen, profile header, splash screen. Always subtle — never distracting from data.
- **Radar rings**: concentric circles at 100m / 250m / 500m marking the Spider-Sense boundary.
- **Tracking pulse**: selected/target marker emits a soft pulsing ring animation while tracking
  is active. Subtle, not flashy.
- **Marker animation**: never snap a marker to a new position; interpolate/animate movement over
  roughly the update interval for a smooth radar feel.

## 5. Spider-Themed UI Terminology (labels only, not technical protocol names)

| Label            | Meaning |
|------------------|---------|
| Spider Sense      | Nearby buddy detection (≤500m radar) |
| Target            | The currently selected/tracked friend |
| Signal            | The latest location response |
| Last Signal       | Timestamp of the last update |
| Tracking Active   | Active tracking session in progress |

## 6. Core Screens (reference layouts)

### Splash
Spider-web geometry background, app wordmark "🕷 BUDDY TRACKER" (using an original spider glyph,
not the Marvel logo).

### Dashboard
```
┌─────────────────────────────────────────┐
│ 🕷 BUDDY TRACKER                 ⚙     │
│ 🔍 Search targets...          ⟳        │
├─────────────────────────────────────────┤
│              CAMPUS MAP                 │
│        ◉ Rahul Mech   320m              │
│                       ● YOU              │
│    ◉ Priya   470m                       │
├─────────────────────────────────────────┤
│ SPIDER SENSE                            │
│ ● Rahul Mech        320m                │
│ ● Priya             470m                │
│ Last Sync: 10:42 PM                     │
└─────────────────────────────────────────┘
```

### Search Result Card
```
┌─────────────────────────────┐
│ 🕷 Rahul Mech               │
│ Last Signal: 3.2 km         │
│ Updated: 4 min ago          │
│     [ TRACK FRIEND ]        │
└─────────────────────────────┘
```

### Friend Profile
```
┌────────────────────────────────┐
│          🕷  RAHUL MECH        │
│ Last Signal      3.2 km        │
│ Accuracy         ±12 m         │
│ Updated          20 sec ago    │
│       [ TRACK FRIEND ]         │
│       [ VIEW PROFILE ]         │
└────────────────────────────────┘
```

### Active Tracking Screen
```
┌─────────────────────────────────────────┐
│ ← RAHUL MECH              ● TRACKING   │
├─────────────────────────────────────────┤
│                  ◉ TARGET               │
│                       ● YOU              │
├─────────────────────────────────────────┤
│ TARGET STATUS                           │
│ Distance       1.24 km                  │
│ Speed          2.1 km/h                 │
│ Accuracy       ±12 m                    │
│ Last Signal    4 sec ago                │
│ Transport      SMS                      │
│       [ ■ STOP TRACKING ]               │
└─────────────────────────────────────────┘
```

## 7. UI States (must be designed, not skipped)

- **Empty state**: no buddies yet — friendly spider-web illustration + "Add your first buddy".
- **No Signal state**: request sent, nothing received yet.
- **Offline state**: no internet and no SMS path — cached data shown, clearly labeled stale.
- **Target status / signal indicator**:
  - `ONLINE  ●●●●` — internet transport
  - `SMS     ●●○○` — SMS fallback transport
  - `STALE   ●○○○` — no fresh signal
  - Never imply bar count is a measured signal strength unless it truly is one.

## 8. Location Freshness Convention

| Age            | State      | Indicator |
|----------------|------------|-----------|
| 0–30 sec       | Fresh      | 🟢 FRESH |
| 30 sec–5 min   | Aging      | 🟡 AGING |
| >5 min         | Stale      | 🔴 STALE |

Thresholds are configurable constants. Always show the raw timestamp alongside the freshness tag.

## 9. Components

- **Buttons**: primary action = Spider Red fill (e.g. TRACK FRIEND, STOP TRACKING); secondary =
  Web Blue outline; both use the readable primary font, uppercase tracking-style labels sparingly.
- **Cards**: Secondary Dark background, thin Web Blue/Electric Blue border or glow on selection.
- **Markers**: "YOU" = white/electric blue dot; buddy = web-blue glyph; selected target = red
  pulsing ring.
- **Privacy indicator**: when the user is being tracked by someone, show a persistent, un-hideable
  "● ACTIVE — sharing location" indicator with a stop-sharing control. Never hide this state.

## 10. Accessibility & Clarity Notes

- Maintain sufficient contrast between Spider Red/Web Blue text and the Deep Black background.
- Do not rely on color alone for freshness/transport state — always pair with a text label.
- Keep spider-themed labels (Target, Signal, Spider Sense) paired with a plain-language tooltip
  or subtitle the first time a user encounters them.
