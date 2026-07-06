extends Control

@export_node_path("Label") var lives_value_path: NodePath = ^"MarginContainer/VBoxContainer/LivesRow/LivesValue"
@export_node_path("ProgressBar") var hairball_cooldown_path: NodePath = ^"MarginContainer/VBoxContainer/HairballRow/HairballCooldown"

@onready var lives_value: Label = get_node_or_null(lives_value_path)
@onready var hairball_cooldown: ProgressBar = get_node_or_null(hairball_cooldown_path)


func _ready() -> void:
	set_lives(9, 9)
	set_hairball_cooldown(0.0, 1.0)


func set_lives(current_lives: int, max_lives: int) -> void:
	if lives_value == null:
		return

	lives_value.text = "%d / %d" % [current_lives, max_lives]


func set_hairball_cooldown(remaining: float, cooldown: float) -> void:
	if hairball_cooldown == null:
		return

	var max_cooldown := maxf(cooldown, 0.001)
	hairball_cooldown.max_value = max_cooldown
	hairball_cooldown.value = max_cooldown - clampf(remaining, 0.0, max_cooldown)
