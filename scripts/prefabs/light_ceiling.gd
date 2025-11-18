extends Node3D

var on = false

var mat_ref

@onready var lamp_0: MeshInstance3D = $lamp_0
@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@onready var omni_light_3d_2: OmniLight3D = $OmniLight3D2

func on_button_pressed() -> void:
	if mat_ref == null:
		mat_ref = lamp_0.get_active_material(2)
	if on:
		omni_light_3d.visible = false
		omni_light_3d_2.visible = false
		mat_ref.emmision_enabled = false
		on = false
	else:
		omni_light_3d.visible = true
		omni_light_3d_2.visible = true
		mat_ref.emmision_enabled = true
		on = true
