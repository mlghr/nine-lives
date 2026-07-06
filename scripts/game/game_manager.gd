extends Node

@export var objective_state: ObjectiveState
@export var restart_delay: float = 1.2

var _hud: Control
var _gate_cleared_visual: Node3D
var _restarting: bool = false


func _ready() -> void:
	if objective_state != null:
		objective_state = objective_state.duplicate(true) as ObjectiveState
		objective_state.reset()


func bind_hub(hub: Node) -> void:
	if hub == null:
		return

	_restarting = false
	_hud = hub.get_node_or_null("HUD") as Control
	_gate_cleared_visual = hub.get_node_or_null("KitchenBlockedDoorway/GateClearedVisual") as Node3D
	if _gate_cleared_visual != null:
		_gate_cleared_visual.visible = objective_state != null and objective_state.completed

	var player := hub.get_node_or_null("Player")
	if player != null:
		var health_component := player.get_node_or_null("HealthComponent") as HealthComponent
		if health_component != null and not health_component.defeated.is_connected(_on_player_defeated):
			health_component.defeated.connect(_on_player_defeated)

	var living_room := hub.get_node_or_null("LivingRoom")
	if living_room != null:
		if living_room.has_signal("room_entered") and not living_room.room_entered.is_connected(_on_living_room_entered):
			living_room.room_entered.connect(_on_living_room_entered)
		if living_room.has_signal("blockers_cleared") and not living_room.blockers_cleared.is_connected(_on_living_room_completed):
			living_room.blockers_cleared.connect(_on_living_room_completed)


func _on_living_room_entered() -> void:
	if objective_state != null:
		objective_state.room_entered = true


func _on_living_room_completed() -> void:
	if objective_state != null:
		objective_state.completed = true

	if _gate_cleared_visual != null:
		_gate_cleared_visual.visible = true

	if _hud != null and _hud.has_method("show_victory"):
		_hud.call("show_victory")


func _on_player_defeated() -> void:
	if _restarting:
		return

	_restarting = true
	if _hud != null and _hud.has_method("show_game_over"):
		_hud.call("show_game_over")

	await get_tree().create_timer(restart_delay).timeout
	if objective_state != null:
		objective_state.reset()

	get_tree().reload_current_scene()
