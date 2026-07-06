class_name HairballProjectile
extends Area3D

@export var data: HairballData

var source: Node
var direction: Vector3 = Vector3.FORWARD

var _lifetime_remaining: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if data != null:
		_lifetime_remaining = data.lifetime
		_apply_data_to_shape()


func configure(projectile_data: HairballData, projectile_source: Node, travel_direction: Vector3) -> void:
	data = projectile_data
	source = projectile_source
	direction = travel_direction.normalized()
	if direction.length_squared() == 0.0:
		direction = Vector3.FORWARD

	_lifetime_remaining = data.lifetime if data != null else 0.0
	_apply_data_to_shape()


func _physics_process(delta: float) -> void:
	if data == null:
		queue_free()
		return

	global_position += direction * data.speed * delta
	_lifetime_remaining -= delta
	if _lifetime_remaining <= 0.0:
		queue_free()


func _on_area_entered(area: Area3D) -> void:
	if data == null:
		return

	if source != null and area.owner == source:
		return

	if area.has_method("receive_hit"):
		area.receive_hit({
			"source": source,
			"damage": data.damage,
			"stagger": data.stagger,
			"knockback_force": data.knockback_force,
			"hit_type": &"hairball",
			"direction": direction,
		})
		queue_free()


func _apply_data_to_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if data == null or shape_node == null or not shape_node.shape is SphereShape3D:
		return

	(shape_node.shape as SphereShape3D).radius = data.radius
