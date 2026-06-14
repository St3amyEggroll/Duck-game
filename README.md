# Duck-game

A Roblox game built in Luau, version-controlled via [Rojo](https://rojo.space).
The source of truth is this repository (`src/`), **not** the `.rbxl` file.

## Project layout

```
src/
├── shared/   → ReplicatedStorage.Shared   (modules used by client AND server)
├── server/   → ServerScriptService.Server (server-authoritative logic)
└── client/   → StarterPlayerScripts.Client (input, UI, camera)
```

Design principles for this project live in [`CLAUDE.md`](./CLAUDE.md).

## Getting started

1. **Install the toolchain** (Rojo, StyLua, Selene, Wally):
   ```sh
   rokit install
   ```
   Don't have Rokit? See https://github.com/rojo-rbx/rokit.

2. **Install packages** (once any are added to `wally.toml`):
   ```sh
   wally install
   ```

3. **Sync into Roblox Studio**:
   ```sh
   rojo serve
   ```
   Then connect from the Rojo plugin inside Studio. Edits to files in `src/`
   appear live in Studio.

## Development commands

| Command           | Purpose                                  |
| ----------------- | ---------------------------------------- |
| `rojo serve`      | Live-sync `src/` into Studio             |
| `rojo build -o Duck-game.rbxlx` | Build a place file from source |
| `stylua src/`     | Auto-format all Luau                     |
| `selene src/`     | Lint for bugs and bad patterns           |

## Conventions

- Every module starts with `--!strict` for type safety.
- Bootstrap scripts (`init.server.luau`, `init.client.luau`) stay thin; they
  only wire modules together.
- Server is authoritative — never trust client input.
