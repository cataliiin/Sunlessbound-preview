extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			animation_player.play("fire")
