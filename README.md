# Duck-game

A 2D duck combat platformer built on Roblox in Luau, version-controlled via
[Rojo](https://rojo.space). The source of truth is this repository (`src/`),
**not** the `.rbxl` file.

## Project layout

```
src/
├── shared/   → ReplicatedStorage   (modules used by client AND server)
│   ├── DuckShared/   Config, AimUtil, PixelUI, Remotes, PlaneUtil, WeaponDefs
│   ├── Maps/         Pit, Rooftops, Temple   (map data tables)
│   └── WeaponData/   Pistol, Shotgun, Sword, Grenade   (weapon data tables)
├── server/   → ServerScriptService (server-authoritative gameplay)
│   ├── MapService          builds maps from data
│   ├── RoundManager        the round/score game loop
│   ├── WeaponService       data-driven, anti-exploit weapons
│   ├── PickupService       weapon pickups
│   └── RagdollService      R6 ragdoll physics on death
└── client/   → StarterPlayerScripts (input, camera, UI, feedback)
    ├── DuckController2D     2D movement + static camera
    ├── WeaponController     aim/fire + shot rendering
    ├── RoundHud             pixel HUD + scoreboard
    └── CameraShake          trauma-based screen shake
```

Models (e.g. `ReplicatedStorage/Weapons`) and other non-script assets live in
the Studio place and are **not** managed by Rojo.

Design principles for this project live in [`CLAUDE.md`](./CLAUDE.md).

## Getting started

1. **Install the toolchain** (Rojo, StyLua, Selene, Wally):
   ```sh
   rokit install
   ```

2. **Sync into Roblox Studio**:
   ```sh
   rojo serve
   ```
   Then connect from the Rojo plugin inside Studio. Edits to files in `src/`
   appear live in Studio.

## Development commands

| Command           | Purpose                                  |
| ----------------- | ---------------------------------------- |
| `rojo serve`      | Live-sync `src/` into Studio             |
| `stylua src/`     | Auto-format all Luau                     |
| `selene src/`     | Lint for bugs and bad patterns           |

## Conventions

- Tunables live in `DuckShared/Config` — the single source of truth.
- Clean utility/data modules use `--!strict`.
- Bootstrap stays thin; gameplay logic lives in focused modules.
- Server is authoritative — never trust client input.
- Avatar rig type must be **R6** (ragdoll + gun posing depend on it).
