# VIctory Unified Build (RTX 3070 8 GB + Ryzen 5 5600XT)

Licensed under **GPL-3.0-or-later** (see `LICENSE` and `docs/asset-policy.md`).

## Attribution & Integrated Projects

1. **[VIctory](https://github.com/Marvisak/VIctory)** (Marvisak & contributors) — Upstream Xbox Series X|S compatibility runtime, PE/XVD loader, HLE services, D3D12 backend, and GFX10-to-DXIL shader recompiler.
2. **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)** — Primary codebase for this unified build:
   - Renderer Ports 1, 2, 5, 6, 7 (`VICTORY_PORT_CONSTANTS`, `VICTORY_PORT_DESCRIPTORS`, `VICTORY_PORT_CBV`, `VICTORY_PORT_GUARD`, `VICTORY_PORT_JOURNAL`)
   - Async submission, thin command recording (`VICTORY_THIN`), parallel joins (`VICTORY_JOIN_PARTS`), relay/landing (`VICTORY_RELAY`, `VICTORY_CARD_STEPS`)
   - Native resolution scaling (`VICTORY_OUTPUT=1920x1080`), unlocked frame pacing (`VICTORY_FRAME_INTERVAL_MS=16.667`), persistent texture store (`VICTORY_TEXTURE_STORE=1`), dynamic surface-light ambient stand-in (`VICTORY_AMBIENT`, `VICTORY_AMBIENT_SETTLE`)
3. **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)** — Integrated fixes and optimizations:
   - BC7 channel rotation fix (modes 4 and 5 only, upstream PR #3111) in `crates/victory-formats/src/bcpack.rs`
   - Legacy multiply-add (`v_mac_legacy_f32` / `v_mad_legacy_f32`) with `ftz` and `legacy_fmad` (PR #1026) in `crates/victory-shader/src/emit/lower.rs`
   - `VICTORY_SETTLE_ROOM=1` (2x flights in air, 8x changed runs merged) in `crates/victory-gpu/src/host.rs`
4. **[stellarr-studio/kelvaroq](https://github.com/stellarr-studio/kelvaroq)** — Hardware profiling & 8 GB VRAM budget tuning:
   - `VICTORY_TEXTURE_STAGE_MB=64`, `VICTORY_CARD_BUFFERS_MB=256`, `VICTORY_QUEUE2_LANDING_MB=32`
5. **[DexNom/VIctory](https://github.com/DexNom/VIctory)** — Shader/DXIL correctness fixes (quad neighbor sampling, cube-map explicit gradients, DXC vertex signature ordering, sparse texture range merging — already integrated in the `VIctory-7900XTX` base).
