# Game Design Brief — "Nine Lives" (working title)

*Cat exploration-adventure. Godot 4.6, 3D, toon/cel-shaded. Project: `cat` at `/Users/mlghr/code/godot/cat`.*

## Pitch

You play as a house cat reclaiming home turf from everyday things cats instinctively hate: the vacuum cleaner, the neighbor's dog, bath time, the broom, and the occasional giant grabby hand. It's an exploration-adventure across a single connected house-and-yard hub, told in a toon/cel-shaded style — playful and a little exaggerated, closer to an animated show than a horror story about home appliances.

## Core loop

One connected hub — the house and its yard — rather than discrete levels. Rooms gate off a wing until you deal with whatever's blocking it (can't reach the kitchen counters until the broom's dealt with, can't reach the backyard until the dog's been handled). Traversal leans on cat-specific platforming: jumping between counters, along fences, up bookshelves, across tree branches. Collectibles (toys, treats, yarn) reward exploring off the critical path. Enemies patrol set routes or ambush from hiding rather than spawning in arenas.

## Combat: universal kit + contextual weaknesses

You asked for a blend of "melee + special abilities" and "per-enemy puzzle/weakness" — here's the suggested split, which is a common and reliable pattern (it's the same idea behind elemental weaknesses in a lot of action-adventure games): give the player one moveset that always works on everything, then let each enemy also have a faster, funnier shortcut that rewards paying attention. That way nobody's ever stuck grinding, but the roster still feels distinct.

**Universal kit (works on every enemy, always viable):**
Claw combo (3-hit chain), pounce (leaping heavy attack, chance to knock down), dodge-roll, hiss (short interrupt/parry). Health is life-based (cats have nine lives) with a stagger buffer on small hits so it doesn't feel like a one-hit-death game.

**Ability layer (unlocked over the course of the game):**
- *Hairball* — ranged projectile, interrupts/staggers at a distance, short cooldown.
- *Catnip Rage* — timed buff: faster attacks, no flinch, small damage boost.
- *Hide & Ambush* — duck into a box or under furniture, breaks enemy tracking; the next hit out of hiding is a guaranteed critical.

**Weakness layer (the per-enemy identity/comedy):**
Optional, faster takedown per enemy type, discovered through observation rather than a tutorial pop-up. See roster table below.

## Enemy roster

| Enemy | Behavior | Universal-kit fight | Signature weakness (fast-track) |
|---|---|---|---|
| Upright vacuum | Patrols hallway/living room, loud charge attack | Wear it down with claw combos | Claw the power cord to unplug it (instant stagger); drag it near water for a one-hit comedic KO |
| Robot vacuum (roomba-style) | Fast, low, erratic pathing | Pounce from above to flip it | Flipped = helpless flailing (auto-defeated); or lure it toward a staircase |
| Neighborhood dog | Yard patrol, lunge/chase, barks to alert others | Dodge lunges, combo between barks | Lure it under/through a gap it can't follow; Hairball forces a sneeze-stun |
| Spray bottle (held off-screen) | Ranged "wet" attacks that briefly disable abilities | Close the gap during its reload window | Knock the bottle out of grip / off the shelf to disable it for the encounter |
| Bathtub & hose (bathroom set-piece) | Hose sprays arcs, tub fills over time | Time dodges between spray arcs | Pull the drain plug / shut the valve to end the encounter |
| Broom (swept by an arm) | Sweeping knockback attacks | Dodge the sweep, punish the recovery | Pounce the bristle head mid-swing to tangle/snap it |
| Giant hand | Recurring hazard, not a health-bar fight — tries to grab/pick you up | N/A — evasion-based | Break line of sight (Hide & Ambush) or lead it into something it flinches from |

The giant hand is deliberately not a standard fight — it's a chase/stealth hazard. Keeping one roster entry evasion-only avoids the roster feeling like the same fight in seven skins.

## Art direction

Toon/cel-shaded: flat color zones, rim-lit outlines, slightly exaggerated cat proportions (bigger eyes and paws for readability and charm). Household objects get personality through silhouette and staging (headlight placement, hose posture) rather than literally becoming living creatures — keeps the tone playful rather than surreal.

## Setting & progression

Central hallway hub with four starter wings: Living Room (tutorial + vacuum), Kitchen (broom + counter platforming), Bathroom (spray bottle + tub hazard), Backyard (dog + fence/tree platforming). Bedroom, garage, and attic are natural expansion wings later. Ability unlocks tie to wing completion rather than a numeric level-up system (e.g., Hairball after Kitchen, Catnip Rage after Bathroom, Hide & Ambush after Backyard) — light enough that a first vertical slice doesn't need a save/economy system yet.

## Scope recommendation

Build a vertical slice first: hallway hub + Living Room wing only, with the upright vacuum and robot vacuum, the full universal kit, and the Hairball ability. Prove the feel and the weakness-system hook on two enemies before expanding to the rest of the roster and wings.

## Platform targets

Windows/Mac/Linux export from day one via Godot's standard exporters — no blockers there. Consoles (Switch/PlayStation/Xbox) aren't part of Godot's open-source build; reaching them later means registering as a platform developer directly with the console maker and using Godot's console support, currently offered through commercial partners (e.g. W4 Games, Lone Wolf Technology) rather than the free export templates. That's a later business step, not a design blocker — the only thing to get right now is using Godot's InputMap action system instead of hard-coded key checks, so gamepad support (and later console ports) doesn't require a rewrite.

## Tech stack

Godot 4.6.2 (stable), GDScript, 3D, Jolt Physics (project default). Models built procedurally in Blender via Python (`bpy`) scripts, exported as glTF 2.0, then imported and finished inside the Godot editor as real, editable scenes — per your standing rule, nothing should exist only as a code-instantiated object with no editor-visible counterpart.

## Open questions for later (non-blocking)

The cat's name and any customization scope, whether there's a goal beyond "reclaim the house" (a story reason the enemies showed up?), audio/music direction, save-system needs once there's more than one wing, and whether local co-op is ever worth a stretch goal.
