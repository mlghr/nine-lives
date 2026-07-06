# Codex Dev Prompt — "Nine Lives" (Milestone 1)

You are building a 3D Godot game called "Nine Lives" (working title). Repo: `https://github.com/mlghr/nine-lives.git`, base branch `main`. Godot 4.6.2 (stable), GDScript, Forward+ rendering, Jolt Physics (already set in `project.godot`). The project is currently an empty scaffold. Read `docs/game-design-brief.md` before doing anything — it is the design source of truth. `docs/prompts/blender-asset-prompt.md` describes the future art pipeline; you only need it for proxy proportions.

## How you are being run

You run in Codex cloud, one **work item** per task. The work items are numbered below and are strictly sequential. Each run:

1. The user tells you which work item to do (e.g. "Work item 3"). Do exactly that item — nothing from later items.
2. Assume all previous items are merged into `main`. If files a previous item should have created are missing, stop and report it; do not recreate them.
3. Produce one branch / one PR per item. Branch name: `feature/m1-<nn>-<short-name>` (e.g. `feature/m1-02-player-controller`).
4. End every PR description with three sections: **What was added**, **Placeholders** (art, sound, tuning), and **Decisions needing sign-off** (see rule 3 below).

Codex environment setup should run `bash scripts/setup-codex-godot.sh` before the task starts. That script installs Godot 4.6.2 on Linux Codex containers and exposes it as `godot` for validation.

## Non-negotiable rules

1. **Scene files are the source of truth.** You have no Godot editor, but everything must exist as editor-editable files: scenes as `.tscn`, resources as `.tres`, written directly in Godot's text format. Never construct an object graph at runtime — no `Node3D.new()` + `add_child()` chains, no meshes or collision shapes built in scripts. Scripts *drive and configure* nodes that exist in scene files; dynamic spawning (projectiles, enemies) instances a `PackedScene` that itself is a real `.tscn`. This applies to the player, every enemy, every UI screen, every ability effect, every level.
2. **Tunable data lives in custom Resources, not code.** Enemy stats, ability parameters (cooldown, damage, durations), player movement/combat numbers: define `class_name ... extends Resource` scripts with `@export` fields, save instances as `.tres`, and reference those from scenes. No hardcoded gameplay constants or config dictionaries in scripts. Use `@export` on node scripts for per-instance tuning so the owner can tweak in the Inspector.
3. **Never block on questions — surface them.** You can't have a back-and-forth mid-run. Where the brief doesn't pin a decision down, pick the conservative option, expose it as an `@export` tunable where possible, and list it under **Decisions needing sign-off** in the PR. Anything expensive to redo (camera feel, control mapping, animation-facing assumptions) must appear there even if you implemented a default.
4. **Developer experience is a first-class goal.** Consistent folder structure (below), clear node names (no `Node3D2`), comments where behavior isn't obvious from the scene tree, patterns a future contributor can extend without reading every script.
5. **Milestone 1 only.** Hallway hub + Living Room, upright vacuum + robot vacuum, full universal kit, Hairball. Do not build other wings, enemies, or abilities. After work item 7, stop and wait for approval.

## Authoring Godot 4.6 text formats (no editor available)

- `.tscn` header: `[gd_scene load_steps=N format=3]`; `.tres`: `[gd_resource type="Resource" script_class="..." load_steps=N format=3]`. Keep `load_steps` = number of ext/sub resources + 1.
- **Never fabricate `uid://` values.** Omit the `uid` attribute on `ext_resource` entries and reference by `path="res://..."` — Godot loads by path and assigns UIDs when the owner next saves in the editor. Do not hand-create `.uid` sidecar files; the editor generates them.
- Use only node types valid in Godot 4.6 (`CharacterBody3D`, `AnimationPlayer`, `Area3D`, `NavigationAgent3D`, ...). No Godot 3 names.
- Every `ext_resource`/`sub_resource` needs a unique `id`; keep them short and stable (`"1_player"`, `"2_mesh"`).
- Scenes must open clean: no missing-dependency paths, no scripts referencing nodes that aren't in the scene. Double-check `node paths` in `[connection]` signal blocks.

**Validation:** if the environment's setup script has installed Godot (recommended: download `Godot_v4.6.2-stable_linux.x86_64` from godotengine/godot-builds releases), run `godot --headless --path . --import` and treat any error output as a failure to fix before opening the PR. If no binary is available, do a manual pass over every `.tscn`/`.tres` you touched against the rules above and say in the PR that validation was static only.

## Concept (short version)

House cat reclaims the house from things cats hate. One connected house+yard hub; wings gate until their blocker is dealt with. Combat = universal kit that always works (claw 3-hit combo, pounce heavy, dodge-roll, hiss-parry) + unlockable abilities (M1: Hairball ranged stagger) + a per-enemy environmental weakness that's the fast, funny alternative (vacuum: claw the cord to unplug; robot vacuum: flip it or lure it to the stairs). Health = nine lives with a stagger buffer on small hits. Art will be toon/cel-shaded; M1 uses flat-color placeholder materials on primitive proxies (`CapsuleMesh`, `BoxMesh` inside real scenes) sized to final proportions.

## Project structure

```
scenes/
  player/player.tscn
  enemies/vacuum/vacuum.tscn
  enemies/robot_vacuum/robot_vacuum.tscn
  abilities/hairball_projectile.tscn
  levels/hallway_hub.tscn
  levels/living_room.tscn
  ui/hud.tscn
scripts/            (mirrors scenes/; one script per scene unless genuinely shared)
resources/
  enemy_stats/vacuum_stats.tres, robot_vacuum_stats.tres
  abilities/hairball_data.tres
  player/player_stats.tres
assets/models|animations|materials|audio   (reserved for the Blender pipeline)
```

Adjust only with a stated reason in the PR.

## Work items

**WI1 — Structure proposal + project skeleton.** No gameplay code. Create the folder structure (with `.gitkeep` where empty), define all InputMap actions in `project.godot` (`move_forward/back/left/right`, `jump`, `attack_claw`, `pounce`, `dodge`, `hiss`, `ability_hairball`, camera look) with keyboard+mouse *and* gamepad bindings — never hard-coded key checks in scripts. Write `docs/design/scene-trees.md` proposing the full node tree for Player, Vacuum, and Robot Vacuum (node types, names, what each script owns, how hitbox/hurtbox areas are structured, how the stats `.tres` plugs in). This PR is the owner's approval gate for the architecture; later items must follow the approved doc.

**WI2 — Player movement + camera.** `player.tscn` (`CharacterBody3D`, capsule proxy at house-cat proportions), walk/run/jump with coyote time, third-person orbit camera rig (own scene or clearly separated sub-tree). All feel numbers via `player_stats.tres` / `@export`s. Camera behavior is a flagged sign-off decision.

**WI3 — Universal combat kit.** Claw 3-hit combo, pounce (leaping heavy, knockdown chance), dodge-roll with i-frames, hiss (short-range interrupt/parry). Reusable hitbox/hurtbox component scenes (`Area3D`-based). Nine-lives health + stagger buffer as a resource + component usable by player and enemies. Placeholder attack timing via `AnimationPlayer` tracks inside the scenes, not timers hardcoded in scripts.

**WI4 — Upright vacuum.** `EnemyStats` resource script + `vacuum_stats.tres`. Patrol on editor-placed path/markers, detect player, loud telegraphed charge attack. Weakness hooks: a cord node that can be clawed → unplugged (instant stagger/shutdown), and a "near water" check → comedic one-hit KO. Weakness trigger volumes are nodes in the scene, editable in the editor.

**WI5 — Robot vacuum.** Fast, low, erratic pathing (`robot_vacuum_stats.tres`). Pounce from above flips it → helpless flailing, auto-defeated after a few seconds. Can be lured off a staircase edge → defeated. Shares the hurtbox/health components from WI3.

**WI6 — Hairball + HUD.** `hairball_projectile.tscn` instanced from a `PackedScene` on cast; `hairball_data.tres` (cooldown, speed, stagger values). Interrupts/staggers enemies at range. `hud.tscn`: nine-lives display + Hairball cooldown indicator.

**WI7 — Greybox levels + integration.** `hallway_hub.tscn` + `living_room.tscn` from primitive proxies: hallway with gated doorways to future wings (visibly blocked), living room with counter/shelf platforming, vacuum patrol route, an outlet+cord setup and a water bowl (vacuum weaknesses), a staircase (robot vacuum weakness). Place both enemies, wire the main scene (living room reachable from hallway), set the run/main scene in `project.godot`. End the PR with a full Milestone 1 summary: what exists, every placeholder, and a proposed next-milestone list. Then stop.
