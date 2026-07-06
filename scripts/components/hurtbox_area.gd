class_name HurtboxArea
extends Area3D

@export_node_path("Node") var target_path: NodePath = ^"../.."
@export_node_path("HealthComponent") var health_component_path: NodePath = ^"../../HealthComponent"
@export var hit_marker: StringName = &""

@onready var target: Node = get_node_or_null(target_path)
@onready var health_component: HealthComponent = get_node_or_null(health_component_path)


func receive_hit(hit_data: Dictionary) -> bool:
	if hit_marker != &"":
		hit_data = hit_data.duplicate()
		hit_data["hurtbox_marker"] = hit_marker

	if target != null and hit_data.get("source") == target:
		return false

	if target != null and target.has_method("on_hurtbox_hit") and target.on_hurtbox_hit(hit_data):
		return true

	if health_component == null:
		push_warning("%s received a hit without a HealthComponent." % name)
		return false

	return health_component.apply_hit(hit_data)
