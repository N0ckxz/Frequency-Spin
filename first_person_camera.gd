extends CharacterBody3D

signal station_changed(new_index: int)

# Station rotation settings
@export var ROTATION_SPEED: float = 8.0
var target_y_rotation: float = 0.0
var current_station_index: int = 0

# Four stations: 0: Front (Radio), 1: Right (Decoder), 2: Back (Terminal), 3: Left (Manual)
const STATION_ANGLES = [0.0, -PI/2, -PI, PI/2]

@onready var twist_pivot: Node3D = $TwistPivot
@onready var pitch_pivot: Node3D = $TwistPivot/PitchPivot

var spin_sound: AudioStreamPlayer

func _ready() -> void:
	# Capture the mouse so it doesn't leave the game window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_y_rotation = STATION_ANGLES[current_station_index]
	twist_pivot.rotation.y = target_y_rotation
	
	spin_sound = AudioStreamPlayer.new()
	spin_sound.stream = load("res://sfx/game jam sfx/table spin & snap (fast).mp3")
	add_child(spin_sound)
	
	# Give the scene a moment to load before emitting the initial station
	call_deferred("_emit_initial_station")

func _emit_initial_station() -> void:
	station_changed.emit(current_station_index)

func _unhandled_input(event: InputEvent) -> void:
	# Release mouse toggle (useful for debugging)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Handle rotation between stations using A and D keys
	var changed = false
	if event.is_action_pressed("move_right"):
		current_station_index = (current_station_index + 1) % 4
		target_y_rotation = STATION_ANGLES[current_station_index]
		changed = true
	elif event.is_action_pressed("move_left"):
		current_station_index = (current_station_index - 1 + 4) % 4
		target_y_rotation = STATION_ANGLES[current_station_index]
		changed = true
		
	if changed:
		spin_sound.play()
		station_changed.emit(current_station_index)
		
	# Allow minor vertical free look (FNAF style panning)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var MOUSE_SENSITIVITY = 0.003
		# PitchPivot rotates up and down (X axis)
		pitch_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Clamp to prevent looking completely upside down
		pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))

func _physics_process(delta: float) -> void:
	# Smoothly interpolate the twist pivot towards the target rotation
	twist_pivot.rotation.y = lerp_angle(twist_pivot.rotation.y, target_y_rotation, ROTATION_SPEED * delta)
	
	# The player remains stationary at the center of the shack
	velocity = Vector3.ZERO
	move_and_slide()
