extends Node
"""
To setup dragging for the main node you need to:
	For draggable node define func:
	func get_drag_ghost():
	func get_drag_data():
	
	func on_drag():
	func drag_successful():
	func drag_failed():
	
	For receiver node:
	func receive_drop() -> bool:
"""

@export_group("Draggable")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var is_draggable: bool = false
@export var draggable_node: Control

@export_group("Receiver")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var is_receiver: bool = false
@export var receiver_node: Control

var is_dragging: bool

var drag_ghost: Control
var drag_data

func _ready() -> void:
	if is_draggable:
		draggable_node.connect("gui_input", _handle_gui_input_of_node)
		draggable_node.add_to_group("draggable_node")
	if is_receiver:
		receiver_node.connect("mouse_entered", mouse_entered_receiver)
		receiver_node.connect("mouse_exited", mouse_exited_receiver)
		receiver_node.add_to_group("drag_receiver_node")

func _handle_gui_input_of_node(event):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag()
		elif not event.pressed:
			stop_drag()
	elif event is InputEventMouseMotion and is_dragging:
		drag_ghost.global_position = get_viewport().get_mouse_position() - (drag_ghost.size/2)

func start_drag() -> void:
	is_dragging = true
	drag_ghost = draggable_node.get_drag_ghost()
	drag_data = draggable_node.get_drag_data()
	draggable_node.on_drag()
	drag_ghost.global_position = get_viewport().get_mouse_position() - (drag_ghost.size/2)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.z_index = 10
	get_tree().get_root().add_child(drag_ghost)

func stop_drag() -> void:
	is_dragging = false
	drag_ghost.queue_free()
	
	var target = GlobalUtils.current_receiver
	if target != null and target != get_tree().root and target != receiver_node:
		if target.has_method("receive_drop") and target.is_in_group("drag_receiver_node"):
			var result: bool = target.receive_drop(drag_data)
			if result:
				draggable_node.drag_successful()
				return
	draggable_node.drag_failed()

func mouse_entered_receiver():
	GlobalUtils.current_receiver = receiver_node

func mouse_exited_receiver():
	GlobalUtils.handle_mouse_exit(receiver_node)
