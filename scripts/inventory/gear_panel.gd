extends Panel

@onready var custom_slot_primary: Panel = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/CustomSlotPrimary
@onready var custom_slot_secondary: Panel = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/CustomSlotSecondary

func get_primary_item() -> InventoryItem:
	return custom_slot_primary.item

func get_secondary_item() -> InventoryItem:
	return custom_slot_secondary.item

# Dragging

var dragging = false
var drag_offset = Vector2.ZERO

func _on_top_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.pressed:
				accept_event()
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				z_index +=1
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset
