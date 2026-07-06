class_name PlayerStats
extends Resource

@export_group("Movement")
@export var walk_speed: float = 2.2
@export var run_speed: float = 4.4
@export var walk_input_threshold: float = 0.35
@export var run_input_threshold: float = 0.95
@export var acceleration: float = 18.0
@export var deceleration: float = 24.0
@export var air_acceleration: float = 7.0
@export var turn_speed: float = 12.0
@export var facing_deadzone: float = 0.05

@export_group("Jump")
@export var jump_velocity: float = 4.2
@export var gravity: float = 12.5
@export var coyote_time: float = 0.12
@export var grounded_snap_velocity: float = -0.1

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var controller_look_speed: float = 2.4
@export var controller_look_deadzone: float = 0.12
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 18.0
@export var camera_boom_length: float = 2.4
@export var camera_collision_margin: float = 0.08
