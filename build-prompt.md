# build-prompt.md — Vibe-Coding Prompts for Buddy Tracker

Goal: build the app in an AI IDE (Claude Code, Cursor, Windsurf, etc.) using the **fewest tokens
per prompt** while keeping full quality — by pointing the agent at the doc files instead of
re-explaining the project every time, and by working one small phase at a time.

## 0. One-Time Setup (do this once, not per prompt)

1. Put `agent.md`, `design.md`, `architecture.md`, `code-structure.md`, `memory.md` in the repo
   root.
2. If your IDE supports persistent/pinned context or a rules file (e.g. `.cursorrules`,
   `CLAUDE.md`), paste `agent.md`'s content there so it's loaded automatically every session
   instead of being pasted into each prompt.
3. `flutter create buddy_tracker` and restructure `lib/` to match `code-structure.md` before the
   first real prompt (this is mechanical — do it yourself or with one prompt, see Prompt 1 below).

**Why this saves credits:** every phase prompt below is 1–3 sentences because it references files
already in context instead of restating rules, colors, or architecture. Re-explaining the project
in every prompt is the single biggest source of wasted tokens.

---

## Master Kickoff Prompt (run once)

```
Read agent.md, architecture.md, design.md, code-structure.md, memory.md in the repo root.
Follow agent.md as your operating rules for the whole project. Confirm you've loaded them,
summarize the current phase from memory.md in one line, then stop and wait for the next prompt.
```

---

## Phase Prompts (run in order, one at a time)

Each prompt assumes the agent already has the docs loaded (session-persistent context or rules
file). Do not paste the docs' content again — just reference them by name.

### Phase 1 — Design shell
```
Build Phase 1 only (see architecture.md §14): app theme from design.md's color/typography system,
splash screen, dashboard shell with placeholder map, buddy card component, spider-sense radar
component, and the active-tracking screen layout. No real data/services yet — static/mock content
is fine. Update memory.md when done.
```

### Phase 2 — Local database
```
Build Phase 2 only: Drift/SQLite schema and DAOs for users, buddies, last_locations,
tracking_sessions, pending_requests, settings — exactly as specified in architecture.md §7.
Wire it under database/ per code-structure.md. Update memory.md when done.
```

### Phase 3 — GPS
```
Build Phase 3 only: location_service.dart implementing LocationManager
(getCurrentLocation/getAccuracy/getSpeed/getHeading/validateLocation) and the Haversine distance
util in core/utils, per architecture.md §4 and §8. Update memory.md when done.
```

### Phase 4 — QR pairing
```
Build Phase 4 only: pairing_service.dart (PairingManager) plus the pairing/ feature screens
(My QR, Scan QR, Add Buddy with nickname) per architecture.md §9 and design.md's Add Buddy flow.
QR payload = protocol version, buddy ID, public key, pairing token only. Update memory.md when done.
```

### Phase 5 — Supabase
```
Build Phase 5 only: supabase_service.dart — client init, users/buddy_relationships/
latest_locations/tracking_sessions tables per architecture.md §7, and realtime subscription for
latest_locations. Update memory.md when done.
```

### Phase 6 — Refresh flow
```
Build Phase 6 only: RefreshManager (one-shot refresh: get own GPS → request buddy locations via
TransportManager → update DB → update map), wired to the dashboard refresh button, per
architecture.md §11 refresh flow. Update memory.md when done.
```

### Phase 7 — Active tracking
```
Build Phase 7 only: TrackingManager with the ~15s request loop (constant from core/constants),
wired to the Track Friend button and the tracking screen built in Phase 1. Update memory.md when done.
```

### Phase 8 — Lifecycle
```
Build Phase 8 only: enforce architecture.md's hard rule — app backgrounded/minimized immediately
stops tracking; reopening the app always shows cached state with tracking OFF. Hook into
TrackingManager.handleAppLifecycle(). Update memory.md when done.
```

### Phase 9 — SMS fallback (build & test last)
```
Build Phase 9 only: sms_service.dart implementing the compact location packet (lat, lon,
timestamp, sequence, accuracy, CRC) and TransportManager's Internet→SMS→cache fallback decision
from architecture.md §5. Note in memory.md that this needs real-device testing per
architecture.md §15 Test B/C.
```

---

## Micro-Prompts (for bug fixes / small tweaks — cheapest option)

```
In <file>, fix: <one-sentence description>. Follow agent.md rules. Don't touch other files.
Skip a memory.md update for a fix this small unless it changes a decision.
```

## Credit-Saving Rules of Thumb

- One phase per prompt — never ask for two phases at once; smaller diffs are cheaper to review
  and cheaper to regenerate if something's wrong.
- Reference docs by name, never paste their content into the prompt.
- For fixes, name the exact file — don't let the agent re-scan the whole repo.
- Ask for a diff/summary reply, not a full re-listing of unchanged files.
- Run the Master Kickoff Prompt again only if you start a fresh session with no persisted context.
