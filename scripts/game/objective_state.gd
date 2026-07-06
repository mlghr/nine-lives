class_name ObjectiveState
extends Resource

@export var objective_name: String = "Clear the Living Room"
@export var room_entered: bool = false
@export var completed: bool = false


func reset() -> void:
	room_entered = false
	completed = false
