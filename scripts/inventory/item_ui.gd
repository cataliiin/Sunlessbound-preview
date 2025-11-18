extends TextureRect

signal drag_succesful

var item: InventoryItem

func set_item(_item: InventoryItem) -> void:
	self.item = _item
	self.texture = item.get_icon()

# Drag and drop

func get_drag_ghost():
	var ghost = TextureRect.new()
	ghost.size = size
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.texture = texture
	ghost.modulate = Color(1,1,1,0.6)
	return ghost

func get_drag_data():
	return item

func on_drag():
	self.modulate = Color(1,1,1,0.2)

func drag_successful():
	emit_signal("drag_succesful")
	queue_free()

func drag_failed():
	self.modulate = Color(1,1,1,1)
