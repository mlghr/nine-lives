class_name DebugOverlay
extends CanvasLayer

@export_node_path("Label") var readout_path: NodePath = ^"MarginContainer/PanelContainer/Readout"
@export var refresh_interval: float = 0.1

@onready var readout: Label = get_node_or_null(readout_path)

var _player: CharacterBody3D
var _enabled: bool = true
var _refresh_timer: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func configure(player: Node, enabled: bool, starts_visible: bool = false) -> void:
	_player = player as CharacterBody3D
	_enabled = enabled
	visible = enabled and starts_visible
	set_process(visible)
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event.is_action_pressed("debug_toggle"):
		visible = not visible
		set_process(visible)
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_respawn"):
		_respawn_to_nearest_marker()
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return

	_refresh_timer = maxf(refresh_interval, 0.01)
	_refresh()


func _refresh() -> void:
	if readout == null:
		return

	if _player == null:
		readout.text = "Debug overlay\nPlayer: missing"
		return

	var debug_state: Dictionary = {}
	if _player.has_method("get_debug_state"):
		debug_state = _player.call("get_debug_state")

	var velocity := _player.velocity
	var speed_2d := Vector2(velocity.x, velocity.z).length()
	var state := String(debug_state.get("combat_state", "unknown"))
	var iframes := bool(debug_state.get("invulnerable", false))
	var hairball_remaining := float(debug_state.get("hairball_remaining", 0.0))
	var hairball_cooldown := float(debug_state.get("hairball_cooldown", 0.0))
	var stats_path := String(debug_state.get("stats_resource", "<none>"))

	readout.text = "\n".join([
		"Debug Overlay",
		"State: %s" % state,
		"Velocity: %.2f, %.2f, %.2f" % [velocity.x, velocity.y, velocity.z],
		"Ground speed: %.2f" % speed_2d,
		"I-frames: %s" % ("yes" if iframes else "no"),
		"Hairball: %.2f / %.2f" % [hairball_remaining, hairball_cooldown],
		"Stats: %s" % stats_path,
	])


func _respawn_to_nearest_marker() -> void:
	if _player == null:
		return

	var markers := get_tree().get_nodes_in_group("debug_respawn")
	if markers.is_empty():
		return

	var nearest_marker: Marker3D
	var nearest_distance := INF
	for marker in markers:
		var marker_3d := marker as Marker3D
		if marker_3d == null:
			continue

		var distance := _player.global_position.distance_squared_to(marker_3d.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_marker = marker_3d

	if nearest_marker == null:
		return

	_player.global_transform = nearest_marker.global_transform
	_player.velocity = Vector3.ZERO
