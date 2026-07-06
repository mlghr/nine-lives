You are building a 3D Godot game called "Nine Lives" (working title — feel free to confirm a real title with the user early on). The project already exists at `/Users/mlghr/code/godot/cat`, Godot 4.6.2 (stable), Forward+ rendering, Jolt Physics. Right now it's an empty scaffold: just the default icon, no scenes or scripts. This document is everything you need to start; the full design brief lives at `docs/game-design-brief.md` in the project — read it first.

## Non-negotiable workflow rules

These come from the project owner's standing instructions and apply to everything you build, not just the first milestone:

1. **Editor-first, always.** Anything that can exist as a scene, node, or resource in the Godot editor must be built that way — never fabricated purely at runtime in code. If you catch yourself writing `Node3D.new()`, `add_child()` on a freshly-constructed object graph, or hand-building a mesh/collision shape in a script, stop: create a `.tscn` scene with real nodes instead, and instance that `PackedScene` from code. Code should *drive and configure* nodes that already exist and are visible/editable in the editor, not create the object graph from scratch. This applies to the player, every enemy, every UI screen, every ability effect, and every level.
2. **Data belongs in editable Resources, not code.** Enemy stats, weakness definitions, ability parameters (cooldowns, damage, buff durations), and similar tunable numbers should live in custom `Resource` scripts (`class_name EnemyStats extends Resource`, etc.) saved as `.tres` files, editable in the Inspector — not as hardcoded constants or dictionaries buried in a script.
3. **Ask before guessing.** If a gameplay decision isn't already pinned down in the design brief or this document, ask the project owner rather than picking an arbitrary answer, especially for anything that's expensive to redo (control scheme feel, camera behavior, art-facing pipeline assumptions).
4. **Git workflow:** one feature branch per work item, branch created on the remote, push when that item is done. Remote: `https://github.com/mlghr/nine-lives.git`, base branch `main`. This planning/scaffold commit lives on `docs/initial-game-design`; branch off `main` the same way for each subsequent work item.
5. You already have full read/write access to the project folder — no need to ask permission before touching files in it.
6. **Developer experience is a first-class goal**, not an afterthought. Consistent scene/folder structure, clear node names (no `Node3D2`, no leftover `KinematicBody` naming from Godot 3), comments where behavior isn't obvious from the scene tree alone, and patterns that a future contributor (human or AI) can extend without reading through every script first.

## Concept summary

Exploration-adventure: you play a house cat, one connected house-and-yard hub, wings gated behind dealing with whatever enemy blocks them. See `docs/game-design-brief.md` for full detail. The short version of combat: a universal moveset that works on every enemy (claw combo, pounce, dodge-roll, hiss-parry), an ability layer unlocked over time (Hairball ranged projectile, Catnip Rage buff, Hide & Ambush), and a per-enemy environmental weakness that's a faster, funnier alternative to slugging through the universal kit (e.g. clawing the vacuum's cord to unplug it). Art direction is toon/cel-shaded — plan for a cel-shader (custom shader or `BaseMaterial3D` unshaded + rim approach) rather than PBR realism.

Full enemy roster and the universal-kit-vs-weakness table are in the design brief — don't duplicate that table here, just implement against it.

## Milestone 1 (build this first, nothing else)

Central hallway hub + Living Room wing only. Two enemies: upright vacuum and robot vacuum. Full universal kit. One ability: Hairball. Placeholder art (see the Blender prompt companion doc, `docs/prompts/blender-asset-prompt.md`) — use primitive proxies (`CapsuleMesh`, `BoxMesh`, built as real scenes, not procedural code shapes at runtime) sized to the final proportions until real models land, so gameplay feel can be tested immediately.

Do not build the other wings, the rest of the roster, or the remaining abilities until Milestone 1 is approved.

## Before writing any code

Propose the scene tree / node structure for the Player and for the Vacuum enemy in plain text, and confirm it with the project owner. Once agreed, build it in the Godot editor as real scenes — don't skip straight to scripts.

Suggested starting structure (adjust as needed, this is a starting point not a mandate):

```
scenes/
  player/
    player.tscn
  enemies/
    vacuum/vacuum.tscn
    robot_vacuum/robot_vacuum.tscn
  abilities/
    hairball_projectile.tscn
  levels/
    hallway_hub.tscn
    living_room.tscn
  ui/
    hud.tscn
scripts/
  (mirrors the scenes above, one script per scene unless a class is genuinely shared)
resources/
  enemy_stats/
    vacuum_stats.tres
    robot_vacuum_stats.tres
  abilities/
    hairball_data.tres
assets/
  models/ animations/ materials/ audio/   (populated by the Blender pipeline)
```

## Input

Use Godot's InputMap actions (configured in Project Settings, which is itself an editor-first choice) rather than hard-coded key checks in scripts. Keeps gamepad support free and avoids a rewrite when console export becomes relevant later.

## Working style

Small, reviewable increments. After each milestone, summarize what was added, what's still a placeholder (art, sound, etc.), and what you'd tackle next — then wait for the go-ahead rather than continuing on to Milestone 2 unprompted.
