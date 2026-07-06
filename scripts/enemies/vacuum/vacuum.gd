extends CharacterBody3D

enum VacuumState {
	PATROL,
	CHASE,
	CHARGE_WINDUP,
	CHARGING,
	RECOVERY,
	STAGGERED,
	SHUTDOWN,
}

@export var stats: EnemyStats
@export_node_path("Node3D") var model_root_path: NodePath = ^"ModelRoot"
@export_node_path("NavigationAgent3D") var navigation_agent_path: NodePath = ^"NavigationAgent"
@export_node_path("Area3D") var player_detection_area_path: NodePath = ^"Sensors/PlayerDetectionArea"
@export_node_path("Area3D") var charge_commit_area_path: NodePath = ^"Sensors/ChargeCommitArea"
@export_node_path("HitboxArea") var charge_hitbox_path: NodePath = ^"CombatRoot/ChargeHitbox"
@export_node_path("HealthComponent") var health_component_path: NodePath = ^"HealthComponent"
@export_node_path("Node3D") var patrol_route_path: NodePath = ^"PatrolRoute"
@export_node_path("Node3D") var power_cord_path: NodePath = ^"WeaknessRoot/PowerCord"
@export_node_path("Area3D") var water_short_circuit_area_path: NodePath = ^"WeaknessRoot/WaterShortCircuitArea"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"

@onready var model_root: Node3D = get_node_or_null(model_root_path)
@onready var navigation_agent: NavigationAgent3D = get_node_or_null(navigation_agent_path)
@onready var player_detection_area: Area3D = get_node_or_null(player_detection_area_path)
@onready var charge_commit_area: Area3D = get_node_or_null(charge_commit_area_path)
@onready var charge_hitbox: HitboxArea = get_node_or_null(charge_hitbox_path)
@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var patrol_route: Node3D = get_node_or_null(patrol_route_path)
@onready var power_cord: Node = get_node_or_null(power_cord_path)
@onready var water_short_circuit_area: Area3D = get_node_or_null(water_short_circuit_area_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var state: VacuumState = VacuumState.PATROL

var _target: Node3D
var _patrol_points: Array[Marker3D] = []
var _patrol_index: int = 0
var _state_timer: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	if stats == null:
		push_error("Vacuum requires an EnemyStats resource.")
		return

	_collect_patrol_points()
	_apply_stats_to_nodes()
	_connect_signals()
	_set_next_patrol_target()


func _physics_process(delta: float) -> void:
	if stats == null:
		return

	match state:
		VacuumState.PATROL:
			_patrol(delta)
		VacuumState.CHASE:
			_chase(delta)
		VacuumState.CHARGE_WINDUP:
			_tick_windup(delta)
		VacuumState.CHARGING:
			_charge(delta)
		VacuumState.RECOVERY, VacuumState.STAGGERED:
			_tick_timer(delta, VacuumState.PATROL)
		VacuumState.SHUTDOWN:
			velocity = Vector3.ZERO

	move_and_slide()
	_update_facing(delta)


func on_hurtbox_hit(hit_data: Dictionary) -> bool:
	if hit_data.get("hit_type") == &"hiss":
		_enter_stagger(stats.charge_recovery)
		return false

	return false


func on_power_cord_unplugged() -> void:
	if stats.cord_unplug_shutdown:
		_enter_shutdown()
	else:
		_enter_stagger(stats.cord_unplug_stagger_duration)


func on_water_weakness_triggered() -> void:
	if stats.water_instant_defeat:
		_enter_shutdown()


func _collect_patrol_points() -> void:
	_patrol_points.clear()
	if patrol_route == null:
		return

	for child in patrol_route.get_children():
		if child is Marker3D:
			_patrol_points.append(child)


func _apply_stats_to_nodes() -> void:
	if charge_hitbox != null:
		charge_hitbox.damage = stats.charge_damage
		charge_hitbox.stagger = stats.charge_stagger
		charge_hitbox.knockback_force = stats.charge_knockback_force
		charge_hitbox.hit_type = &"vacuum_charge"

	if player_detection_area != null:
		_update_sphere_radius(player_detection_area, stats.detection_radius)

	if charge_commit_area != null:
		_update_sphere_radius(charge_commit_area, stats.charge_commit_distance)


func _connect_signals() -> void:
	if player_detection_area != null:
		player_detection_area.body_entered.connect(_on_player_detection_body_entered)
		player_detection_area.body_exited.connect(_on_player_detection_body_exited)

	if charge_commit_area != null:
		charge_commit_area.body_entered.connect(_on_charge_commit_body_entered)

	if health_component != null:
		health_component.stagger_started.connect(_on_stagger_started)
		health_component.defeated.connect(_enter_shutdown)

	if power_cord != null and power_cord.has_signal("unplugged"):
		power_cord.unplugged.connect(on_power_cord_unplugged)

	if water_short_circuit_area != null:
		water_short_circuit_area.area_entered.connect(_on_water_short_circuit_area_entered)
		water_short_circuit_area.body_entered.connect(_on_water_short_circuit_body_entered)


func _patrol(delta: float) -> void:
	if navigation_agent == null or _patrol_points.is_empty():
		velocity = Vector3.ZERO
		return

	if navigation_agent.is_navigation_finished() or global_position.distance_to(navigation_agent.target_position) <= stats.waypoint_arrival_distance:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		_set_next_patrol_target()

	_move_toward(navigation_agent.get_next_path_position(), stats.patrol_speed, delta)


func _chase(delta: float) -> void:
	if _target == null:
		state = VacuumState.PATROL
		_set_next_patrol_target()
		return

	if navigation_agent != null:
		navigation_agent.target_position = _target.global_position
		_move_toward(navigation_agent.get_next_path_position(), stats.chase_speed, delta)
	else:
		_move_toward(_target.global_position, stats.chase_speed, delta)


func _tick_windup(delta: float) -> void:
	velocity = Vector3.ZERO
	_tick_timer(delta, VacuumState.CHARGING)


func _charge(delta: float) -> void:
	velocity.x = _charge_direction.x * stats.charge_speed
	velocity.z = _charge_direction.z * stats.charge_speed
	_tick_timer(delta, VacuumState.RECOVERY)


func _tick_timer(delta: float, next_state: VacuumState) -> void:
	_state_timer = maxf(_state_timer - delta, 0.0)
	if _state_timer > 0.0:
		return

	if state == VacuumState.CHARGE_WINDUP:
		_begin_charge()
	elif state == VacuumState.CHARGING:
		_begin_recovery()
	else:
		state = next_state
		_set_next_patrol_target()


func _move_toward(target_position: Vector3, speed: float, delta: float) -> void:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta)
		return

	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _set_next_patrol_target() -> void:
	if navigation_agent == null or _patrol_points.is_empty():
		return

	navigation_agent.target_position = _patrol_points[_patrol_index].global_position


func _start_charge_windup() -> void:
	if _target == null or state in [VacuumState.CHARGE_WINDUP, VacuumState.CHARGING, VacuumState.RECOVERY, VacuumState.STAGGERED, VacuumState.SHUTDOWN]:
		return

	_charge_direction = _target.global_position - global_position
	_charge_direction.y = 0.0
	_charge_direction = _charge_direction.normalized()
	if _charge_direction.length_squared() == 0.0:
		_charge_direction = -global_transform.basis.z

	state = VacuumState.CHARGE_WINDUP
	_state_timer = stats.charge_windup
	if animation_player != null and animation_player.has_animation(&"charge_windup"):
		animation_player.play(&"charge_windup")


func _begin_charge() -> void:
	state = VacuumState.CHARGING
	_state_timer = 0.35
	if animation_player != null and animation_player.has_animation(&"charge_attack"):
		animation_player.play(&"charge_attack")


func _begin_recovery() -> void:
	if charge_hitbox != null:
		charge_hitbox.enabled = false

	velocity = Vector3.ZERO
	state = VacuumState.RECOVERY
	_state_timer = stats.charge_recovery


func _enter_stagger(duration: float) -> void:
	if state == VacuumState.SHUTDOWN:
		return

	if charge_hitbox != null:
		charge_hitbox.enabled = false

	velocity = Vector3.ZERO
	state = VacuumState.STAGGERED
	_state_timer = duration
	if animation_player != null and animation_player.has_animation(&"stagger"):
		animation_player.play(&"stagger")


func _enter_shutdown() -> void:
	if charge_hitbox != null:
		charge_hitbox.enabled = false

	velocity = Vector3.ZERO
	state = VacuumState.SHUTDOWN
	if animation_player != null and animation_player.has_animation(&"shutdown"):
		animation_player.play(&"shutdown")


func _update_facing(delta: float) -> void:
	if model_root == null:
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() == 0.0:
		return

	var desired_yaw := atan2(-horizontal_velocity.x, -horizontal_velocity.z)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, desired_yaw, minf(stats.turn_rate * delta, 1.0))


func _update_sphere_radius(area: Area3D, radius: float) -> void:
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or not shape_node.shape is SphereShape3D:
		return

	(shape_node.shape as SphereShape3D).radius = radius


func _on_player_detection_body_entered(body: Node3D) -> void:
	if not _is_player_candidate(body):
		return

	_target = body
	if state == VacuumState.PATROL:
		state = VacuumState.CHASE


func _on_player_detection_body_exited(body: Node3D) -> void:
	if body != _target:
		return

	_target = null
	if state == VacuumState.CHASE:
		state = VacuumState.PATROL
		_set_next_patrol_target()


func _on_charge_commit_body_entered(body: Node3D) -> void:
	if body == _target and _is_player_candidate(body):
		_start_charge_windup()


func _on_stagger_started(duration: float) -> void:
	_enter_stagger(duration)


func _on_water_short_circuit_area_entered(area: Area3D) -> void:
	if area.is_in_group("water_hazard") or area.name.to_lower().contains("water"):
		on_water_weakness_triggered()


func _on_water_short_circuit_body_entered(body: Node3D) -> void:
	if body.is_in_group("water_hazard") or body.name.to_lower().contains("water"):
		on_water_weakness_triggered()


func _is_player_candidate(body: Node) -> bool:
	return body.name == "Player" or body.is_in_group("player")
