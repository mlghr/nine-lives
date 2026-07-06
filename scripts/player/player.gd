extends CharacterBody3D

@export var stats: PlayerStats
@export_node_path("Node3D") var model_root_path: NodePath = ^"ModelRoot"
@export_node_path("Node3D") var camera_rig_path: NodePath = ^"CameraRig"

@onready var model_root: Node3D = get_node_or_null(model_root_path)
@onready var camera_rig: Node3D = get_node_or_null(camera_rig_path)

var _coyote_timer: float = 0.0


func _ready() -> void:
	if stats == null:
		push_error("Player requires a PlayerStats resource.")


func _physics_process(delta: float) -> void:
	if stats == null:
		return

	var movement_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := _camera_relative_direction(movement_input)
	var target_velocity := move_direction * _target_speed(movement_input.length())
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

	if Input.is_action_just_pressed("jump") and _coyote_timer > 0.0:
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
