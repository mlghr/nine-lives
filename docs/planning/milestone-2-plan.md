# Milestone 2 Plan — "Nine Lives"

This is the approved Milestone 2 plan and the Codex execution prompt. It answers `docs/planning/milestone-2-fable-brief.md`. Baseline: `main` at PR #8 (`78cd9e8`) plus the brief commit.

## Theme

**Living Room playable loop, plus Catnip Rage and the first real Blender asset (the cat).**

Rationale: M1 built systems and a greybox slice, but nothing yet plays like a game — enemies aren't authored into an encounter, there's no objective, no failure/restart, and feel values have never been tuned. M2 closes that loop first (WI1–WI4), because every later wing inherits whatever feel and encounter patterns exist now. Two owner-approved additions ride on top: Catnip Rage as the slice's second ability (WI5), and the start of the Blender pipeline with the cat protagonist (WI7–WI8) — orange tabby, cartoon-ish proportions — so the art pipeline is validated end-to-end on one asset before the roster needs it. Kitchen wing is explicitly deferred to M3.

## How Codex is run (unchanged from M1)

One work item per task, strictly sequential; assume previous items are merged into `main`. One branch/PR per item, named `feature/m2-<nn>-<short-name>`. Every PR ends with **What was added / Placeholders / Validation / Decisions needing sign-off**. All rules in `docs/prompts/codex-dev-prompt.md` §"Non-negotiable rules" and §"Authoring Godot 4.6 text formats" still apply verbatim (editor-first scenes, tunables in `.tres` resources, InputMap only, no fabricated `uid://`, no `.uid` sidecars committed, never block on questions — surface them). Only that file's Milestone-1 scope section is superseded by this plan. Validation for every item: `godot --headless --path . --import` clean (setup: `bash scripts/setup-codex-godot.sh`), plus the item's own acceptance checks; state in the PR if validation was static-only.

## Work items

**M2-WI1 — Feel-tuning harness + debug overlay.**
Targets: `scenes/debug/debug_overlay.tscn` + `scripts/debug/debug_overlay.gd`; new InputMap actions `debug_toggle`, `debug_respawn`; `Marker3D` spawn points in `hallway_hub.tscn` and `living_room.tscn`; optional tuning preset variants of `resources/player/player_stats.tres` (e.g. `player_stats_floaty.tres`) selectable via an exported field.
Acceptance: overlay toggles at runtime showing velocity, player state, active i-frames, Hairball cooldown, and current stats resource; `debug_respawn` teleports to the nearest marker; with the overlay off, zero gameplay difference; overlay ships disabled via an exported flag on the hub.
Placeholders: plain `Label`-based UI is fine. Sign-off: which movement/camera values felt wrong during self-test — list concrete suggested changes (camera sensitivity, pitch clamp, coyote time, dodge i-frame window, pounce arc) rather than silently retuning them.

**M2-WI2 — Living Room encounter authoring.**
Targets: `scenes/levels/living_room.tscn` (rework), `scripts/enemies/vacuum/vacuum.gd` + `robot_vacuum.gd` only as needed to consume authored data.
Acceptance: upright vacuum patrols an editor-authored `Path3D`/marker route through the room's open floor; robot vacuum has authored wander bounds; both enemies leash to an encounter-bounds `Area3D` and reset rather than following the player into the hallway; outlet + cord, water bowl, staircase, counters, and shelves are restaged so each weakness is discoverable from normal play sightlines; an `Area3D` objective trigger fires a signal on first room entry and on "all blockers defeated/disabled" (consumed in WI4 — for now, emitted and logged).
Placeholders: staging uses existing proxy blocks. Sign-off: proposed room layout (include a top-down ASCII sketch in the PR).

**M2-WI3 — Combat & feedback pass.**
Targets: `scenes/effects/` (new) — one small `PackedScene` per event: claw hit, pounce impact, hiss parry, Hairball impact, player damage, stagger, cord unplug, robot flip, enemy shutdown; `AudioStreamPlayer3D` hook nodes (empty streams) at each event point; telegraph rework inside `vacuum.tscn` (charge windup: color flash + shake via `AnimationPlayer`) and `robot_vacuum.tscn` (bump windup); HUD reactions in `hud.tscn` (life-loss flash, cooldown-ready ping, in-danger state).
Acceptance: every listed event visibly reads in play; all effect scenes are instanced `PackedScene`s (no runtime-built graphs); timings live in `AnimationPlayer` tracks or exported fields; effects are cheap (`GPUParticles3D` or flat mesh flashes).
Sign-off: none expected; note any timing values changed on enemies.

**M2-WI4 — Objective, restart, and slice completion.**
Targets: `scripts/game/objective_state.gd` (`class_name` Resource) + `resources/game/living_room_objective.tres`; `scenes/game/game_manager.tscn` + script, registered as an autoload in `project.godot`; hallway gate visual/collision state change in `hallway_hub.tscn`; game-over and victory presentation in `hud.tscn`.
Acceptance: defeating/disabling both vacuums completes the living-room objective; a hallway "next wing" gate visibly changes state (stays impassable — Kitchen is M3); losing all nine lives shows game-over and cleanly restarts the slice (scene reload + state reset); clearing the room shows a victory state and returns control. No save system.
Sign-off: autoload use for the game manager (flag it explicitly — it's editor-visible via Project Settings but is a pattern choice the owner should bless).

**M2-WI5 — Catnip Rage ability.**
Targets: `scripts/abilities/catnip_rage_data.gd` + `resources/abilities/catnip_rage_data.tres` (duration, cooldown, attack-speed multiplier, damage bonus, no-flinch flag); player buff handling in `player.gd` + a rage state on the existing combat/animation setup; InputMap action `ability_catnip_rage`; HUD indicator alongside Hairball's; activation/active/expiry effect scenes following WI3 patterns.
Acceptance: during rage — faster attack timing, small damage boost, no flinch from small hits; buff ends on timer with clear feedback; cooldown starts on expiry; all numbers from the `.tres`; hiss/dodge unaffected.
Sign-off: **unlock gating.** The design brief ties Catnip Rage to Bathroom completion, which doesn't exist yet. Default: available from the start of the slice (dev-unlocked), with the gating decision deferred — implement behind a single exported `unlocked` flag so re-gating later is trivial.

**M2-WI6 — Proxy material palette + weakness visual language.**
Targets: `resources/materials/` (new) — shared `StandardMaterial3D` `.tres` palette: player, enemy, hazard, weakness-interactable (high-visibility accent), inactive/disabled, floor, wall, platform, gate-blocked, gate-cleared; applied across both levels, both enemies, and props.
Acceptance: no per-scene ad-hoc colors remain; weakness objects (cord, water bowl, stair edge) share one accent language; disabled enemies visibly read as off; gates read blocked vs cleared. Flat albedo only — the real cel shader is deferred (sign-off: confirm cel shader lands in M3).

**M2-WI7 — Blender cat model (script + export).**
Targets: `tools/blender/cat_build.py` (bpy script per `docs/prompts/blender-asset-prompt.md`: parametric values at top, header comment with tri budget and bone list); export to `assets/models/player/cat.glb`.
Spec: orange tabby, cartoon-ish — exaggerated proportions, bigger eyes and paws for readability; 3,000–8,000 tris; material slots by zone (body, belly/chest, stripes, ears, eyes, nose/paw pads) with flat colors; full armature per the asset prompt (spine, four legs, tail 4–6 bones, head/jaw, ears); animation actions covering current gameplay verbs only: idle, walk, run, pounce, claw 1–3, dodge-roll, hurt, faint, hairball-spit, rage-idle, rage-attack. 1 unit = 1 m, ~0.3 m shoulder height, origin at feet, transforms applied, clean names.
Acceptance: script runs headless (`blender --background --python tools/blender/cat_build.py` or pip `bpy`) and regenerates the `.glb` deterministically; if Blender cannot run in the Codex environment, the PR delivers the script + a documented local run command, marks the `.glb` as pending, and says so — do not hand-author a fake `.glb`.
Sign-off: stripe pattern/color values (expose as parameters), and whether animation quality is "blocking placeholder" or "keep" tier.

**M2-WI8 — Cat integration into the player scene.**
Targets: import `cat.glb`, re-save as an editable inherited scene (`scenes/player/cat_model.tscn`); swap it in for the capsule proxy inside `player.tscn`, preserving the collision shape, hitboxes, hurtbox, camera rig, and Hairball spawn exactly; wire imported animation actions into the existing `AnimationPlayer`/state handling so combat timings still come from the same tracks/resources.
Acceptance: game plays identically except visuals; no combat timing drift (compare against WI3 values); `godot --headless --import` clean; capsule proxy kept in the scene as a hidden fallback node until the owner approves deletion.
Sign-off: final look approval of the tabby in-engine; whether to delete the proxy.

**Stop after WI8.** End the final PR with a Milestone 2 summary (what exists, every remaining placeholder, proposed M3 scope — presumably Kitchen wing + broom + cel shader) and wait for approval.

## Owner questions (non-blocking, answer any time before the relevant WI)

1. Catnip Rage gating (WI5) — dev-unlocked default OK, or should the living-room victory award it?
2. Autoload game manager (WI4) — approve the pattern?
3. Cel shader — confirm deferral to M3.
4. If Blender can't run in Codex's environment (WI7): run the script locally yourself, or should WI7 set up a CI/setup-script path first?
5. Pause menu / title screen stay out of M2 unless you say otherwise.
