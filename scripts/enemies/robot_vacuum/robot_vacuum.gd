extends CharacterBody3D

signal disabled(reason: StringName)

enum RobotVacuumState {
	PATROL,
	CHASE,
	BUMP,
	RECOVERY,
	FLIPPED,
	DEFEATED,
}

@export var stats: RobotVacuumStats
@export_node_path("Node3D") var model_root_path: NodePath = ^"ModelRoot"
@export_node_path("NavigationAgent3D") var navigation_agent_path: NodePath = ^"NavigationAgent"
@export_node_path("Area3D") var player_detection_area_path: NodePath = ^"Sensors/PlayerDetectionArea"
@export_node_path("HitboxArea") var bump_hitbox_path: NodePath = ^"CombatRoot/BumpHitbox"
@export_node_path("HealthComponent") var health_component_path: NodePath = ^"HealthComponent"
@export_node_path("Node3D") var route_root_path: NodePath = ^"PatrolRoute"
@export_node_path("Area3D") var encounter_bounds_path: NodePath = NodePath("")
@export_node_path("Area3D") var stair_fall_detector_path: NodePath = ^"WeaknessRoot/StairFallDetector"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"
@export var flip_effect_scene: PackedScene
@export var shutdown_effect_scene: PackedScene

@onready var model_root: Node3D = get_node_or_null(model_root_path)
@onready var navigation_agent: NavigationAgent3D = get_node_or_null(navigation_agent_path)
@onready var player_detection_area: Area3D = get_node_or_null(player_detection_area_path)
@onready var bump_hitbox: HitboxArea = get_node_or_null(bump_hitbox_path)
@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var route_root: Node3D = get_node_or_null(route_root_path)
@onready var encounter_bounds: Area3D = get_node_or_null(encounter_bounds_path)
@onready var stair_fall_detector: Area3D = get_node_or_null(stair_fall_detector_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var state: RobotVacuumState = RobotVacuumState.PATROL

var _target: Node3D
var _route_points: Array[Marker3D] = []
var _route_index: int = 0
var _state_timer: float = 0.0
var _erratic_timer: float = 0.0
var _erratic_direction: Vector3 = Vector3.FORWARD
var _home_transform: Transform3D
var _disabled_emitted: bool = false


func _ready() -> void:
	if stats == null:
		push_error("RobotVacuum requires a RobotVacuumStats resource.")
		return

	_home_transform = global_transform
	_collect_route_points()
	_apply_stats_to_nodes()
	_connect_signals()
	_pick_erratic_direction()
	_set_next_route_target()


func _physics_process(delta: float) -> void:
	if stats == null:
		return

	match state:
		RobotVacuumState.PATROL:
			_patrol(delta)
		RobotVacuumState.CHASE:
			_chase(delta)
		RobotVacuumState.BUMP:
			_bump(delta)
		RobotVacuumState.RECOVERY:
			_tick_timer(delta, RobotVacuumState.PATROL)
		RobotVacuumState.FLIPPED:
			_tick_timer(delta, RobotVacuumState.DEFEATED)
		RobotVacuumState.DEFEATED:
			velocity = Vector3.ZERO

	move_and_slide()
	_update_facing(delta)


func on_hurtbox_hit(hit_data: Dictionary) -> bool:
	if hit_data.get("hit_type") == &"pounce" and hit_data.get("hurtbox_marker") == &"top_pounce":
		var source := hit_data.get("source") as Node3D
		if source == null or source.global_position.y >= global_position.y + stats.pounce_flip_height_margin:
			_enter_flipped()
			return true

	return false


func on_stair_fall_triggered() -> void:
	if stats.stair_fall_instant_defeat:
		_enter_defeated(&"stair_fall")


func _collect_route_points() -> void:
	_route_points.clear()
	if route_root == null:
		return

	for child in route_root.get_children():
		if child is Marker3D:
			_route_points.append(child)


func _apply_stats_to_nodes() -> void:
	if bump_hitbox != null:
		bump_hitbox.damage = stats.bump_damage
		bump_hitbox.stagger = stats.bump_stagger
		bump_hitbox.knockback_force = stats.bump_knockback_force
		bump_hitbox.hit_type = &"robot_vacuum_bump"

	if player_detection_area != null:
		var shape_node := player_detection_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape_node != null and shape_node.shape is SphereShape3D:
			(shape_node.shape as SphereShape3D).radius = stats.detection_radius


func _connect_signals() -> void:
	if player_detection_area != null:
		player_detection_area.body_entered.connect(_on_player_detection_body_entered)
		player_detection_area.body_exited.connect(_on_player_detection_body_exited)

	if health_component != null:
		health_component.defeated.connect(_enter_defeated)
		health_component.stagger_started.connect(_on_stagger_started)

	if stair_fall_detector != null:
		stair_fall_detector.area_entered.connect(_on_stair_area_entered)
		stair_fall_detector.body_entered.connect(_on_stair_body_entered)

	if encounter_bounds != null:
		encounter_bounds.body_exited.connect(_on_encounter_bounds_body_exited)


func _patrol(delta: float) -> void:
	_update_erratic_direction(delta)

	if navigation_agent == null or _route_points.is_empty():
		velocity.x = _erratic_direction.x * stats.patrol_speed
		velocity.z = _erratic_direction.z * stats.patrol_speed
		return

	if navigation_agent.is_navigation_finished() or global_position.distance_to(navigation_agent.target_position) <= stats.waypoint_arrival_distance:
		_route_index = (_route_index + 1) % _route_points.size()
		_set_next_route_target()
		_pick_erratic_direction()

	var path_direction := navigation_agent.get_next_path_position() - global_position
	path_direction.y = 0.0
	if path_direction.length_squared() > 0.0:
		path_direction = path_direction.normalized()

	var blended_direction := (path_direction + _erratic_direction * 0.35).normalized()
	velocity.x = blended_direction.x * stats.patrol_speed
	velocity.z = blended_direction.z * stats.patrol_speed


func _chase(delta: float) -> void:
	if _target == null:
		state = RobotVacuumState.PATROL
		_set_next_route_target()
		return

	_update_erratic_direction(delta)
	var target_position := _target.global_position
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() == 0.0:
		return

	direction = (direction.normalized() + _erratic_direction * 0.2).normalized()
	velocity.x = direction.x * stats.chase_speed
	velocity.z = direction.z * stats.chase_speed

	if global_position.distance_to(target_position) <= stats.charge_commit_distance:
		_start_bump(direction)


func _bump(delta: float) -> void:
	_tick_timer(delta, RobotVacuumState.RECOVERY)


func _tick_timer(delta: float, next_state: RobotVacuumState) -> void:
	_state_timer = maxf(_state_timer - delta, 0.0)
	if _state_timer > 0.0:
		return

	if state == RobotVacuumState.FLIPPED:
		_enter_defeated(&"flipped")
	else:
		if bump_hitbox != null:
			bump_hitbox.enabled = false
		state = next_state
		_set_next_route_target()


func _start_bump(direction: Vector3) -> void:
	if state in [RobotVacuumState.BUMP, RobotVacuumState.RECOVERY, RobotVacuumState.FLIPPED, RobotVacuumState.DEFEATED]:
		return

	velocity.x = direction.x * stats.charge_speed
	velocity.z = direction.z * stats.charge_speed
	state = RobotVacuumState.BUMP
	_state_timer = 0.34
	if animation_player != null and animation_player.has_animation(&"bump_attack"):
		animation_player.play(&"bump_attack")


func _enter_flipped() -> void:
	if state == RobotVacuumState.DEFEATED:
		return

	if bump_hitbox != null:
		bump_hitbox.enabled = false

	velocity = Vector3.ZERO
	state = RobotVacuumState.FLIPPED
	_state_timer = stats.helpless_duration
	if animation_player != null and animation_player.has_animation(&"flipped"):
		animation_player.play(&"flipped")
	_spawn_effect(flip_effect_scene)


func _enter_defeated(reason: StringName = &"defeated") -> void:
	if bump_hitbox != null:
		bump_hitbox.enabled = false

	velocity = Vector3.ZERO
	state = RobotVacuumState.DEFEATED
	if animation_player != null and animation_player.has_animation(&"defeated"):
		animation_player.play(&"defeated")

	if not _disabled_emitted:
		_disabled_emitted = true
		_spawn_effect(shutdown_effect_scene)
		disabled.emit(reason)


func _reset_to_leash_home() -> void:
	if state in [RobotVacuumState.FLIPPED, RobotVacuumState.DEFEATED]:
		return

	if bump_hitbox != null:
		bump_hitbox.enabled = false

	_target = null
	velocity = Vector3.ZERO
	global_transform = _home_transform
	state = RobotVacuumState.PATROL
	_route_index = 0
	_pick_erratic_direction()
	_set_next_route_target()


func _on_stagger_started(duration: float) -> void:
	if state in [RobotVacuumState.FLIPPED, RobotVacuumState.DEFEATED]:
		return

	velocity = Vector3.ZERO
	state = RobotVacuumState.RECOVERY
	_state_timer = maxf(duration, stats.charge_recovery)


func _set_next_route_target() -> void:
	if navigation_agent == null or _route_points.is_empty():
		return

	navigation_agent.target_position = _route_points[_route_index].global_position


func _update_erratic_direction(delta: float) -> void:
	_erratic_timer = maxf(_erratic_timer - delta, 0.0)
	if _erratic_timer == 0.0:
		_pick_erratic_direction()


func _pick_erratic_direction() -> void:
	_erratic_timer = randf_range(stats.erratic_turn_interval_min, stats.erratic_turn_interval_max)
	var angle := randf_range(-PI, PI)
	_erratic_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _update_facing(delta: float) -> void:
	if model_root == null:
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() == 0.0:
		return

	var desired_yaw := atan2(-horizontal_velocity.x, -horizontal_velocity.z)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, desired_yaw, minf(stats.turn_rate * delta, 1.0))


func _on_player_detection_body_entered(body: Node3D) -> void:
	if not _is_player_candidate(body):
		return

	_target = body
	if state == RobotVacuumState.PATROL:
		state = RobotVacuumState.CHASE


func _on_player_detection_body_exited(body: Node3D) -> void:
	if body != _target:
		return

	_target = null
	if state == RobotVacuumState.CHASE:
		state = RobotVacuumState.PATROL
		_set_next_route_target()


func _on_stair_area_entered(area: Area3D) -> void:
	if area.is_in_group("stair_fall") or area.name.to_lower().contains("stair"):
		on_stair_fall_triggered()


func _on_stair_body_entered(body: Node3D) -> void:
	if body.is_in_group("stair_fall") or body.name.to_lower().contains("stair"):
		on_stair_fall_triggered()


func _on_encounter_bounds_body_exited(body: Node3D) -> void:
	if body == _target and _is_player_candidate(body):
		_reset_to_leash_home()


func _is_player_candidate(body: Node) -> bool:
	return body.name == "Player" or body.is_in_group("player")


func _spawn_effect(effect_scene: PackedScene) -> void:
	if effect_scene == null:
		return

	var effect := effect_scene.instantiate() as Node3D
	if effect == null:
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = self

	parent.add_child(effect)
	effect.global_position = global_position
