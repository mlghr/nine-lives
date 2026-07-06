# Milestone 1 Scene Tree Proposal

This is the approval gate for the first playable slice. Later work items should create real `.tscn` scenes and `.tres` resources that follow these trees unless the PR calls out a deliberate change.

## Shared Architecture

- Scene files own the object graph. Scripts only drive nodes that already exist in the scene.
- Tunable gameplay values live in custom `Resource` scripts and `.tres` instances, then plug into root scene scripts through exported resource properties.
- Reusable combat pieces live under `scenes/components/` and `scripts/components/`. This adds one folder pair beyond the original prompt structure because WI3 requires shared hitbox, hurtbox, and health components.
- Hitboxes and hurtboxes are `Area3D` nodes with named `CollisionShape3D` children. `AnimationPlayer` tracks enable and disable hitboxes for attack windows; scripts do not create hitboxes at runtime.
- Enemy patrol and weakness markers are level-authored nodes. Enemy scripts receive exported `NodePath` references to those markers or discover nodes in agreed groups, so designers can move routes and weakness volumes in the editor.

## Player

`scenes/player/player.tscn`

```text
Player (CharacterBody3D) [scripts/player/player.gd]
  BodyCollision (CollisionShape3D)
  ModelRoot (Node3D)
    BodyProxy (MeshInstance3D)
    HeadProxy (MeshInstance3D)
    TailProxy (MeshInstance3D)
    PawProxy_FL (MeshInstance3D)
    PawProxy_FR (MeshInstance3D)
    PawProxy_BL (MeshInstance3D)
    PawProxy_BR (MeshInstance3D)
  FacingMarker (Marker3D)
  GroundProbe (RayCast3D)
  CameraRig (Node3D) [scripts/player/camera_rig.gd]
    YawPivot (Node3D)
      PitchPivot (Node3D)
        CameraBoom (SpringArm3D)
          Camera (Camera3D)
  CombatRoot (Node3D)
    ClawHitbox_L (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    ClawHitbox_R (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    PounceHitbox (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    HissParryArea (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    Hurtbox (Area3D) [scripts/components/hurtbox_area.gd]
      CollisionShape3D
  HealthComponent (Node) [scripts/components/health_component.gd]
  HairballSpawn (Marker3D)
  AnimationPlayer (AnimationPlayer)
```

Script ownership:

- `player.gd` owns movement, jump state, universal combat state, ability requests, and references `PlayerStats`.
- `camera_rig.gd` owns orbit input, pitch/yaw clamps, collision boom tuning, and camera sensitivity.
- `health_component.gd` owns nine-lives state and stagger-buffer behavior so enemies can reuse the same damage flow.
- `hitbox_area.gd` emits damage, stagger, knockback, and source metadata when an enabled hitbox overlaps a hurtbox.
- `hurtbox_area.gd` forwards incoming hit data to the owning `HealthComponent` or enemy/player root.

Resource plug-ins:

- `resources/player/player_stats.tres` plugs into `Player.stats`.
- `PlayerStats` should include movement speed, acceleration, jump force, coyote time, dodge timing, pounce force, claw combo timing, hiss window, nine-lives count, and stagger-buffer tuning.
- `resources/abilities/hairball_data.tres` plugs into the ability/cast path once WI6 creates `hairball_projectile.tscn`.

## Upright Vacuum

`scenes/enemies/vacuum/vacuum.tscn`

```text
Vacuum (CharacterBody3D) [scripts/enemies/vacuum/vacuum.gd]
  BodyCollision (CollisionShape3D)
  ModelRoot (Node3D)
    BodyProxy (MeshInstance3D)
    HandleProxy (MeshInstance3D)
    HeadProxy (MeshInstance3D)
    WheelProxy_L (MeshInstance3D)
    WheelProxy_R (MeshInstance3D)
  NavigationAgent (NavigationAgent3D)
  Sensors (Node3D)
    PlayerDetectionArea (Area3D)
      CollisionShape3D
    ChargeCommitArea (Area3D)
      CollisionShape3D
  CombatRoot (Node3D)
    ChargeHitbox (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    Hurtbox (Area3D) [scripts/components/hurtbox_area.gd]
      CollisionShape3D
  WeaknessRoot (Node3D)
    PowerCord (Node3D) [scripts/enemies/vacuum/power_cord.gd]
      CordMesh (MeshInstance3D)
      CordHurtbox (Area3D) [scripts/components/hurtbox_area.gd]
        CollisionShape3D
      OutletSocket (Marker3D)
    WaterShortCircuitArea (Area3D)
      CollisionShape3D
  HealthComponent (Node) [scripts/components/health_component.gd]
  AudioCuePoints (Node3D)
    MotorLoopPoint (Marker3D)
    ChargeCuePoint (Marker3D)
  AnimationPlayer (AnimationPlayer)
```

Script ownership:

- `vacuum.gd` owns patrol, detection, telegraph, charge, stagger, shutdown, and exported references to level-authored patrol markers.
- `power_cord.gd` owns cord-specific hit response and tells `vacuum.gd` when the cord is unplugged.
- Shared `hitbox_area.gd`, `hurtbox_area.gd`, and `health_component.gd` handle combat interaction consistently with the player and robot vacuum.

Resource plug-ins:

- `resources/enemy_stats/vacuum_stats.tres` plugs into `Vacuum.stats`.
- `EnemyStats` should include lives/health, patrol speed, chase speed, turn rate, detection radius, charge speed, charge windup, charge recovery, stagger duration, universal-kit damage response, cord-unplug stagger duration, and water weakness result.
- Patrol route is not stored in stats. It is level-authored through exported `NodePath` or marker-group references.

Weakness structure:

- Clawing `CordHurtbox` triggers the unplug weakness and forces a heavy stagger or shutdown depending on stats tuning.
- `WaterShortCircuitArea` detects overlap with level-authored water volumes, such as a water bowl spill trigger, and applies the comedic one-hit KO route.

## Robot Vacuum

`scenes/enemies/robot_vacuum/robot_vacuum.tscn`

```text
RobotVacuum (CharacterBody3D) [scripts/enemies/robot_vacuum/robot_vacuum.gd]
  BodyCollision (CollisionShape3D)
  ModelRoot (Node3D)
    BodyProxy (MeshInstance3D)
    BumperProxy (MeshInstance3D)
    WheelProxy_L (MeshInstance3D)
    WheelProxy_R (MeshInstance3D)
    FlippedIndicatorProxy (MeshInstance3D)
  NavigationAgent (NavigationAgent3D)
  Sensors (Node3D)
    PlayerDetectionArea (Area3D)
      CollisionShape3D
    ObstacleProbe_Front (RayCast3D)
    ObstacleProbe_Left (RayCast3D)
    ObstacleProbe_Right (RayCast3D)
  CombatRoot (Node3D)
    BumpHitbox (Area3D) [scripts/components/hitbox_area.gd]
      CollisionShape3D
    Hurtbox (Area3D) [scripts/components/hurtbox_area.gd]
      CollisionShape3D
    TopPounceWeakpoint (Area3D) [scripts/components/hurtbox_area.gd]
      CollisionShape3D
  WeaknessRoot (Node3D)
    StairFallDetector (Area3D)
      CollisionShape3D
    FlipStateAnchor (Marker3D)
  HealthComponent (Node) [scripts/components/health_component.gd]
  AnimationPlayer (AnimationPlayer)
```

Script ownership:

- `robot_vacuum.gd` owns erratic patrol, detection, bump attacks, flipped state, helpless timer, and exported references to level-authored route markers.
- `TopPounceWeakpoint` reports pounce-from-above hits separately from regular damage so the root can flip the robot without hardcoding special cases in the generic hitbox.
- `StairFallDetector` reacts to level-authored staircase weakness volumes and applies the fast defeat path.
- Shared combat components keep damage, stagger, and invulnerability behavior aligned with the player and upright vacuum.

Resource plug-ins:

- `resources/enemy_stats/robot_vacuum_stats.tres` plugs into `RobotVacuum.stats`.
- `EnemyStats` should include lives/health, patrol speed, chase speed, erratic turn interval, bump damage, pounce-flip threshold, helpless duration, stair-fall defeat behavior, stagger duration, and universal-kit damage response.

## Decisions Needing Sign-off

- Camera actions use mouse motion for `camera_look` and right-stick directional actions for `camera_look_left/right/up/down`. Keyboard arrow camera look is intentionally omitted; Work Item 2, the player movement and camera pass, should tune sensitivity and pitch clamp feel.
- The shared `scenes/components/` and `scripts/components/` folders are added now for WI3 reusable combat/health components.
- The player tree keeps `CameraRig` inside `player.tscn` for the first slice. If a reusable camera scene is preferred, Work Item 2 can split it into `scenes/player/camera_rig.tscn` before gameplay code depends on it.
- Vacuum and robot vacuum both use `CharacterBody3D` plus `NavigationAgent3D` for controllable enemy movement.
