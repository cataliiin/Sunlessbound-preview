extends Node3D

# could add a message to show beside the crosshair

@export var actionable_nodes: Array[Node]

func interact() -> void:
	print("button interact")
	for node in actionable_nodes:
		if node != null:
			if node.has_method("on_button_pressed"):
				node.on_button_pressed()
			elif node.has_method("interact"):
				node.interact()
