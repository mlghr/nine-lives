# Milestone 2 Planning Brief for Fable

This file is a handoff prompt for planning Milestone 2 of **Nine Lives**. It should be read together with:

- `docs/game-design-brief.md`
- `docs/design/scene-trees.md`
- `docs/prompts/codex-dev-prompt.md`
- `docs/prompts/fable-dev-prompt.md`
- `docs/prompts/blender-asset-prompt.md`

Milestone 1 is complete and merged into `main` through PR #8, commit `78cd9e870b2726820381214f205912ab7f5fdb90`.

## What Milestone 1 Built

The current project is a playable greybox vertical slice foundation:

- `project.godot` has `res://scenes/levels/hallway_hub.tscn` configured as the main scene.
- `scenes/levels/hallway_hub.tscn` contains the player, HUD, blocked future-wing doorways, and an instanced living room.
- `scenes/levels/living_room.tscn` contains greybox floor/walls, counter and shelf platforming blocks, staircase, water bowl weakness volume, outlet proxy, upright vacuum, and robot vacuum.
- `scenes/player/player.tscn` contains the cat proxy, movement/camera rig, combat hitboxes, hurtbox, health component, Hairball spawn, and placeholder combat animation tracks.
- Reusable combat components exist under `scenes/components/` and `scripts/components/`: hitbox, hurtbox, and health.
- Upright vacuum exists with patrol/chase/charge behavior, cord unplug weakness, water weakness, health, and hurtbox.
- Robot vacuum exists with erratic movement, bump attack, top-pounce flip weakness, stair-fall weakness, health, and hurtbox.
- Hairball ability exists as data, projectile scene, projectile script, player cast path, cooldown signal, and HUD cooldown indicator.
- HUD shows lives and Hairball cooldown state.

All M1 scenes and resources were authored as editor-visible `.tscn` / `.tres` files. Godot headless import and a small main-scene smoke test passed before WI7 was merged.

## Non-Negotiable Constraints to Preserve

Milestone 2 should continue the same project rules:

- Keep scenes/resources editor-first. Do not build persistent object graphs with `Node3D.new()` plus `add_child()` in scripts.
- Runtime spawning is allowed only by instancing real `PackedScene` assets, such as projectiles or reusable effects.
- Gameplay tuning belongs in exported fields and custom `.tres` resources, not hardcoded constants or config dictionaries.
- Use Godot InputMap actions, not direct key checks.
- Omit `uid://` values in hand-authored `.tscn` / `.tres` files, and do not commit `.uid` sidecars.
- Keep one branch and one PR per implementation work item.
- PR descriptions should continue to call out what was added, placeholders, validation, and decisions needing sign-off.
- Validation should run `godot --headless --path . --import` when Godot is available.

## Current Placeholders and Known Gaps

Milestone 1 intentionally leaves these rough:

- Art is primitive proxy geometry with flat placeholder materials.
- No audio, VFX, title screen, pause menu, settings menu, save flow, or game-over/restart polish.
- No final navigation mesh or room-authored patrol routes.
- Enemy patrol routes are mostly scene-local/default rather than carefully authored in the living room.
- Camera and movement values have not had real in-editor feel tuning.
- Combat animations are placeholder `AnimationPlayer` timing tracks, not final animation.
- Hit reactions and enemy telegraphs are functional but low-feedback.
- HUD is functional but visually plain.
- Future wing doorways are simple blocked barriers.
- No collectibles, objective tracking, progression state, or completion gates yet.

## Decisions Needing Owner Sign-Off Before or During M2

Fable should shape Milestone 2 around these decisions:

- Whether M2 should deepen the Living Room vertical slice, or start the next wing.
- If starting the next wing, which wing is next: Kitchen, Bathroom, or Backyard.
- Whether the next ability should be Catnip Rage, Hide & Ambush, or no new ability until M1 feel is stronger.
- Whether art pass should remain greybox/proxy only, or start the Blender-generated asset pipeline.
- Whether M2 should prioritize player feel and combat feedback before adding content.
- Whether to introduce progression state now, such as wing gates, objective completion, and a restart/game-over loop.

## Recommended Milestone 2 Direction

Recommended scope: **Living Room polish and first playable loop**, not a full new wing yet.

Rationale: M1 created the systems and greybox slice, but the game still needs a satisfying playable loop before expanding. Tuning movement, combat readability, enemy feedback, and room-authored encounters will make later wings cheaper and better.

Suggested Milestone 2 goal:

> Turn the M1 greybox into a playable vertical-slice loop: start in the hallway, enter the living room, learn/encounter both vacuums, defeat or bypass them with universal combat or weaknesses, update objective/progression state, and return control cleanly after victory/failure.

## Candidate M2 Work Items

These are planning candidates for Fable to refine. They are not yet approved implementation instructions.

### M2-WI1: Feel-Tuning Harness and Debug UX

Add editor-visible debug/test helpers for tuning player movement, camera, combat, and enemy behavior.

Potential deliverables:

- A lightweight debug overlay or debug panel toggle.
- Exported tuning presets/resources for player and camera values.
- Optional test markers/spawn points for quick hallway/living-room iteration.
- Clear validation notes for camera sensitivity, pitch clamp, coyote time, dodge timing, pounce arc, and Hairball cooldown.

### M2-WI2: Living Room Encounter Authoring

Make the living room encounter intentional instead of merely populated.

Potential deliverables:

- Room-authored vacuum patrol markers and robot vacuum route/behavior markers.
- Enemy leash or encounter bounds so enemies do not behave strangely around the hallway connection.
- Better placement for outlet, cord, water bowl, staircase, counters, and shelf platforming.
- Objective trigger for entering the room and defeating or disabling the blockers.

### M2-WI3: Combat and Feedback Pass

Improve readability and feel for the existing universal kit and enemy reactions.

Potential deliverables:

- Placeholder VFX scenes for claw hits, pounce impact, hiss/parry, Hairball impact, damage, stagger, unplug, flip, and shutdown.
- Placeholder audio hooks or silent event points ready for audio files.
- Clearer telegraph timing for upright vacuum charge and robot vacuum bump.
- Better HUD response for life loss, cooldown, victory, and temporary danger states.

### M2-WI4: Objective, Restart, and Slice Completion Flow

Add the minimum structure that makes the vertical slice feel complete.

Potential deliverables:

- Objective state resource or manager scene, still editor-first and small.
- Hallway gate state that changes after living-room blockers are handled.
- Restart/game-over handling when the player loses all lives.
- Simple success state for clearing the living room.
- No full save system unless the owner explicitly approves it.

### M2-WI5: Proxy Art and Material Consistency Pass

Polish proxy readability without over-investing in final assets.

Potential deliverables:

- Consistent placeholder material palette for player, enemies, interactables, hazards, blockers, floors, and walls.
- Clear visual language for weakness objects and active/inactive states.
- Optional first Blender-generated proxy asset if Fable thinks the asset pipeline should be tested now.
- Keep final art production limited unless the owner approves a dedicated asset milestone.

## Alternative M2 Direction: Kitchen Wing Start

If the owner wants expansion over polish, Fable can plan a Kitchen milestone instead. Suggested scope:

- Add Kitchen wing greybox connected to hallway.
- Add broom enemy as the new blocker.
- Add counter platforming and kitchen-specific hazards.
- Decide whether Kitchen unlocks Hairball in the larger design, or whether M1's already-unlocked Hairball means Kitchen should unlock something else later.

This path is higher risk because the existing slice has not yet had a feel/readability pass.

## Suggested Fable Output

Please produce a Milestone 2 plan with:

- One clear recommended M2 theme.
- A short rationale for that theme.
- Sequential work items with one-PR scope each.
- For each work item: target files/scenes/resources, acceptance criteria, validation expectations, placeholders, and decisions needing sign-off.
- Any owner questions that block good planning.

Keep the plan aligned with the existing scene/resource structure and avoid expanding scope beyond what can be reviewed cleanly.
