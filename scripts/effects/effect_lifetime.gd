class_name EffectLifetime
extends Node3D

@export var lifetime: float = 0.45
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"
@export var animation_name: StringName = &"burst"

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var _remaining: float = 0.0


func _ready() -> void:
	_remaining = lifetime
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
