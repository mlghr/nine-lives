You are generating 3D art for "Nine Lives" (working title), a toon/cel-shaded cat-vs-household-enemies exploration game. All modeling, rigging, and animation must be done through Blender's Python API (`bpy`) in scripts — no manual modeling — so the pipeline stays scriptable, parametric, and repeatable. The companion game-development prompt (`docs/prompts/fable-dev-prompt.md`) and full design brief (`docs/game-design-brief.md`) describe the game; read those for context on how each asset is actually used.

## Target engine & import conventions

Godot 4.6.2, importing via glTF 2.0 (`.glb`). Concretely:

- Apply all transforms before export (no un-applied rotation/scale on any object).
- Scale so 1 Blender unit = 1 meter = 1 Godot unit. A house cat should end up roughly 0.3m tall at the shoulder, 0.45m nose-to-tail-base.
- Origin at the base/feet of each asset, not the geometric center — makes placement and ground-snapping predictable in the Godot editor.
- Use Blender/glTF's default forward axis (-Y) — the glTF exporter handles the Z-up-to-Y-up conversion automatically, so don't manually pre-rotate to compensate.
- Export straight into the Godot project at `assets/models/<category>/<name>.glb` (e.g. `assets/models/enemies/vacuum.glb`).
- Name objects, armatures, bones, and animation actions the way you'd want them to read in the Godot scene tree — not Blender defaults like `Cube.001` or `Armature.002`. The dev side is importing these directly; sensible names save real time there.

## Art style spec (toon/cel-shaded)

Flat, quad-based, low-to-mid poly forms — cel shading emphasizes silhouette and broad flat color regions, not surface micro-detail, so don't spend budget on it:

- Cat protagonist: roughly 3,000–8,000 triangles.
- Mid-size enemies (vacuum, dog, robot vacuum): roughly 1,000–4,000 triangles.
- Small props (spray bottle, broom, drain plug): under 1,000 triangles.
- Assign simple material slots by body part/zone (body, belly, ears, eyes, etc.) rather than one blended material — gives the Godot-side cel shader clean regions to work with.
- Keep silhouettes clean; avoid thin protruding details that break outline/rim-light shaders at a distance.
- Skip fine surface detail (fur strands, scratches) — it's invisible under flat toon shading and wastes poly/texture budget.

## Asset list

Build in this order. Stop after Pass 1 of the Milestone-1 assets (below) and check in before continuing — the roster is large enough that it's worth confirming the pipeline and look on two assets before running it across all seven.

**Two-pass approach**, matching the game's vertical-slice-first scope:
- **Pass 1 — grey-box:** simple primitive proxies (correct scale/proportions, no rig needed beyond root motion) for the cat, upright vacuum, and robot vacuum only, so gameplay can be tested immediately. This unblocks the dev side without waiting on final art.
- **Pass 2 — final:** full toon-shaded models, rigs, and animations for the complete roster, once gameplay feel is validated on Pass 1. Confirm with the requester before starting Pass 2.

Full roster and rig/animation needs (Pass 2):

- **Cat (protagonist):** full armature — spine chain, four legs (IK-friendly), tail (4–6 bones), head/jaw, ears. Animations: idle, walk, run, pounce-attack, claw-combo (2–3 hit variants), dodge-roll, hurt/stagger, faint (life lost), hairball-spit, rage-mode idle and attack variant, hide-crouch, victory/idle-happy.
- **Upright vacuum:** body + hose/neck bone + a separate cord bone (needed for the "unplug" animation beat). Animations: patrol-roll, charge-roar, unplug-stagger, defeated-tip-over.
- **Robot vacuum:** minimal rig, body + slight tilt/spin bone. Animations: patrol-erratic, bump-react, flipped-flail, defeated-spin-out.
- **Dog:** quadruped armature, same general pattern as the cat but larger proportions. Animations: patrol-walk, lunge-bark, startled, chase-run, sneeze-stun.
- **Spray bottle + wielding arm:** simple arm/hand rig plus a bottle prop with a trigger bone. Animations: idle-aim, pump-spray, reload-window, knocked-away.
- **Bathtub & hose set-piece:** mostly static mesh, plus a simple hose-nozzle rig for the spray-arc animation and a drain-plug prop with a "pulled" pose.
- **Broom + sweeping arm:** arm rig plus broom prop. Animations: idle-sweep-telegraph, sweep-attack, recovery, tangled-break.
- **Giant hand:** forearm + hand rig. Animations: idle-hover, grab-swipe, retreat-flinch, whiff.

## Script structure

One Python script per asset, or a shared `asset_lib.py` module with one build function per asset — either way, each asset must be independently regenerable without re-running the whole roster. Parametrize proportions and colors as variables/function arguments near the top of each script rather than hardcoding magic numbers inline; that's what makes this pipeline actually scriptable rather than a one-shot export. Each script should end by exporting directly to its target path in `assets/models/`, and start with a short header comment: what the asset is, its triangle budget, and its bone list.

## Handoff note

Once a `.glb` is exported and imported into Godot, the dev side will re-save it as an editable Godot scene (adding collision shapes, hitbox/hurtbox `Area3D` nodes, etc. in the editor) rather than referencing the raw import at runtime — that's the same editor-first rule the game code follows. You don't need to do anything differently for this; just make sure names and origins are clean enough that the re-save is straightforward.

If any of the animation or rigging requirements above are ambiguous once you're looking at a specific asset, ask before mass-producing the rest of the roster on a guessed convention.
