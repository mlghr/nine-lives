class_name HitboxArea
extends Area3D

@export var damage: int = 1
@export var stagger: float = 0.25
@export var knockback_force: float = 0.0
@export_range(0.0, 1.0, 0.01) var knockdown_chance: float = 0.0
@export var invulnerable_time: float = 0.2
@export var hit_type: StringName = &"claw"
@export_node_path("Node") var source_path: NodePath = ^"../.."

@export var enabled: bool = false:
	set(value):
		enabled = value
		monitoring = value

@onready var source: Node = get_node_or_null(source_path)


func _ready() -> void:
	monitoring = enabled
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if not enabled or source == null:
		return

	if area.owner == source:
		return

	if area.has_method("receive_hit"):
		area.receive_hit(_build_hit_data())


func _build_hit_data() -> Dictionary:
	return {
		"source": source,
		"damage": damage,
		"stagger": stagger,
		"knockback_force": knockback_force,
		"knockdown_chance": knockdown_chance,
		"invulnerable_time": invulnerable_time,
		"hit_type": hit_type,
		"direction": -global_transform.basis.z,
	}
