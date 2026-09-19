# Audit notes (2026-09-19)

Read-through audit of the code tree. Repo-hygiene items were fixed the same day
(see the bottom). Unchecked items below are **not yet fixed**. Nothing was run in the
engine, so runtime claims come from reading the code.

## High

- [x] **Potion that misses everything soft-locks the run.** Fixed: the kill zone
  now calls `Potion.fall_out()` for potions (`launcher.gd`), which emits
  `potion_shattered` with no splash, so `StateManager` leaves `POTION_ACTIVE`.
  Balls still go through `ball_lost`. Untested in the engine.

## Medium

- [ ] **`Events` signatures don't match usage.** `potion_shattered(potion: Node2D)`
  (`Events.gd:26`) is emitted with `(potion_type, position)` (`Potion.gd:56`);
  `screen_complete(next_screen)` (`Events.gd:8`) is always emitted with no args.
  Typo `balls_reminaing` at `Events.gd:18`. Check whether the 4.7 editor warns.
- [ ] **Empty ball queue hangs the level.** With no balls (empty
  `RunState.owned_balls`, or potions done and no balls) the state sits in
  `BALL_AIMING` and `game_over` never fires (`state_manager.gd:37-43, 87`).
- [ ] **Levels depend on `GameFlow` internals.** `scoring_manager.gd:19` reads
  `GameFlow.worlds[...]` directly; `current_world`/`current_screen` at
  `scoring_manager.gd:7-8` are unused. `RunState` seeds once in `_ready` and
  `start_run()` never resets it, so it will leak between runs once shop/draft
  mutate it.
- [ ] **Launch-preview constants duplicated.** `launcher.gd:11-16` hardcodes
  `impulse`, `ball_radius = 8`, `ball_bounce = 0.8`; these must match
  `ball.tscn`. Potions reuse the ball's numbers.
- [ ] **Shared water material mutated at runtime.** `potion_fluid_pool.gd:46,54`
  sets shader params on `water_shader.tres`, a shared resource in the vendored
  addon, so color/fade persist across levels. The `fade` uniform added to
  `addons/godot-rapier2d/water_shader.gdshader` will be lost on an addon update.
  Fix: `duplicate()` the material per pool; move the shader out of `addons/`.
- [ ] **Null `peg_type` guarded inconsistently.** `_refresh_visual` guards it
  (`peg.gd:120`); `_display_color` (`peg.gd:113`) and `scoring_manager.gd:25`
  don't. All 229 placed pegs currently set it, so this is latent.

## Low

- [ ] `launcher.gd:111` uses `_input`, so any left click fires, including UI
  clicks. Prefer `_unhandled_input`.
- [ ] `launcher.gd:128` sets `position` from a global position; only correct
  while the parent sits at the origin.
- [ ] Every peg (about 230/level) samples on the same 0.1 s boundary, each doing
  a `get_first_node_in_group` and a linear particle scan (`peg.gd:33-41`).
  Cache the pool ref and randomize the initial `_sample_accum`.
- [ ] `Potion._shatter` (`Potion.gd:58-61`): `hide()`, `set_deferred("freeze")`
  and disabling collision are redundant before `queue_free()`.
- [ ] `game_flow.gd` cleanup: worlds 1-3 share one level pool loaded three times
  with `load()`; `MENU_SCENE` duplicates `FIRST_SCREEN`; `_return_to_menu` is a
  dead duplicate of `return_to_menu`; debug prints at lines 81, 124, 125, 140.
- [ ] Debug prints also in `main.gd:9`, `scoring_manager.gd:41`, menu scripts.
- [ ] `Main.tscn` pre-instances a `MainMenu` that `GameFlow.begin()`
  (`main.gd:11`) immediately frees and replaces.
- [ ] Dead code: signals `Events.screen_loaded`, `game_won`, empty `# --- Run`
  section; `PegType.size`; `hud.balls_remaining`; empty `_ready`/`_process`
  stubs in `main.gd`, `game_over.gd`, `draft_menu.gd`, `shop_menu.gd`,
  `main_menu.gd`.
- [ ] Naming is mixed: `Assets`/`Scenes` (PascalCase) vs `scripts`/`sounds`/
  `types`; `Events.gd`/`Alchemy.gd` vs snake_case files;
  `scripts/class_name/` mixes Resources with nodes (`Potion`, `DeployQueue`).
  Fine on Linux, risky on case-insensitive filesystems (mac/Windows).
- [ ] No `CLAUDE.md`, README, or tests. `fluidtest.tscn` and `test_level.tscn`
  are scratch scenes in the main tree.

## Repo weight (deliberately not touched)

- `addons/godot-rapier2d/bin` is 142 MB across all platforms and `.git` is
  98 MB; export presets only cover Windows and macOS. Trimming
  android/ios/wasm/i686 or moving to LFS would help, but changes the vendored
  addon.
- Six `.kra` source files under `Assets/` aren't referenced by the game; only 3
  of 27 sounds under `sounds/Peg Hits/` are used. Left in place as source art.
- `.claude/worktrees/` is 556 MB. `potion-fade-queue` and `smooth-pool-fade`
  look already merged into `main`; verify, then `git worktree remove` them
  (both are locked).

## Not verified

Parse warnings and runtime behavior; Rapier assumptions (that `Fluid2D.points`
reflects live particle positions, and that `cast_motion` works under Rapier for
the aim preview); addon internals.

## Fixed: repo hygiene

- Unstaged the three accidentally staged `.claude/worktrees/*` gitlinks (index
  only; worktrees on disk untouched).
- Removed tracked junk: `.DS_Store` (x2), `Assets/.xdp-qt_temp.*`,
  `Assets/*.png~`, `Assets/placeholder_peg.kra~`.
- `.gitignore`: deduped `.godot/`; added `.DS_Store`, `*~`, `.xdp-qt_temp.*`,
  `.claude/worktrees/`.
