extends Node3D

signal room_entered
signal blockers_cleared

@export_node_path("Area3D") var entry_trigger_path: NodePath = ^"EncounterAuthoring/EntryTrigger"
@export_node_path("Node3D") var vacuum_path: NodePath = ^"Vacuum"
@export_node_path("Node3D") var robot_vacuum_path: NodePath = ^"RobotVacuum"

@onready var entry_trigger: Area3D = get_node_or_null(entry_trigger_path)
@onready var vacuum: Node = get_node_or_null(vacuum_path)
@onready var robot_vacuum: Node = get_node_or_null(robot_vacuum_path)

var _entered: bool = false
var _vacuum_disabled: bool = false
var _robot_disabled: bool = false
var _cleared: bool = false


func _ready() -> void:
	if entry_trigger != null:
		entry_trigger.body_entered.connect(_on_entry_trigger_body_entered)

	if vacuum != null and vacuum.has_signal("disabled"):
		vacuum.disabled.connect(_on_vacuum_disabled)

	if robot_vacuum != null and robot_vacuum.has_signal("disabled"):
		robot_vacuum.disabled.connect(_on_robot_disabled)


func _on_entry_trigger_body_entered(body: Node3D) -> void:
	if _entered or not _is_player_candidate(body):
		return

	_entered = true
	room_entered.emit()
	print("Living room objective: room entered")


func _on_vacuum_disabled(_reason: StringName) -> void:
	_vacuum_disabled = true
	_check_blockers_cleared()


func _on_robot_disabled(_reason: StringName) -> void:
	_robot_disabled = true
	_check_blockers_cleared()


func _check_blockers_cleared() -> void:
	if _cleared or not (_vacuum_disabled and _robot_disabled):
		return

	_cleared = true
	blockers_cleared.emit()
	print("Living room objective: blockers cleared")


func _is_player_candidate(body: Node) -> bool:
	return body.name == "Player" or body.is_in_group("player")
