extends Panel

signal item_changed(InventoryItem)

@export var slot_type: ItemData.GearSlotType

var item: InventoryItem
var item_scene

func receive_drop(_item: InventoryItem) -> bool:
	if _item.get_type() == slot_type and item == null:
		item = _item
		
		var item_inv_parent = item.parent_inventory_data
		var item_index = item_inv_parent.get_item_index(item)
		item_inv_parent.remove_item(item_index)
		
		item.parent_inventory_data = null
		
		load_item()
		return true
	else:
		return false

func load_item() -> void:
	var item_ui_scene: Control = load("res://scenes/inventory/ItemUI.tscn").instantiate()
	item_ui_scene.set_item(item)
	item_ui_scene.size = item.get_size() * Vector2i(64, 64)
	item_ui_scene.position = self.position
	self.add_child(item_ui_scene)
	item_scene = item_ui_scene
	item_ui_scene.connect("drag_succesful", handle_succesful_drag)
	emit_signal("item_changed", item)

func remove_item() -> void:
	item = null
	item_scene.queue_free()
	emit_signal("item_changed", item)

func handle_succesful_drag() -> void:
	remove_item()
