extends Node3D

@export var open: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func interact() -> void:
	if !animation_player.is_playing():
		if open:
			animation_player.play("close")
			open = false
		else:
			animation_player.play("open")
			open = true
