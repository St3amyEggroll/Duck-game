# Duck-game — Project Guidelines

These are the binding development principles for this project. Apply them to all
code, reviews, and design decisions.

## Platform & Stack

- **Platform:** Roblox
- **Language:** Luau (typed Lua) — prefer `--!strict` on all modules.
- **Sync:** Rojo (filesystem ↔ Roblox Studio). Source of truth is this repo, NOT
  the `.rbxl` file.
- **Tooling:** Rojo (sync), Selene (lint), StyLua (format), Wally (packages),
  managed via Rokit.
- **Architecture:** Lightweight `ModuleScript` patterns — no heavy frameworks
  unless clearly justified. **Server-authoritative**: never trust the client.
- **Layout:** `src/shared` → ReplicatedStorage, `src/server` →
  ServerScriptService, `src/client` → StarterPlayerScripts.

## Core Principles

1. **Modular** — Separate concerns into small, focused modules (e.g. input,
   rendering, physics, entities, game state, assets). Each module owns one
   responsibility and exposes a clean interface. No god-objects, no tangled
   cross-dependencies.

2. **Efficient** — Write performant code: avoid unnecessary allocations in hot
   loops, use appropriate data structures, keep the update/render loop tight.
   Profile before optimizing, but never write knowingly wasteful code.

3. **Bug-free** — Correctness first. Handle edge cases, validate inputs, and
   prefer code that is easy to reason about. Test critical logic. Don't ship
   code that "probably works."

4. **Aligned design** — Consistent visual style, naming, and architecture
   throughout. UI/assets share a coherent design language; code follows one set
   of conventions. No mismatched patterns.

5. **No bloat** — Only build what's needed. No dead code, no speculative
   abstractions, no unused dependencies. Keep the footprint lean.

6. **Industry best practices** — Follow established game-dev and software
   conventions: clear game loop separation (input → update → render), data-driven
   design where it helps, version control hygiene, readable self-documenting code.

## Working Agreement

- Match the conventions of surrounding code when editing.
- Prefer clarity over cleverness.
- Refactor toward these principles whenever touching adjacent code.
