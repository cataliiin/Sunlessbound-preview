extends CharacterBody3D

enum PlayerState {
	walking,
	running,
	crouching
}

var state: PlayerState = PlayerState.walking

# VARIABLES

@export_category("Player")

@export_group("Movement")

@export_group("Movement/General")
@export_range(1, 60, 0.1) var walk_movement_speed: float = 1.8
@export_range(0.1, 30, 0.1) var gravity: float = 15.5

@export_group("Movement/Acceleration")
@export_range(0.1, 60, 0.1) var horizontal_air_acceleration: float = 3
@export_range(0.1, 60, 0.1) var horizontal_normal_acceleration: float = 4
@export_range(0.1, 60, 0.1) var horizontal_air_deceleration: float = 3
@export_range(0.1, 60, 0.1) var horizontal_normal_deceleration: float = 8

@export_group("Movement/Run")
@export var can_run: bool = true
@export_range(1, 60, 0.1) var run_movement_speed: float = 3.0
@export_group("Movement/Run/DynamicFov")
@export var dymanic_fov: bool = true
@export_range(1, 100, 1) var fov_lerp_speed: float = 3
@export_range(50, 120, 1) var default_fov: float = 78
@export_range(50, 120, 1) var running_fov: float = 83

@export_group("Movement/Crouch")
@export var can_crouch = true
@export_range(1, 60, 0.1) var crouch_movement_speed: float = 1.2
@export_range(0.1, 50, 0.1) var crouch_speed: float = 5.2
@export_range(0.1, 10, 0.1) var crouching_player_height: float = 1.0

@export_group("Movement/Jump")
@export var can_jump: bool = true
@export_range(0.1, 30, 0.1) var jump_force: float = 4.0

# FOR OTHER SCRIPTS
@export_group("Mouse")
@export_range(1, 100, 1) var mouse_sensitivity: float = 9

@export_group("HeadBoobing")
@export var headbob: bool = true
@export_range(0.1, 30, 0.1) var hb_lerp_speed = 3.0
@export_group("HeadBoobing/speed")
@export_range(0.1, 30, 0.1) var hb_running_speed = 16.0 
@export_range(0.1, 30, 0.1) var hb_walking_speed = 12.0
@export_range(0.1, 30, 0.1) var hb_crouching_speed = 8.0
@export_group("HeadBoobing/intensity")
@export_range(0.01, 30, 0.01) var hb_running_intensity = 0.1
@export_range(0.01, 30, 0.01) var hb_walking_intensity = 0.08
@export_range(0.01, 30, 0.01) var hb_crouching_intensity = 0.07

@export_group("JumpNudge")
@export var jump_nudge: bool = true
@export_range(0.01, 10, 0.01) var landing_nudge_intensity_multiplier: float = 1.0  # Fine-tune overall intensity
@export_range(0.01, 10, 0.01) var landing_nudge_base_intensity: float = 0.07  # Base intensity of the nudge
@export_range(0.01, 10, 0.01) var landing_nudge_velocity_scale: float = 0.07  # Scale factor for velocity
@export_range(0.01, 10, 0.01) var landing_nudge_duration: float = 0.1        # Duration of the nudge in seconds
@export var nudge_target_y: float = 0.0                # Target Y position for the nudge

var movement_speed: float = 0
var current_h_acceleration: float = 0
var current_h_deceleration: float = 0

var initial_player_height: float
var initial_head_height: float

var direction: Vector3
var horizontal_velocity = Vector3()
var gravity_vector = Vector3()

var was_in_air_last_frame: bool = false
var downward_velocity: float = 0


# NODES

@onready var camera: Camera3D = $Head/Eyes/Camera3D
@onready var player_collision_shape: CollisionShape3D = $CollisionShape3D
@onready var player_head: Node3D = $Head
@onready var head_raycast: RayCast3D = $HeadRayCast

func _ready():
	initial_player_height = player_collision_shape.shape.height
	initial_head_height = player_head.position.y

func _physics_process(delta):
	
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input_direction.x, 0,input_direction.y )).normalized()
	
	if not is_on_floor():
		gravity_vector += Vector3.DOWN * gravity * delta
		current_h_acceleration = horizontal_air_acceleration
		current_h_deceleration = horizontal_air_deceleration
		was_in_air_last_frame = true
		downward_velocity = velocity.y
	else:
		gravity_vector = -get_floor_normal()
		current_h_acceleration = horizontal_normal_acceleration
		current_h_deceleration = horizontal_normal_deceleration
		
		if was_in_air_last_frame:
			camera.on_land(downward_velocity)
			was_in_air_last_frame = false
	
	if is_on_ceiling():
		gravity_vector = Vector3(0,-0.1,0)
	
	if can_jump:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			gravity_vector = Vector3.UP * jump_force
	
	if can_run:
		if Input.is_action_pressed("run"):
			if input_direction.y < 0:
				movement_speed = run_movement_speed
				state = PlayerState.running
			else:
				movement_speed = run_movement_speed * 0.65
		else:
			movement_speed = walk_movement_speed
			state = PlayerState.walking
	else: 
		movement_speed = walk_movement_speed
		state = PlayerState.walking
	
	if can_crouch:
		handle_crouch(delta)
	
	# Calculate horizontal speed using proper lerp
	var desired_horizontal_velocity = direction * movement_speed * speed_multiplier
	if direction != Vector3.ZERO:
		horizontal_velocity = horizontal_velocity.lerp(desired_horizontal_velocity, current_h_acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, current_h_deceleration * delta)
	
	# Combine velocities
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = gravity_vector.y
	
	# Move
	move_and_slide()

func handle_crouch(delta):
	
	if Input.is_action_pressed("crouch"):
		state = PlayerState.crouching
		movement_speed = crouch_movement_speed
		
		player_collision_shape.shape.height = lerp(player_collision_shape.shape.height, crouching_player_height, delta * crouch_speed)
		player_head.position.y = lerp(player_head.position.y, (initial_player_height-crouching_player_height) / 2 + (crouching_player_height / 4) * 3, delta * crouch_speed)
		head_raycast.position.y = lerp(head_raycast.position.y, (initial_player_height-crouching_player_height) / 2 + crouching_player_height, delta * crouch_speed)
	elif !head_raycast.is_colliding() and !is_on_ceiling():
		player_collision_shape.shape.height = lerp(player_collision_shape.shape.height, initial_player_height, delta * crouch_speed)
		player_head.position.y = lerp(player_head.position.y, initial_head_height, delta * crouch_speed)
		head_raycast.position.y = lerp(head_raycast.position.y, initial_player_height, delta * crouch_speed)
	
	if head_raycast.is_colliding() and is_on_floor():
		state = PlayerState.crouching
		movement_speed = crouch_movement_speed

# Vitals 

var speed_multiplier: float = 1.0

func modify_speed_multiplier(v: float) -> void:
	speed_multiplier = v
