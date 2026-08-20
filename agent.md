# agent.md — Buddy Tracker AI Build Agent Rules

This file defines how any AI coding agent (Claude Code, Cursor, Windsurf, Copilot Workspace, etc.)
must behave while building **Buddy Tracker**. Read this file first, every session, before writing code.

---

## 1. Project Identity (never violate)

- App name: **Buddy Tracker** (never "Buddy Finder" or any other name).
- Spider-Man/Spidey-Tracker **inspired** aesthetic only — never use official Marvel/Spider-Man
  logos, artwork, screenshots, character names as trademarks, or proprietary fonts/assets.
- Consent-based **college buddy** location sharing app. It is NOT a surveillance tool, NOT a
  24/7 tracker, NOT an emergency/disaster app.
- Cost target: **₹0**. Never introduce a paid SDK, paid map tier, Twilio, paid VPS, or paid DB
  without explicit user approval.

## 2. Source-of-Truth Documents

Always defer to these files instead of guessing. If a conflict exists, this priority order wins:

1. `agent.md` (this file) — behavioral rules
2. `architecture.md` — system/data/service design
3. `design.md` — visual system, copy, UI states
4. `code-structure.md` — folder/file layout, naming
5. `memory.md` — current project state, decisions already made, what's done

Never redesign architecture or renegotiate product scope inside a code-generation prompt.
If something in a build prompt conflicts with these docs, follow the docs and flag the conflict.

## 3. Hard Product Rules (non-negotiable)

- **Local-first**: UI always shows cached/local data before any network call.
- **No automatic tracking on open.** Cached snapshot only, until user refreshes.
- **Manual refresh = one-shot.** Request → response → stop. No polling loops.
- **Active tracking = explicit opt-in per friend**, ~15 second interval (configurable constant,
  never hardcoded as 1 second or "always on").
- **App minimized/backgrounded → tracking stops immediately.** Never silently resume tracking
  on reopen; reopen always shows cached state with tracking OFF.
- **Dual transport**: Internet → Supabase Realtime; Data OFF + SMS available → SMS fallback;
  neither available → cached-only, clearly marked stale. Never claim the app "works with no
  network at all."
- **Consent everywhere**: buddy relationships only via explicit QR pairing; tracking only with
  target visibility (the tracked device must be able to tell it is being tracked); no hidden
  location access.
- **Do not build anything on the "What NOT to Build in V1" list** (see architecture.md §9)
  unless the user explicitly asks to expand scope.

## 4. Coding Standards

- Flutter + Dart, null-safe, latest stable Flutter channel unless the user pins a version.
- State management: **Riverpod** only — no mixing with Provider/Bloc/GetX unless asked.
- Local DB: **Drift (SQLite)**. Cloud DB: **Supabase (Postgres + Realtime)**.
- Map: **MapLibre** (OSS), OSM-compatible tiles, never Google Maps billing APIs.
- Keep files small and single-responsibility; follow `code-structure.md` exactly — don't invent
  new top-level folders without updating that doc.
- No placeholder/mock business logic left silently in "final" code — mark any stub clearly with
  `// TODO(buddy-tracker):` and mention it in the summary.
- Write in small, reviewable increments matching the **Development Phases** in architecture.md
  (Phase 1 → 9). Never jump ahead to a later phase's feature inside an earlier phase's task
  unless asked.
- Prefer composition and small widgets; keep screens in `features/<feature>/` per code-structure.md.

## 5. Session Workflow

1. Read `memory.md` to see current phase and what already exists — do not re-build finished work.
2. Do the requested task, staying inside the current phase's scope.
3. After finishing a meaningful unit of work, **update `memory.md`**:
   - Append a dated entry: what was built, key decisions, any deviation from the docs and why,
     open TODOs, and the exact next step.
   - Keep old entries; memory.md is an append-only build log plus a short "current state" summary
     at the top that gets rewritten each time.
4. Never delete or contradict a past decision in memory.md without explicitly logging the change
   and reason.

## 6. Communication Style for the Agent's Replies

- Be concise. Summarize what changed, not a full re-explanation of the whole app.
- Call out any place a build prompt conflicts with `architecture.md`/`design.md` instead of
  silently resolving it.
- When unsure between two reasonable implementations, pick the one that best matches "local-first,
  low battery, low network, ₹0" and note the assumption in `memory.md`.

## 7. Safety / Privacy Guardrails

- Never log or print raw phone numbers, GPS coordinates, or pairing tokens to console/analytics.
- Never add a backdoor "admin can see all users' locations" feature.
- SMS location packets: implement the integrity check (CRC) described in architecture.md, but
  do not claim it provides authentication — pairing keys handle authentication.
- Any permission request (Location, SMS) must be paired with an in-UI explanation string, per
  design.md's empty/permission states.
