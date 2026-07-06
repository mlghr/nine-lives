extends Node3D

@export_node_path("Node") var player_path: NodePath = ^"Player"
@export_node_path("Control") var hud_path: NodePath = ^"HUD"
@export_node_path("DebugOverlay") var debug_overlay_path: NodePath = ^"DebugOverlay"
@export var debug_overlay_enabled: bool = true
@export var debug_overlay_starts_visible: bool = false

@onready var player: Node = get_node_or_null(player_path)
@onready var hud: Control = get_node_or_null(hud_path)
@onready var debug_overlay: DebugOverlay = get_node_or_null(debug_overlay_path)


func _ready() -> void:
	if player == null or hud == null:
		return

	var health_component := player.get_node_or_null("HealthComponent") as HealthComponent
	if health_component != null:
		health_component.lives_changed.connect(_on_lives_changed)
		hud.call("set_lives", health_component.current_lives, health_component.stats.max_lives)

	if player.has_signal("hairball_cooldown_changed"):
		player.hairball_cooldown_changed.connect(_on_hairball_cooldown_changed)

	if player.has_signal("catnip_rage_changed"):
		player.catnip_rage_changed.connect(_on_catnip_rage_changed)

	if debug_overlay != null:
		debug_overlay.configure(player, debug_overlay_enabled, debug_overlay_starts_visible)

	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null and game_manager.has_method("bind_hub"):
		game_manager.call("bind_hub", self)


func _on_lives_changed(current_lives: int, max_lives: int) -> void:
	if hud != null:
		hud.call("set_lives", current_lives, max_lives)


func _on_hairball_cooldown_changed(remaining: float, cooldown: float) -> void:
	if hud != null:
		hud.call("set_hairball_cooldown", remaining, cooldown)


func _on_catnip_rage_changed(active: bool, remaining: float, duration: float, cooldown_remaining: float, cooldown: float, unlocked: bool) -> void:
	if hud != null:
		hud.call("set_catnip_rage", active, remaining, duration, cooldown_remaining, cooldown, unlocked)
