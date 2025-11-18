extends Node3D

@export_node_path("Node3D") var head_nodepath: NodePath
@export_node_path("CharacterBody3D") var player_nodepath: NodePath

var mouse_sensitivity : float
var mouse_smoothness : float = 0.2

var target_camera_input : Vector2 = Vector2.ZERO
var smoothed_camera_input : Vector2 = Vector2.ZERO

@onready var head: Node3D = get_node(head_nodepath)
@onready var player: CharacterBody3D = get_node(player_nodepath)

# HEAD BOBBING VARIABLES
var hb_lerp_speed: float = 10.0
var hb_running_speed: float = 16.0
var hb_walking_speed: float = 12.0
var hb_crouching_speed: float = 8.0

var hb_running_intensity: float = 0.10
var hb_walking_intensity: float = 0.08
var hb_crouching_intensity: float = 0.07

var hb_vector: Vector3 = Vector3.ZERO
var hb_index: float = 0.0
var hb_current_intensity: float = 0.0

@onready var player_eyes = $".."

# LANDING NUDGE VARIABLES
var landing_nudge_intensity_multiplier: float = 1.0
var landing_nudge_base_intensity: float = 0.07
var landing_nudge_velocity_scale: float = 0.07
var landing_nudge_duration: float = 0.1
var landing_nudge_timer: float = 0.0
var is_nudging: bool = false
var nudge_target_y: float = 0.0

# DYNAMIC FOV VARIABLES
var fov_lerp_speed : float
var default_fov : float
var running_fov : float

func _ready():
	mouse_sensitivity = player.mouse_sensitivity / 100
	
	hb_lerp_speed = player.hb_lerp_speed
	hb_running_speed = player.hb_running_speed
	hb_walking_speed = player.hb_walking_speed
	hb_crouching_speed = player.hb_crouching_speed
	
	hb_running_intensity = player.hb_running_intensity
	hb_walking_intensity = player.hb_walking_intensity
	hb_crouching_intensity = player.hb_crouching_intensity
	
	landing_nudge_intensity_multiplier = player.landing_nudge_intensity_multiplier
	landing_nudge_base_intensity = player.landing_nudge_base_intensity
	landing_nudge_velocity_scale = player.landing_nudge_velocity_scale
	landing_nudge_duration = player.landing_nudge_duration
	nudge_target_y = player.nudge_target_y
	
	fov_lerp_speed = player.fov_lerp_speed
	default_fov = player.default_fov
	running_fov = player.running_fov
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		target_camera_input += event.relative * mouse_sensitivity
	
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var smoothing_factor := 1.0 - pow(mouse_smoothness, delta * 60)
	
	smoothed_camera_input = smoothed_camera_input.lerp(target_camera_input, smoothing_factor)
	
	player.rotate_y(deg_to_rad(-smoothed_camera_input.x))
	head.rotate_x(deg_to_rad(-smoothed_camera_input.y))
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	target_camera_input = Vector2.ZERO
	
	if player.headbob:
		head_boobing(delta)
	
	if player.dymanic_fov:
		dynamic_fov(delta)
	
	if is_nudging:
		landing_nudge_timer -= delta
		if landing_nudge_timer > 0:
			if abs(player_eyes.position.y - nudge_target_y) > 0.001:
				player_eyes.position.y = lerp(player_eyes.position.y, nudge_target_y, delta * 10.0)
		else:
			is_nudging = false
			player_eyes.position.y = lerp(player_eyes.position.y, 0.0, delta * 10.0)

func head_boobing(delta):
	match player.state:
		player.PlayerState.running:
			hb_current_intensity = hb_running_intensity
			hb_index += hb_running_speed * delta
		player.PlayerState.walking:
			hb_current_intensity = hb_walking_intensity
			hb_index += hb_walking_speed * delta
		player.PlayerState.crouching:
			hb_current_intensity = hb_crouching_intensity
			hb_index += hb_crouching_speed * delta
	
	if player.is_on_floor() and player.direction != Vector3.ZERO:
		hb_vector.x = sin(hb_index/2)+0.5
		hb_vector.y = sin(hb_index)
		hb_vector.z = sin(hb_index/2)*0.1
		
		player_eyes.position.x = lerp(player_eyes.position.x, hb_vector.x * hb_current_intensity, delta * hb_lerp_speed)
		player_eyes.position.y = lerp(player_eyes.position.y, hb_vector.y * (hb_current_intensity/2), delta * hb_lerp_speed)
		player_eyes.rotation.z = lerp(player_eyes.rotation.z, hb_vector.z * hb_current_intensity, delta * hb_lerp_speed)
	else:
		player_eyes.position.x = lerp(player_eyes.position.x, 0.0, delta * hb_lerp_speed)
		player_eyes.position.y = lerp(player_eyes.position.y, 0.0, delta * hb_lerp_speed)
		player_eyes.rotation.z = lerp(player_eyes.rotation.z, 0.0, delta * hb_lerp_speed)

func on_land(velocity: float) -> void:
	var nudge_intensity = (landing_nudge_base_intensity + abs(velocity) * landing_nudge_velocity_scale) * landing_nudge_intensity_multiplier
	nudge_target_y = -nudge_intensity
	is_nudging = true
	landing_nudge_timer = landing_nudge_duration
	
func dynamic_fov(delta):
	if player.state == player.PlayerState.running and player.direction != Vector3.ZERO and self.fov != running_fov:
		self.fov = lerp(self.fov, running_fov, delta * fov_lerp_speed)
	elif self.fov != default_fov:
		self.fov = lerp(self.fov, default_fov, delta * fov_lerp_speed)
