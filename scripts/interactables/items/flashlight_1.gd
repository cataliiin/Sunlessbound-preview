extends Node3D
@onready var spot_light_3d: SpotLight3D = $SpotLight3D
@onready var spot_light_3d_2: SpotLight3D = $SpotLight3D2

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_item"):
		spot_light_3d.visible = !spot_light_3d.visible
		spot_light_3d_2.visible = !spot_light_3d_2.visible
