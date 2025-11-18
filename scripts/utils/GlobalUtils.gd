extends Node

var day_lenght: int = 15 * 60  # in seconds

func has_property(argument: String, node: Node) -> bool:
	var script = node.get_script()
	if script == null:
		return false
	var property_list = script.get_script_property_list()
	for property_dict in property_list:
		var property_name = property_dict.get("name", "")
		if property_name == argument:
			return true
	return false

# Drag and drop

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("interact"):
		#print(current_receiver)

var current_receiver = null

func handle_mouse_exit(receiver_node):
	if current_receiver == receiver_node:
		current_receiver = null
