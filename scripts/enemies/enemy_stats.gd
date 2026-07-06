class_name EnemyStats
extends HealthStats

@export_group("Movement")
@export var patrol_speed: float = 1.2
@export var chase_speed: float = 2.0
@export var turn_rate: float = 8.0
@export var waypoint_arrival_distance: float = 0.25

@export_group("Detection")
@export var detection_radius: float = 3.2
@export var charge_commit_distance: float = 1.7

@export_group("Charge")
@export var charge_damage: int = 1
@export var charge_stagger: float = 0.85
@export var charge_knockback_force: float = 3.0
@export var charge_speed: float = 4.8
@export var charge_windup: float = 0.45
@export var charge_recovery: float = 0.7

@export_group("Weaknesses")
@export var cord_unplug_stagger_duration: float = 2.0
@export var cord_unplug_shutdown: bool = true
@export var water_instant_defeat: bool = true
