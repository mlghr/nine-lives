extends Control

@export_node_path("Label") var lives_value_path: NodePath = ^"MarginContainer/VBoxContainer/LivesRow/LivesValue"
@export_node_path("ProgressBar") var hairball_cooldown_path: NodePath = ^"MarginContainer/VBoxContainer/HairballRow/HairballCooldown"
@export_node_path("Label") var danger_state_path: NodePath = ^"FeedbackLayer/DangerState"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"

@onready var lives_value: Label = get_node_or_null(lives_value_path)
@onready var hairball_cooldown: ProgressBar = get_node_or_null(hairball_cooldown_path)
@onready var danger_state: Label = get_node_or_null(danger_state_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var _last_lives: int = -1
var _last_hairball_remaining: float = 0.0


func _ready() -> void:
	set_lives(9, 9)
	set_hairball_cooldown(0.0, 1.0)


func set_lives(current_lives: int, max_lives: int) -> void:
	if lives_value == null:
		return

	if _last_lives >= 0 and current_lives < _last_lives:
		_play_feedback(&"life_loss_flash")

	_last_lives = current_lives
	lives_value.text = "%d / %d" % [current_lives, max_lives]
	if danger_state != null:
		danger_state.visible = current_lives > 0 and current_lives <= 2


func set_hairball_cooldown(remaining: float, cooldown: float) -> void:
	if hairball_cooldown == null:
		return

	var max_cooldown := maxf(cooldown, 0.001)
	hairball_cooldown.max_value = max_cooldown
	hairball_cooldown.value = max_cooldown - clampf(remaining, 0.0, max_cooldown)
	if _last_hairball_remaining > 0.0 and remaining == 0.0:
		_play_feedback(&"cooldown_ready_ping")

	_last_hairball_remaining = remaining


func show_victory() -> void:
	_play_feedback(&"cooldown_ready_ping")


func show_game_over() -> void:
	_play_feedback(&"life_loss_flash")


func _play_feedback(animation_name: StringName) -> void:
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
