class_name RobotVacuumStats
extends EnemyStats

@export_group("Robot Vacuum")
@export var erratic_turn_interval_min: float = 0.35
@export var erratic_turn_interval_max: float = 0.9
@export var bump_damage: int = 1
@export var bump_stagger: float = 0.45
@export var bump_knockback_force: float = 1.8
@export var pounce_flip_height_margin: float = 0.15
@export var helpless_duration: float = 3.0
@export var stair_fall_instant_defeat: bool = true
