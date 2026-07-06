extends Node3D

signal unplugged

@export var unplug_hit_type: StringName = &"claw"
@export var unplug_effect_scene: PackedScene

var is_unplugged: bool = false


func on_hurtbox_hit(hit_data: Dictionary) -> bool:
	if is_unplugged:
		return true

	if hit_data.get("hit_type") != unplug_hit_type:
		return false

	is_unplugged = true
	_spawn_unplug_effect()
	unplugged.emit()
	return true


func _spawn_unplug_effect() -> void:
	if unplug_effect_scene == null:
		return

	var effect := unplug_effect_scene.instantiate() as Node3D
	if effect == null:
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = self

	parent.add_child(effect)
	effect.global_position = global_position
