extends CharacterBody3D

signal hairball_cooldown_changed(remaining: float, cooldown: float)

@export var stats: PlayerStats
@export_node_path("Node3D") var model_root_path: NodePath = ^"ModelRoot"
@export_node_path("Node3D") var camera_rig_path: NodePath = ^"CameraRig"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"
@export_node_path("HealthComponent") var health_component_path: NodePath = ^"HealthComponent"
@export_node_path("HitboxArea") var claw_left_hitbox_path: NodePath = ^"CombatRoot/ClawHitbox_L"
@export_node_path("HitboxArea") var claw_right_hitbox_path: NodePath = ^"CombatRoot/ClawHitbox_R"
@export_node_path("HitboxArea") var pounce_hitbox_path: NodePath = ^"CombatRoot/PounceHitbox"
@export_node_path("HitboxArea") var hiss_parry_area_path: NodePath = ^"CombatRoot/HissParryArea"
@export_node_path("Marker3D") var hairball_spawn_path: NodePath = ^"HairballSpawn"
@export var hairball_projectile_scene: PackedScene
@export var hairball_data: HairballData

@onready var model_root: Node3D = get_node_or_null(model_root_path)
@onready var camera_rig: Node3D = get_node_or_null(camera_rig_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)
@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var claw_left_hitbox: HitboxArea = get_node_or_null(claw_left_hitbox_path)
@onready var claw_right_hitbox: HitboxArea = get_node_or_null(claw_right_hitbox_path)
@onready var pounce_hitbox: HitboxArea = get_node_or_null(pounce_hitbox_path)
@onready var hiss_parry_area: HitboxArea = get_node_or_null(hiss_parry_area_path)
@onready var hairball_spawn: Marker3D = get_node_or_null(hairball_spawn_path)

@export var parry_active: bool = false

var _coyote_timer: float = 0.0
var _combo_step: int = 0
var _combo_reset_timer: float = 0.0
var _combat_state: StringName = &"idle"
var _dodge_direction: Vector3 = Vector3.ZERO
var _hairball_cooldown_remaining: float = 0.0


func _ready() -> void:
	if stats == null:
		push_error("Player requires a PlayerStats resource.")
		return

	_apply_combat_stats()


func _physics_process(delta: float) -> void:
	if stats == null:
		return

	var movement_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := _camera_relative_direction(movement_input)
	_update_combo_reset(delta)
	_update_hairball_cooldown(delta)
	_handle_combat_input(move_direction)

	var target_velocity := move_direction * _target_speed(movement_input.length())
	if _combat_state == &"dodge":
		target_velocity = _dodge_direction * stats.dodge_speed

	var grounded := is_on_floor()

	if grounded:
		_coyote_timer = stats.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	var horizontal_acceleration := stats.air_acceleration
	if grounded:
		horizontal_acceleration = stats.acceleration if move_direction.length_squared() > 0.0 else stats.deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, horizontal_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, horizontal_acceleration * delta)

	if Input.is_action_just_pressed("jump") and _combat_state != &"dodge" and _coyote_timer > 0.0:
		velocity.y = stats.jump_velocity
		_coyote_timer = 0.0
	elif grounded and velocity.y < 0.0:
		velocity.y = stats.grounded_snap_velocity
	else:
		velocity.y -= stats.gravity * delta

	move_and_slide()
	_update_facing(delta)


func _camera_relative_direction(movement_input: Vector2) -> Vector3:
	if movement_input.length_squared() == 0.0:
		return Vector3.ZERO

	var basis := global_transform.basis
	if camera_rig != null:
		basis = camera_rig.global_transform.basis

	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := basis.x
	right.y = 0.0
	right = right.normalized()

	return (right * movement_input.x + forward * -movement_input.y).normalized()


func _target_speed(input_strength: float) -> float:
	if input_strength <= 0.0:
		return 0.0

	var run_weight := inverse_lerp(stats.walk_input_threshold, stats.run_input_threshold, input_strength)
	run_weight = clampf(run_weight, 0.0, 1.0)

	var analog_scale := minf(input_strength / stats.walk_input_threshold, 1.0)
	return lerpf(stats.walk_speed, stats.run_speed, run_weight) * analog_scale


func _update_facing(delta: float) -> void:
	if model_root == null:
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length() <= stats.facing_deadzone:
		return

	var desired_yaw := atan2(-horizontal_velocity.x, -horizontal_velocity.z)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, desired_yaw, minf(stats.turn_speed * delta, 1.0))


func on_hurtbox_hit(_hit_data: Dictionary) -> bool:
	return parry_active


func _handle_combat_input(move_direction: Vector3) -> void:
	if _combat_state != &"idle":
		return

	if Input.is_action_just_pressed("dodge"):
		_start_dodge(move_direction)
	elif Input.is_action_just_pressed("hiss"):
		_start_hiss()
	elif Input.is_action_just_pressed("pounce"):
		_start_pounce(move_direction)
	elif Input.is_action_just_pressed("attack_claw"):
		_start_claw()
	elif Input.is_action_just_pressed("ability_hairball"):
		_try_cast_hairball()


func _start_claw() -> void:
	_combo_step = (_combo_step % 3) + 1
	_combat_state = &"claw"
	_play_combat_animation("claw_%d" % _combo_step)


func _start_pounce(move_direction: Vector3) -> void:
	var pounce_direction := move_direction
	if pounce_direction.length_squared() == 0.0:
		pounce_direction = _current_facing_direction()

	velocity.x = pounce_direction.x * stats.pounce_forward_speed
	velocity.z = pounce_direction.z * stats.pounce_forward_speed
	velocity.y = stats.pounce_up_velocity
	_combat_state = &"pounce"
	_play_combat_animation("pounce")


func _start_dodge(move_direction: Vector3) -> void:
	_dodge_direction = move_direction
	if _dodge_direction.length_squared() == 0.0:
		_dodge_direction = _current_facing_direction()

	_combat_state = &"dodge"
	_play_combat_animation("dodge_roll")


func _start_hiss() -> void:
	_combat_state = &"hiss"
	_play_combat_animation("hiss")


func _finish_combat_action() -> void:
	if _combat_state == &"claw":
		_combo_reset_timer = stats.claw_combo_reset_seconds

	_combat_state = &"idle"


func _finish_dodge() -> void:
	if health_component != null:
		health_component.clear_invulnerability()

	_dodge_direction = Vector3.ZERO
	_combat_state = &"idle"


func _clear_parry() -> void:
	parry_active = false


func _play_combat_animation(animation_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		push_warning("Missing combat animation: %s" % animation_name)
		_finish_combat_action()
		return

	_disable_combat_windows()
	animation_player.play(animation_name)


func _update_combo_reset(delta: float) -> void:
	if _combo_reset_timer <= 0.0:
		return

	_combo_reset_timer = maxf(_combo_reset_timer - delta, 0.0)
	if _combo_reset_timer == 0.0:
		_combo_step = 0


func _current_facing_direction() -> Vector3:
	if model_root == null:
		return -global_transform.basis.z

	return -model_root.global_transform.basis.z.normalized()


func _apply_combat_stats() -> void:
	if claw_left_hitbox != null:
		claw_left_hitbox.damage = stats.claw_1_damage
		claw_left_hitbox.stagger = stats.claw_stagger
		claw_left_hitbox.knockback_force = stats.claw_knockback_force
		claw_left_hitbox.hit_type = &"claw"

	if claw_right_hitbox != null:
		claw_right_hitbox.damage = stats.claw_2_damage
		claw_right_hitbox.stagger = stats.claw_stagger
		claw_right_hitbox.knockback_force = stats.claw_knockback_force
		claw_right_hitbox.hit_type = &"claw"

	if pounce_hitbox != null:
		pounce_hitbox.damage = stats.pounce_damage
		pounce_hitbox.stagger = stats.pounce_stagger
		pounce_hitbox.knockback_force = stats.pounce_knockback_force
		pounce_hitbox.knockdown_chance = stats.pounce_knockdown_chance
		pounce_hitbox.hit_type = &"pounce"

	if hiss_parry_area != null:
		hiss_parry_area.damage = stats.hiss_damage
		hiss_parry_area.stagger = stats.hiss_stagger
		hiss_parry_area.knockback_force = stats.hiss_knockback_force
		hiss_parry_area.hit_type = &"hiss"


func _disable_combat_windows() -> void:
	parry_active = false

	for hitbox in [claw_left_hitbox, claw_right_hitbox, pounce_hitbox, hiss_parry_area]:
		if hitbox != null:
			hitbox.enabled = false


func _try_cast_hairball() -> void:
	if hairball_projectile_scene == null or hairball_data == null or hairball_spawn == null:
		push_warning("Hairball cast requested without projectile scene, data, or spawn marker.")
		return

	if _hairball_cooldown_remaining > 0.0:
		return

	var projectile := hairball_projectile_scene.instantiate() as HairballProjectile
	if projectile == null:
		push_warning("Hairball projectile scene does not instantiate a HairballProjectile.")
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()

	parent.add_child(projectile)
	projectile.global_transform = hairball_spawn.global_transform
	projectile.configure(hairball_data, self, _current_facing_direction())

	_hairball_cooldown_remaining = hairball_data.cooldown
	hairball_cooldown_changed.emit(_hairball_cooldown_remaining, hairball_data.cooldown)


func _update_hairball_cooldown(delta: float) -> void:
	if hairball_data == null or _hairball_cooldown_remaining <= 0.0:
		return

	_hairball_cooldown_remaining = maxf(_hairball_cooldown_remaining - delta, 0.0)
	hairball_cooldown_changed.emit(_hairball_cooldown_remaining, hairball_data.cooldown)
