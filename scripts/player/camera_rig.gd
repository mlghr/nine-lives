extends Node3D

@export var stats: PlayerStats
@export_node_path("Node3D") var yaw_pivot_path: NodePath = ^"YawPivot"
@export_node_path("Node3D") var pitch_pivot_path: NodePath = ^"YawPivot/PitchPivot"
@export_node_path("SpringArm3D") var camera_boom_path: NodePath = ^"YawPivot/PitchPivot/CameraBoom"

@onready var yaw_pivot: Node3D = get_node_or_null(yaw_pivot_path)
@onready var pitch_pivot: Node3D = get_node_or_null(pitch_pivot_path)
@onready var camera_boom: SpringArm3D = get_node_or_null(camera_boom_path)

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	if stats == null:
		push_error("CameraRig requires a PlayerStats resource.")
		return

	if yaw_pivot == null or pitch_pivot == null:
		push_error("CameraRig is missing its yaw or pitch pivot.")
		return

	_yaw = yaw_pivot.rotation.y
	_pitch = pitch_pivot.rotation.x
	_apply_camera_stats()


func _unhandled_input(event: InputEvent) -> void:
	if stats == null:
		return

	if event is InputEventMouseMotion:
		_apply_look_delta(event.relative.x * stats.mouse_sensitivity, event.relative.y * stats.mouse_sensitivity)


func _process(delta: float) -> void:
	if stats == null:
		return

	var look_input := Input.get_vector("camera_look_left", "camera_look_right", "camera_look_up", "camera_look_down")
	if look_input.length() <= stats.controller_look_deadzone:
		return

	_apply_look_delta(look_input.x * stats.controller_look_speed * delta, look_input.y * stats.controller_look_speed * delta)


func _apply_look_delta(yaw_delta: float, pitch_delta: float) -> void:
	if yaw_pivot == null or pitch_pivot == null:
		return

	_yaw += yaw_delta
	_pitch = clampf(
		_pitch + pitch_delta,
		deg_to_rad(stats.min_pitch_degrees),
		deg_to_rad(stats.max_pitch_degrees)
	)

	yaw_pivot.rotation.y = _yaw
	pitch_pivot.rotation.x = _pitch


func _apply_camera_stats() -> void:
	if camera_boom == null:
		return

	camera_boom.spring_length = stats.camera_boom_length
	camera_boom.margin = stats.camera_collision_margin
