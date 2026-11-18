# BotW-Native + Zelda-on-PC keyboard/mouse port

Goal: port Zelda-on-PC's mouse/keyboard support (1:1 mouse camera, keyboard actions, PC key
prompts, mouse menus) into this BotW-Native checkout.

**Where we are (2026-11-19):** phases 0–10 + map wheel zoom are done, play-tested, committed and pushed
(tilt-maze shrine not reached yet). Phase 11 (mouse in menus, action ring keys, Sort = C in menus, F1 Keys tab)
is built and committed (not pushed); the second play-test was started but no result reported yet. Next session:
ask how the play-test went (checklist in the phase 11 entry), then fix / push.

## Paths
- This repo: `D:\Compiling\BotW-Native`, based on ryderclanky/BotW-Native v0.1.2 `c24309b`.
  Remotes: `origin` = the user's fork CodeCraftPlugin/BotW-Native, `upstream` = ryderclanky (push disabled).
  Work branch `pc-controls` (tracks origin/pc-controls); `main` stays equal to upstream. Commits alternate
  between code commits (the port 38485b2, then one per phase) and "Notes: ..." commits that only touch CLAUDE.md /
  tools/pce: leave the notes commits out of any PR to upstream. Commit/push only when the user asks (they
  usually say "commit and push" after a phase is verified; keep code and notes in separate commits). PR later: `gh pr create --repo ryderclanky/BotW-Native --base main
  --head CodeCraftPlugin:<branch>` from a branch without the notes commit. Update: `git fetch upstream` +
  `git rebase upstream/main`. `BotWRecomp/` in the repo root is a stray user folder from shell launches
  without APPDATA (excluded in .git/info/exclude); leave it alone.
- Reference: https://github.com/mircea32000/Zelda-on-PC (MPL-2.0, Cemu fork). Port source is
  `src/pcedition/` (PCInput.cpp ~2.7k lines, PCCamera, PCPrompts, PCMenus, PCUI, PCKeys, PCGraphics.cpp holds the
  asm patches `[BotWPCE_MouseCamera]` / `[BotWPCE_UI]`). Last sparse clone (src/pcedition, incl. PCGraphics.cpp):
  `C:\Users\CODECR~1\AppData\Local\Temp\claude\195f6e35e45c96ac\25d0c97d-2dba-49ac-9ae3-c9b785233e56\scratchpad\zrepo`
  (temp, may be gone); re-clone into the current scratchpad if needed (`git clone --filter=blob:none --sparse`, then `sparse-checkout set
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
- Debug env: BOTW_PCE_INPUT_LOG=1 (action presses, selector open/close, gameplay camera on/off, and
  "pce camera: <names>" whenever the set of mouse-driven cameras updated in the last 150 ms changes; run.sh sets
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
  (0x02B9C950, 0x02B9C184), mouse for every other player camera (phases 7–9: aim, camera rune,
  lock-on, climbing, conversation, horse, Master Cycle, surf, sand seal, waterfall, Magnesis), `pce_gameplay_camera()`, `pce_bow_camera()`.
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
- `runtime/src/game/pc_ui.{h,cpp}` (MPL) — the [BotWPCE_UI] port (phase 11): text/screen/map/cursor/list/carousel
  hooks (table in docs/pc_hooks.md), UI state (inventory, map, title, dialog, choice...), pointer snapshot (walk of
  the shown layouts: hit areas, tabs, box cursor, map scroll), focus requests to the game's cursor manager, menu
  prompt re-targeting (A = left click, B = Esc, map/inventory hints = wheel), `pce_map_screen()`.
- `runtime/src/input/pc_menus.{h,cpp}` (MPL) — port of PCMenus.cpp, called from pc_controls `frame()` per game read:
  hover selects, click confirms, right click = B, inventory tab click (game's page jump) / page arrows / wheel
  pages / Link drag-rotate, map drag pan + click (cursor to spot, A) + wheel zoom, J = adventure log (J again
  closes), I/Tab always opens on the inventory. While a menu has the pointer, `mouse::set_pointer_mode()` releases
  the capture (cursor shown, warped to centre) and mouse buttons/wheel go only to the menus. Log (INPUT_LOG):
  "pc menus: pointer on/off (...) screens=[...]", "mouse: pointer (menu)".
- `runtime/src/input/pc_tilt.{h,cpp}` (MPL) — Motion Control pose (phase 10); `input/motion.cpp`
  `virtual_motion()` turns it into VPAD motion through its own fusion; `pad_hle.cpp` prefers it while reported.
- Also touched: `host/window.cpp` (mouse events, pc_controls apply/keys/F1, manual stick), `input/pad_hle.cpp`
  (frame()), `settings.{h,cpp}` (mouse_camera, mouse_sens, mouse_sens_y, mouse_sens_aim, mouse_invert_x/y in settings.ini; logs
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
7 Aim cameras + lock-on + camera rune — DONE (user: "everything seems to work"): scope/bow (0x02B9250C,
  0x02B92848, 0x02B92A48), rune aim (0x02B94E30, 0x02B95278, 0x02B956B0), camera rune (0x02BCED3C, 0x02BCF698),
  lock-on (0x02BF0234, skipped while Magnesis 0x020D72D0 ticked <100 ms ago). Every camera with mouse support calls
  `feed()` at its entry (pc_camera.cpp); new settings.ini key mouse_sens_aim=0.8 (zoomed cameras).
8 Climbing 0x02BEE0F8 + conversation 0x02BCB3A0 (orbit_tick: angles), horse 0x02BD2A44 + Master Cycle 0x02BDFB20
  (mount_tick: turn_eye) — DONE (user play-tested; only issue was map zoom, below). The conversation camera feeds
  with gameplay=false (it does not count as "in gameplay", so mouse buttons stay inert in dialogs).
  Map wheel zoom (added with phase 8): `runtime/src/game/pc_ui.cpp` (MPL) hooks the world map screen update
  0x02F033E0 (Zelda-on-PC PCE_MapObj) -> `pce_map_screen()`; while it is shown the wheel holds the right stick
  up/down ~167 ms per notch (max 4) instead of the category flick. Input log prints "world map shown/gone".
  Verified by the user ("yes it works").
9 Shield surf (0x02BE8B30, pitch 0x02BE8EF8, yaw 0x02BE9698), sand seal (0x02BF5ACC, 0x02BF5E80, 0x02BF65E8),
  waterfall (0x02BF8F88, yaw 0x02BF914C), Magnesis held object (action 0x020D72D0, camera rig 0x02BF02A8, object
  lead 0x02BD8AB8, distance fix 0x020D6DB0; follow speed 360 deg/s / 40 m/s like Zelda-on-PC) — DONE (user: "all working
  fine"; camera log verified too). magnet_active() = Magnesis action ticked <100 ms ago (the lock-on hook then skips). All player
  cameras now have mouse support; the phase-1 "timestamp only" entry hooks are gone.
10 Motion Control — DONE (user: scope + T, mouse up/down tilts and the wheel turns the view; a tilt-maze shrine
  not reached yet, test it when the user gets there). Mouse left/right = sideways roll, which aiming ignores (same
  as Zelda-on-PC; the user was told, kept as is). T toggles (tilt_toggle=0: hold); the mouse tilts a virtual
  GamePad, wheel = turn flat (15 deg/notch), middle click = level (Scope is suppressed for that key while on).
  `runtime/src/input/pc_tilt.{h,cpp}` (MPL) = Zelda-on-PC's pose logic (world_rotation, level_by, spring follow);
  `input::virtual_motion()` in motion.cpp runs the pose through its own copy of the Mahony fusion (bias learning
  off), pad_hle uses `pccontrols::tilt_motion()` ahead of the controller gyro. While on: cameras leave the mouse
  alone (feed() returns), selectors are off, mouse buttons work even outside a known camera. Off: levels at
  400 deg/s, then hands motion back. Settings tilt_* in pc_controls.ini (defaults used when the keys are missing;
  existing user files do not have them). Log: "pc controls: motion control on/off".
11 Mouse in menus — BUILT, first play-test found: Sort (Y) unreachable (fixed: Crouch key = Y while a menu has the
  pointer, prompt shows it) and the action ring (fixed: pc_ui hides DoCommand_00's Nt_KeyTex*/T_?_00 panes, the
  ImGui overlay draws the bound key, `pceui::hud_keys()`). Keys tab added to the F1 menu (phase 12's binding part:
  Enter = listen, Left/Right = first/second key, Esc cancel, Delete clear, Reset row; saved to pc_controls.ini at
  once; prompt glyphs in the font update after a restart). Rebuilt, waiting for the second play-test.
  Not ported: gameplay context prompts (Drop/Throw...), save/load macros, F2 GamePad view pointer mapping.
  Original plan: port [BotWPCE_UI] hooks + PCMenus/PCUI; Journal shortcut; context prompts; replaces
  the interim menu rules (mouse buttons inert, wheel = category flick); action ring. Keep the map wheel zoom
  (pc_ui.cpp) working. Zelda-on-PC: PCUI.cpp (HLE_UIScreen/UIText, ScreenVisible), PCMenus.cpp (map: wheel zoom,
  drag; inventory clicks), PCGraphics.cpp lines ~600–740 (the [BotWPCE_UI] patch list).
  Still untested from phase 5: bow selector (2) and arrow wheel while aiming (ask whether the user has a bow now).
12 Settings screen (Sonnet): mouse sensitivity/invert in the F1 overlay menu (bindings: Keys tab, done in 11).

## Known issues not caused by the port (don't chase without being asked)
- Title-screen "Continue" menu stalls ~1.4–2 s when opened: same with PC prompts on and off (A/B checked).
- Blurry text at the second Shrine of Resurrection terminal: render settings are native (1.5x of 720p on a
  1080p display); user was asked to compare with v0.1.2, no answer yet.
- The F1 overlay's top row is Frame rate; Left/Right flips 30/60 fps (settings log now records changes).

## Working with this user
- They play-test each phase; end each phase with a short "what to check" list and update this file.
- Keep explanations plain; they are not deep in the code. Ask before anything that could touch saves.
