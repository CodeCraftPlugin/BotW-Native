# BotW-Native + Zelda-on-PC keyboard/mouse port

Goal: port Zelda-on-PC's mouse/keyboard support (1:1 mouse camera, keyboard actions, PC key
prompts, mouse menus) into this BotW-Native checkout. Phases 0–6 are done (see the status list at the bottom);
next up is phase 7.

## Paths
- This repo: `D:\Compiling\BotW-Native` (clone of ryderclanky/BotW-Native, v0.1.2 `c24309b`).
  **All port work is uncommitted** on `main` (the user has not asked for a commit yet). `BotWRecomp/` in the
  repo root is a stray user folder from shell launches without APPDATA; leave it alone.
- Reference: https://github.com/mircea32000/Zelda-on-PC (MPL-2.0, Cemu fork). Port source is
  `src/pcedition/` (PCInput.cpp ~2.7k lines, PCCamera, PCPrompts, PCMenus, PCUI, PCKeys, PCGraphics.cpp holds the
  asm patches `[BotWPCE_MouseCamera]` / `[BotWPCE_UI]`). A sparse clone may exist in an old session scratchpad;
  re-clone into the scratchpad if needed (`git clone --filter=blob:none --sparse`, then `sparse-checkout set
  src/pcedition bin/resources/pcedition`). Put the MPL notice on any file derived from it.
- Game (v1.5.0 / v208, USA + DLC): `D:\Games\Netendo\Decrepted\Combined\BotW-Native game`
  (U-King.rpx sha256 ba58da5b...34d30, matches). Never copy files out of it (generated, modified copies in the
  user folder, like pc_prompts, are the agreed exception).
- User's untouched release: `D:\Games\BotW-Native-v0.1.2` (do not modify).
- Saves/settings/log: `%APPDATA%\BotWRecomp` = `C:\Users\CodeCraft\AppData\Roaming\BotWRecomp` (shared with
  the release). Save backup `D:\Compiling\save-backup-20261118` is from 06:05 on 2026-11-18 and does NOT have
  the user's later play (slots 1–4).

## Build and run (MSYS2 at D:\Apps\msys64, not on PATH)
The user wants to watch builds and runs live: run them in a Terminal panel tab (run_in_terminal), not hidden
in Bash. Scripts in `tools/pce/` (all set BOTW_USER_ROOT explicitly):
```
& .\tools\pce\msys.ps1 build_run         # incremental build, launches only if it succeeded
& .\tools\pce\msys.ps1 recompile_build   # after adding/removing a BOTW_HOOK (recompile ~70 s + build)
& .\tools\pce\msys.ps1 build             # build only
& .\tools\pce\msys.ps1 run               # launch with real saves, log also in build/pce_test.log
```
- The game must be closed before a build: a running game locks BotWRecomp.exe and the link fails with
  "Permission denied". After a build, check the exe timestamp is newer than the edit before telling the user.
- Full build ~1 h (1292 objects); incremental with one changed generated TU is a few minutes; editing
  settings.h recompiles many runtime files. Machine: 16 threads, 22 GB RAM, GTX 1650.
- An MSYS login shell started from Git Bash has no APPDATA: the exe then uses .\BotWRecomp with no saves and
  starts a NEW GAME. Always set BOTW_USER_ROOT (the scripts do).
- Do not drive the game with `--script` input for tests: getting to the title menu needs an intro/cutscene,
  and blind presses risk starting a new game (which can overwrite saves). Ask the user to play-test instead.
- Debug env: BOTW_PCE_INPUT_LOG=1 (action presses, selector open/close, gameplay camera on/off; run.sh sets
  it), BOTW_PCE_MOUSE_LOG=1 (1 s mouse summaries), BOTW_PCE_SPIN=<deg/frame> (spins main camera),
  BOTW_PCE_NO_PROMPTS=1 (GamePad prompts), BOTW_PCE_FS_LOG=1 (logs Font/RSTB file opens).
- Disassemble guest code: `python -I tools/dis.py "<game>/code/U-King.rpx" <hex addr> [count]` (MSYS shell).

## Hooking (how Zelda-on-PC maps here) — details in docs/pc_hooks.md
- Both target U-King.rpx 1.5.0, so Zelda-on-PC's guest addresses apply directly.
- `BOTW_HOOK(0xADDR) { ... }` in `runtime/src/game/*.cpp`, written at the start of a line, runs right AFTER the
  non-branch instruction at ADDR with `PPCContext* c`. Re-run tools/recompile.py after adding/removing one.
- Zelda-on-PC entry patches (`addr = b _pceXEntry` over `stwu r1,-N(r1)`) -> hook at the same addr (r3 = this
  is intact). In-body `bla` patches -> hook at the same addr, do what the cave does after the original insn.
  Set single-precision results on both `c->f[n]` and `c->ps1[n]`. A patched `bl` (0x020D6DAC) can't be hooked:
  hook the next insn. Calling a guest function from a hook: save the context, `rt_call(c, addr)`, restore
  (see guest_call_f1 in pc_camera.cpp).
- Zelda-on-PC finds UI state (menus, dialogs, which screen) through `[BotWPCE_UI]` hooks (PCE_UIText 0x03C4BA98,
  PCE_UIScreen 0x03A3EDC8, cursor/list ticks, ...). Not ported yet (phase 11). Until then "in gameplay" =
  a player camera updated in the last 150 ms (`pce_gameplay_camera()`; inventory/map/title/cutscenes = off).

## Port: files and what they do
- `runtime/src/game/pc_camera.cpp` — main camera mouse (yaw 0x02B9C950; pitch via the game's own mapping
  0x02B96758 at 0x02B9C120, added at 0x02B9C188/0x02B9C1AC), stick suppression while a selector is open
  (0x02B9C950, 0x02B9C184), entry tick hooks of the other 10 cameras (only timestamps so far; phases 7–9 add
  their rotation there), `pce_gameplay_camera()`, `pce_bow_camera()`.
- `runtime/src/input/mouse.{h,cpp}` — SDL3 relative-mode capture (focused, no F1 menu / on-screen keyboard),
  `take()` motion (camera), `take_wheel()`/`take_pressed()` (bindings), manual-mode stick nudge (0.0062 for
  120 ms after mouse motion so the game stays in manual camera mode).
- `runtime/src/input/pc_controls.{h,cpp}` — Zelda-on-PC's 40 actions, `%APPDATA%\BotWRecomp\pc_controls.ini`
  (written with defaults if missing; `enabled=0` = old keys/controls.ini). Host side `apply()` (keys, mouse
  buttons, wheel, 50 ms tap pulses); per-VPADRead `frame()` (called from pad_hle.cpp VPADRead) runs the
  selectors: hold 1–4 + mouse X, wheel, bow selector with shot cancel. Outside gameplay: mouse buttons do
  nothing, wheel = right-stick flick per notch (inventory categories). Escape = Back (B); F1 = overlay.
  `bound_key()` for the prompts.
- `runtime/src/input/pc_prompts.{h,cpp}` (MPL) — at startup rebuilds `Font/Font_US.sbfarc` with Zelda-on-PC's
  `runtime/resources/pcedition/External_00.bffnt` (copied next to the exe by CMake) with the button codes
  U+E040.. mapped to the bound keys, plus the grown RSTB entry, into `%APPDATA%\BotWRecomp\pc_prompts\`;
  served ahead of mods by `mods::set_private_override()` (coreinit/mods.cpp) — deliberately NOT the mods
  folder, so the shared v0.1.2 release does not load it. Cached by a stamp file.
- Also touched: `host/window.cpp` (mouse events, pc_controls apply/keys/F1, manual stick), `input/pad_hle.cpp`
  (frame()), `settings.{h,cpp}` (mouse_camera, mouse_sens, mouse_sens_y, mouse_invert_x/y in settings.ini; logs
  frame-rate changes), `main.cpp` (pcprompts::prepare after mods::init), `coreinit/fs.cpp` (FS log),
  `CMakeLists.txt` (font copy + install), `docs/pc_hooks.md` (full address map of the camera patches).

## Phases (status)
0 Setup — DONE
1 Hook groundwork — DONE: docs/pc_hooks.md; BOTW_PCE_SPIN test hook verified.
2 Raw mouse via SDL3 — DONE (verified: counts, wheel, buttons, capture/release on focus and F1).
3 Main camera — DONE (user: "feels right"). The v0.1.2 release drops the mouse_* settings.ini keys if it saves.
4 Keyboard actions + rebinding — DONE (verified, incl. a rebind test).
5 Gameplay extras — DONE: selectors with mouse/wheel verified; bow selector (2) and arrow wheel while aiming
  NOT yet tested (user has no bow yet). Journal (J) -> phase 11, Tilt (T) -> phase 10.
6 Key prompts — DONE except the A/X/Y/B action ring around actions ("A Take"): still Wii U letters, probably
  layout images, not font -> look at it in phase 11 with the UI hooks. Inventory wheel = categories verified.
7–9 Other camera modes in 3 batches (Opus) — NEXT. Hooks + HLE behaviour per docs/pc_hooks.md and Zelda-on-PC
  PCInput.cpp HLE_*CamTick / HLE_Aim* / HLE_Surf* / HLE_Magnet* (~lines 480–1060). Suggested batches:
  7 aim cameras (scope/bow 0x02B9250C, rune aim 0x02B94E30) + lock-on 0x02BF0234 + camera rune 0x02BCED3C;
  8 climbing 0x02BEE0F8, horse 0x02BD2A44, Master Cycle 0x02BDFB20, conversation 0x02BCB3A0;
  9 shield surf 0x02BE8B30, sand seal 0x02BF5ACC, waterfall 0x02BF8F88, Magnesis 0x020D72D0 (+ 0x02BF02A8,
  0x02BD8AB8, 0x020D6DB0). Main camera already drops pending mouse motion when another camera runs.
10 Motion shrines (Sonnet): TiltMode/TiltLevel (bindings exist, marked "not yet").
11 Mouse in menus (Opus): port [BotWPCE_UI] hooks + PCMenus/PCUI; Journal shortcut; context prompts; replaces
  the interim menu rules (mouse buttons inert, wheel = category flick); action ring.
12 Settings screen (Sonnet): mouse sensitivity/invert + bindings in the F1 overlay menu.

## Known issues not caused by the port (don't chase without being asked)
- Title-screen "Continue" menu stalls ~1.4–2 s when opened: same with PC prompts on and off (A/B checked).
- Blurry text at the second Shrine of Resurrection terminal: render settings are native (1.5x of 720p on a
  1080p display); user was asked to compare with v0.1.2, no answer yet.
- The F1 overlay's top row is Frame rate; Left/Right flips 30/60 fps (settings log now records changes).

## Working with this user
- They play-test each phase; end each phase with a short "what to check" list and update this file.
- Keep explanations plain; they are not deep in the code. Ask before anything that could touch saves.
