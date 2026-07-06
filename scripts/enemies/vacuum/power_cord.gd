extends Node3D

signal unplugged

@export var unplug_hit_type: StringName = &"claw"

var is_unplugged: bool = false


func on_hurtbox_hit(hit_data: Dictionary) -> bool:
	if is_unplugged:
		return true

	if hit_data.get("hit_type") != unplug_hit_type:
		return false

	is_unplugged = true
	unplugged.emit()
	return true
