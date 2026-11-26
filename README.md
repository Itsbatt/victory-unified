# victory-unified

A unified fork by **[Itsbatt](https://github.com/Itsbatt)** (built and tuned with
**Antigravity / Google Deepmind AI** and **Kilo**) that brings together the latest
performance, shader/pipeline, and rendering work from
**[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**,
**[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**,
**[DexNom/VIctory](https://github.com/DexNom/VIctory)**,
**[Zettrox/ztrx](https://github.com/Zettrox/ztrx)** and the renderer-port line of
**[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)**,
all on top of **[Marvisak/VIctory](https://github.com/Marvisak/VIctory)**, and
tuned for an **NVIDIA RTX 3070 8 GB** on a 32 GB host.

**This repository contains no game files, code or assets.** You need your own copy
of the game. It is not affiliated with or endorsed by the game's developer or
publisher.

## What this unified fork adds

### Graphics & lighting

- **Indirect diffuse / ambient light** (`crates/victory-gpu/src/ambient.rs`,
  `VICTORY_AMBIENT=1.25`): built on `Belobug/VIctory-Belobug-AMD` (`4f45ab8`) with a
  higher `1.25` diffuse floor and a subtle hemispherical sky-to-ground tint (`±8%`)
  so daylight outdoor shadows (foliage, terrain, buildings, character clothes) keep
  readable color and depth without overexposing interiors.
- **Helper-lane quad reads** (`crates/victory-shader/src/emit/lower.rs`): ported from
  `Belobug/VIctory-Belobug-AMD` (`03629f3`) and extended with `DexNom/VIctory`
  (`921d8d3`) fast quad intrinsics (`quadReadLaneAt`/`quadOp`) and quad-local `DPP8`
  support, so pixel-shader quad operations preserve helper pixels and triangle edges
  no longer show lines on car paint, glass, and skin.
- **Shader, cubemap & PSO fixes ported from `DexNom/VIctory`** (`ddb7332`, `76749ce`,
  `5f4c3df`, `921d8d3`): uniform branching across immediate static samplers
  (`lower.rs`, +40 shader variants); restored `wave64` scalar-copy lane mask
  recognition (`structure.rs`); vertex output signature ordering by name offset,
  declared PSV interpolation, and matching unused packed PS inputs (`container.rs`,
  `emit/mod.rs`, `shader.rs`); cube-map explicit-gradient LOD fix and `CalculateLOD`
  spatial fix (`lower.rs`); integer render-target blend bypass on mixed MRTs
  (`pipeline/host.rs`, `pipeline.rs`); and depth-only pipeline pre-warming priority
  (`pipeline/make.rs`).
- **Full `fxceless/victory-fork` rendering base** (`0b0074e`): depth bounds test
  (`#82`), character bake/skin/hair texture rechecking (`VICTORY_HEAP_RECHECK`),
  first-room descriptor mirroring, `VICTORY_LEVELS_ON_DEMAND=1`, and 59/64 trace
  programs.
- **Renderer ports 1, 2, 5, 6, 7** from `avatarmanz/VIctory-7900XTX` (off by default
  while tested): `VICTORY_PORT_CONSTANTS`, `VICTORY_PORT_DESCRIPTORS`,
  `VICTORY_PORT_CBV`, `VICTORY_PORT_GUARD`, `VICTORY_PORT_JOURNAL` — reading the
  title's constants/descriptors in place, translating constant buffers to raw bytes,
  sharing the write-guard lock, and splitting the journal into 64 locked parts.

### Performance, stability & input

- **Hoisted indirect draw clamps** (`indirect.rs`, `draw.rs`, `host.rs`, `list.rs`,
  opt-in `VICTORY_HOIST_CLAMPS=7`): ported from `Belobug/VIctory-Belobug-AMD`
  (`ccab973`, `afca189`, `918ab03`, `76387c2`). Defaults to `0` (inline clamps) on
  NVIDIA `late` queues to avoid per-frame list-split stalls.
- **Texture streaming & memory-range locking** (`watch.rs`, `xmem.rs`, `texture.rs`,
  `descriptor/host.rs`): ported from `DexNom/VIctory` (`5f4c3df`, `921d8d3`).
  Per-range locks replace the global `MAPPING` lock so DirectStorage remaps do not
  block unrelated texture uploads; `O(1)` unmapped fast-path rejection in
  `mapped_bytes` avoids kernel `VirtualQuery` contention; retries alternate with
  fresh textures; full remap queues are not dropped.
- **Safe descriptor lifetime** (`crates/victory-gpu/src/descriptor/host.rs`): defers
  live shader-visible descriptor `unmake` / view-remake writes while GPU submissions
  are in flight (`crate::host::flying()`), flushing them in `Host::sweep()`
  (`flush_idle_heaps()`) once the GPU is idle. This is the fix that ended the
  recurring `nvlddmkm` `MMU Fault` crashes (see status below).
- **Tuned RTX 3070 8 GB launcher** (`scripts/play.ps1`, `Play-GTA6-RTX3070.ps1`):
  `VICTORY_DISPLAY_MODE=1920x1080`, `VICTORY_ASYNC_SUBMIT=1`, `VICTORY_QUEUE2=1`,
  `VICTORY_CARD_BUFFERS_MB=768`, `VICTORY_TEXTURE_BUDGET_MB=2560`,
  `VICTORY_PIPELINE_WAIT_MS=100`, while keeping `VICTORY_INDIRECT_WINDOW`,
  `VICTORY_HOIST_CLAMPS`, `VICTORY_TEXTURE_NO_WAIT` and `VICTORY_INPLACE` off for
  8 GB NVIDIA stability.
- **30 FPS frame cap** (`VICTORY_MAX_FPS=30` in `crates/victory-gpu/src/queue.rs`):
  caps menus/loading screens cleanly at 30 FPS.
- **Lower commit memory** (`crates/victory-gpu/src/shadow.rs`): caps the idle
  snapshot pool at `64 MiB` and drains it on tight commit memory before retrying.
- **Keyboard + XInput pad support**
  (`crates/victory-hle/src/modules/gameinput.rs`): maps `Space` alongside `Enter`
  to `A`, and keeps keyboard fallback active on slot `0` while focused even when a
  physical or virtual XInput controller (e.g. DS4Windows) is connected.
- **Paired bitcode emission** (`crates/victory-shader/src/emit/bitcode/paired.rs`,
  `paired_tests.rs`): paired-bitcode emission path for translated shaders.

## Where it stands (2026-11-26)

Tested on two machines only.

**Primary dev machine** — Windows 11, Intel i9-12900K, 64 GB RAM, Radeon RX 7900 XTX,
ray tracing off:

| | |
|---|---|
| City street, Series S profile, renderer ports 1, 2, 5, 6 and 7 on | about 45 ms a frame (about 22 fps, 44.9 ms in run merge-5) |
| Same, ports 1, 2, 5 and 6 | 45.6 ms, p95 47 ms |
| Same, ports 1, 2 and 5 | 47.3 ms (about 21 fps), p95 49 ms |
| Series X profile, ports 1+2 | about 53 ms (about 19 fps) |
| Same scene before the ports | 57–75 ms (13–17 fps) |
| Shaders the title uses that translate | all of them (25,790 of 25,985; the rest are unused geometry shaders) |
| Memory | about 30 GB private, 10.5 GB VRAM: **64 GB RAM recommended** on this GPU |

**Test machine for the unified RTX 3070 build** — Windows 11 Pro (`10.0.26300`), Ryzen
5 5600XT (6c/12t), NVIDIA RTX 3070 8 GB (driver `32.0.16.2114`), 32 GB RAM,
47.93 GB commit, Xbox Series X profile:

| Area | Verified result |
|---|---|
| Boot, menus, start screen | Works; capped at 30 fps; `Enter` / `Space` mapped to `A` |
| Progression reached | Advances past menus, opening intro, first room, into gameplay (`Player` + `SARC0015` autosave reached; ambient light active) |
| Frame time & utilization | ~2–3 fps in the open world; `344.0 ms/frame` at `8,011 draws/frame`; `425 ms` on a heavy `9,940`-draw frame under `diag` (77% GPU busy) |
| Memory footprint | `19.66–20.51 GB` commit / `15.13–15.40 GB` active RAM in-world |

### Longest crash-free session

After fixing in-flight descriptor mutation (`768735a` / `flush_idle_heaps()`), the
longest continuous run reached **~58 minutes with zero crashes**
(`19:28:28Z` → `20:25:50Z`), ending in the outdoor camp mission
(`8,011 draws/frame`, `3 fps` at `344.0 ms/frame`).

Earlier runs, before that fix, crashed with `nvlddmkm` **Event ID 13 `MMU Fault`**
(`0xf812b60` / `0x1104`, `0x887A0006`) after **49m 42s** and **49m 47s**
(`18:49:15` → `19:39:02`). The descriptor-lifetime fix above is what extended the
stable window from ~49 minutes to ~58 minutes and removed the crash in those runs.

### Known incompatibilities on the RTX 3070

- `VICTORY_ASYNC_PRESENT=1` crashed in `nvwgf2umx.dll` (kept off).
- `--console series-s` hit `0x887A0001` in `FFX_FSR4` (Series X profile used).

### Known issues

- Trees, signs and far objects flicker in the distance in some places.
- Lighting is too bright or too dark after walking indoors until the title has run
  for a while; rooms with little direct light are too dark without `-RayTracing`.
- Textures of what just came into view appear late while the title streams.
- The first run of a new build stutters while the driver makes pipelines
  (`victory warm` makes them ahead).
- Recording a frame in the world makes the title's own watchdog end it.

## How to run it

This is a layer that runs your **own** copy of the title natively on Windows. It
ships **no game files**: you supply the dump. Nothing here is affiliated with or
endorsed by the game's developer or publisher.

### 1. Prerequisites

- Windows 10/11 x64.
- A CPU with **AVX2**.
- A **Direct3D 12** GPU with **shader model 6.6** and **mesh shaders** (RTX 3070 8 GB
  is the reference tuning target; RX 7900 XTX is the primary dev card).
- **Rust** (the toolchain is pinned in `rust-toolchain.toml`; `rustup` will fetch it)
  and the **MSVC build tools** (C++ build tools + Windows SDK).
- Your own dump of the title, in a folder **outside this repository** (the tools
  refuse paths inside the repo).
- About **64 GB RAM recommended** on the 7900 XTX; the RTX 3070 8 GB build needs a
  large Windows commit (pagefile) — 2–4 GB caused OOM in `shadow::pooled`.

### 2. Configure your paths

Copy the example config and point it at your files (paths must be outside the repo):

```powershell
copy victory.example.toml victory.toml
```

Edit `victory.toml`:

```toml
[paths]
game_dir = 'D:\games\gta6-dump'      # your own dump; env: VICTORY_GAME_DIR
# cache_dir = 'D:\victory-data\cache' # default: %LOCALAPPDATA%\victory\cache
# data_dir  = 'D:\victory-data\data'  # default: %LOCALAPPDATA%\victory\data
```

`victory.toml` is git-ignored. Environment variables (`VICTORY_GAME_DIR`,
`VICTORY_CACHE_DIR`, `VICTORY_DATA_DIR`, `VICTORY_CONFIG`) take precedence over it.

### 3. Build

The launcher defaults to the `diag` build (`target\diag\victory.exe`), which is what
all measurements are taken from:

```powershell
cargo build --profile diag -p victory --features diagnostics
```

For a plain release build instead (then pass `-Build release` to the launcher):

```powershell
cargo build --release -p victory
```

### 4. (Recommended) pre-translate shaders and pipelines

Both can be stopped and resumed later. Do this once per new build / driver:

```powershell
target\diag\victory.exe shaders <the shader archives>   # every shader translated, takes minutes
target\diag\victory.exe warm --used                     # pipelines earlier runs drew with
```

### 5. Run

Run from a **normal window, not as administrator** (so the driver keeps its shader
cache elsewhere):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\play.ps1 -Exe "<path>\to\your\game_scarlett_master.exe"
```

`play.ps1` options:

| Option | Effect |
|---|---|
| `-Exe <path>` | **Required.** Path to your own copy's executable. |
| `-Safe` | Leave out the newest, faster ways. **Try this first when something is wrong.** |
| `-RayTracing` | Turn on the title's ray-traced indirect light (lit interiors, ~1/3 slower). |
| `-Build diag\|release` | Which build to launch (default `diag`). |
| `-More @{VICTORY_X='1'}` | Pass extra `VICTORY_*` settings explicitly, e.g. `-More @{VICTORY_PANEL='1'}`. |

The RTX 3070 8 GB tuning lives in `Play-GTA6-RTX3070.ps1` (same idea, 1080p +
`VICTORY_QUEUE2` + 2560 MB texture budget). `play.ps1` launches the **Series X**
profile (what the reference machine used). To use the **Series S** profile, call the
binary directly with the console flag:

```powershell
target\diag\victory.exe run "<path>\to\game_scarlett_master.exe" --execute --console series-s
```

### 6. Every switch

Every `VICTORY_...` switch is described in a comment where it is read; upstream's own
description is in [docs/README-fxceless.md](docs/README-fxceless.md). The unified
build's switches and attributions are listed in
[UNIFIED_CHANGELOG.md](UNIFIED_CHANGELOG.md).

## Credits

This is a tree of other people's work with more on top. The history is kept, and
commits taken from elsewhere name the commit and its author.

- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its contributors
  (GPL-3.0-or-later) is the base of everything here: the loader, the runtime
  services, the Direct3D 12 back end and the shader recompiler.
- **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)** —
  primary codebase for the renderer-port line (ports 1, 2, 5, 6, 7), async
  submission, thin command recording, parallel joins, relay/landing, native
  resolution scaling, unlocked frame pacing, persistent texture store and the
  dynamic surface-light ambient stand-in.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)** (`0b0074e`)
  — async submission/copy queue, plain-copy path, fast descriptor sync, depth bounds
  test (`#82`), trace shader translation, character texture recheck,
  `VICTORY_LEVELS_ON_DEMAND`, BC7 channel rotation fix (modes 4/5, PR #3111), legacy
  multiply-add (`v_mac_legacy_f32` / `v_mad_legacy_f32`, PR #1026) and
  `VICTORY_SETTLE_ROOM`.
- **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**
  (`4f45ab8`, `03629f3`, `ccab973`, `afca189`, `918ab03`, `76387c2`) — indirect
  ambient light pass (`ambient.rs` / `VICTORY_AMBIENT`), pixel-shader helper-lane quad
  reads, hoisted indirect-draw clamps (`VICTORY_HOIST_CLAMPS`), pipeline workers, and
  work by romainhedouin.
- **[DexNom/VIctory](https://github.com/DexNom/VIctory)** (`ddb7332`, `76749ce`,
  `5f4c3df`, `921d8d3`) — uniform static-sampler branching, `wave64` scalar-copy mask
  recovery, vertex signature order & interpolation validation fixes, cubemap
  explicit-LOD & `CalculateLOD` fixes, quad-op/DPP8 improvements, integer-target
  blend bypass, depth-only PSO pre-warming priority, and sparse texture range merging.
- **[Zettrox/ztrx](https://github.com/Zettrox/ztrx)** — streamlined Windows play
  script structure and defaults.
- **[stellarr-studio/kelvaroq](https://github.com/stellarr-studio/kelvaroq)** —
  hardware profiling & 8 GB VRAM budget tuning (`VICTORY_TEXTURE_STAGE_MB`,
  `VICTORY_CARD_BUFFERS_MB`, `VICTORY_QUEUE2_LANDING_MB`).
- **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**.
- **[myokex/victory-amd](https://github.com/myokex/victory-amd)** (commit `c6dc4d8`,
  adapting PR #115 by Spexivus, joroyt, and #1122 by tightfall) and **Joshua Odom**
  (`10ea38e`) — memory page guards and read-beside fixes.
- **Geckomacabre** and **cxy0072019-sketch** — the texture read-back.
- **[XCL](https://github.com/ivall/xcl)** by ivall and contributors (GPL-2.0-only) was
  used as a reference for how the same title behaves under another layer; no code of
  it is here.
- **[Itsbatt](https://github.com/Itsbatt)** & **Antigravity (Google Deepmind AI)** —
  unification, performance tuning, memory pool hardening, frame limiter, and input
  fixes in this repository. Upstream `fxceless` changes were developed with
  [Claude Code](https://claude.com/claude-code).

## License & upstream history

Licensed under **GPL-3.0-or-later** (see [LICENSE](LICENSE)). Full upstream changelog
and testing history from `fxceless/victory-fork` is preserved in
[README.upstream.md](README.upstream.md).