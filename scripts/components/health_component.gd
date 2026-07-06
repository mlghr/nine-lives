class_name HealthComponent
extends Node

signal hit_received(hit_data: Dictionary)
signal stagger_started(duration: float)
signal lives_changed(current_lives: int, max_lives: int)
signal defeated

@export var stats: HealthStats
@export var invulnerable: bool = false
@export var damage_effect_scene: PackedScene
@export var stagger_effect_scene: PackedScene

var current_lives: int = 0
var stagger_buffer: float = 0.0

var _invulnerable_timer: float = 0.0


func _ready() -> void:
	if stats == null:
		push_error("HealthComponent requires a HealthStats resource.")
		return

	current_lives = stats.max_lives
	lives_changed.emit(current_lives, stats.max_lives)


func _process(delta: float) -> void:
	if stats == null:
		return

	if _invulnerable_timer > 0.0:
		_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
		if _invulnerable_timer == 0.0:
			invulnerable = false

	if stagger_buffer > 0.0:
		stagger_buffer = maxf(stagger_buffer - stats.stagger_buffer_recovery * delta, 0.0)


func apply_hit(hit_data: Dictionary) -> bool:
	if stats == null or invulnerable or current_lives <= 0:
		return false

	var damage := maxi(int(hit_data.get("damage", 1)), 0)
	var stagger := maxf(float(hit_data.get("stagger", 0.0)), 0.0)
	var invulnerable_time := maxf(float(hit_data.get("invulnerable_time", stats.default_invulnerable_time)), 0.0)

	hit_received.emit(hit_data)

	if damage > 0:
		current_lives = maxi(current_lives - damage, 0)
		lives_changed.emit(current_lives, stats.max_lives)
		_spawn_effect(damage_effect_scene)

	if stagger > 0.0:
		_apply_stagger(stagger)

	if invulnerable_time > 0.0:
		set_invulnerable_for(invulnerable_time)

	if current_lives == 0:
		stagger_started.emit(stats.defeat_stagger_time)
		defeated.emit()

	return true


func set_invulnerable_for(duration: float) -> void:
	invulnerable = true
	_invulnerable_timer = maxf(duration, 0.0)


func clear_invulnerability() -> void:
	invulnerable = false
	_invulnerable_timer = 0.0


func _apply_stagger(stagger: float) -> void:
	if stagger >= stats.small_hit_stagger_threshold:
		stagger_buffer = 0.0
		stagger_started.emit(stagger)
		_spawn_effect(stagger_effect_scene)
		return

	stagger_buffer += stagger
	if stagger_buffer >= stats.stagger_buffer_limit:
		stagger_buffer = 0.0
		stagger_started.emit(stagger)
		_spawn_effect(stagger_effect_scene)


func _spawn_effect(effect_scene: PackedScene) -> void:
	if effect_scene == null:
		return

	var owner_node := get_parent() as Node3D
	if owner_node == null:
		return

	var effect := effect_scene.instantiate() as Node3D
	if effect == null:
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = owner_node

	parent.add_child(effect)
	effect.global_position = owner_node.global_position
