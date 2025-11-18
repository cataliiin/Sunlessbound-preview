extends Resource
class_name InventoryData

signal inventory_changed

var grid_size: Vector2i

@export var items: Array[InventoryItem]
var slots: Matrix2D

func setup(_grid_size) -> void:
	self.grid_size = _grid_size
	slots = Matrix2D.new()
	slots.setup(grid_size, null)
	if !items.is_empty():
		init_item_list()
	else:
		items = []

func init_item_list() -> void:
	for item in items:
		if item.placed_anchor_slot_pos == null:
			set_item_in_slots(item, find_first_free_space(item.get_size()), true)
		else:
			set_item_in_slots(item, item.placed_anchor_slot_pos, true)

func set_item_in_slots(item: InventoryItem, pos: Vector2i, is_silent: bool = false) -> void:
	var item_size = item.item_data.size
	var ci = items.find(item)
	for y in range(pos.y, pos.y + item_size.y):
		for x in range(pos.x, pos.x + item_size.x):
			slots.setv(x, y, ci)
	item.set_placed_position(pos)
	item.set_parent_inventory_data(self)
	if !is_silent:
		emit_signal("inventory_changed")

func add_item(item: InventoryItem, anchor_pos: Variant = null, is_silent: bool = false) -> bool:
	var item_size = item.item_data.size
	var adding_pos: Variant
	if anchor_pos != null:
		if check_space(anchor_pos, item_size):
			adding_pos = anchor_pos
		else:
			return false
	else:
		adding_pos = find_first_free_space(item_size)
	
	if adding_pos != null:
		items.append(item)
		set_item_in_slots(item, adding_pos, is_silent)
		return true
	else:
		return false

func clear_item_slots(index: int) -> void:
	if index < 0 or index >= items.size():
		push_error("Out of bounds: clear_item_slots called with invalid index: %d" % index)
		return
	
	var item = items[index]
	if item.is_placed():
		var pos = item.placed_anchor_slot_pos
		var size = item.item_data.size
		for y in range(pos.y, pos.y + size.y):
			for x in range(pos.x, pos.x + size.x):
				slots.setv(x, y, null)

func remove_item(index: int, is_silent: bool = false):
	if index < 0 or index >= items.size():
		push_error("Out of bounds: remove_item called with invalid index: %d" % index)
		return null
	
	clear_item_slots(index) # Just clears slots
	items.remove_at(index)
	if !is_silent:
		emit_signal("inventory_changed")


func move_item(index: int, new_pos: Vector2i, is_silent: bool = false) -> bool:
	if index < 0 or index >= items.size():
		push_error("Out of bounds: move_item called with invalid index: %d" % index)
		return false
	
	var item = items[index]
	var old_pos = item.placed_anchor_slot_pos
	
	clear_item_slots(index)
	
	if check_space(new_pos, item.get_size()):
		set_item_in_slots(item, new_pos, is_silent)
		if !is_silent:
			emit_signal("inventory_changed")
		return true
	else:
		set_item_in_slots(item, old_pos, is_silent)
		if !is_silent:
			emit_signal("inventory_changed")
		return false
	

func transfer_item(new_inventory_data: InventoryData, item: InventoryItem, position: Variant = null) -> void:
	var old_item_reference_index = self.get_item_index(item)
	var old_pos = item.placed_anchor_slot_pos
	self.remove_item(old_item_reference_index)
	
	if !new_inventory_data.add_item(item, position):
		self.add_item(item, old_pos)
	
	refresh()

func refresh():
	emit_signal("inventory_changed")

func has_item(item: InventoryItem) -> bool:
	return items.has(item)

func get_item_index(item: InventoryItem) -> int:
	return items.find(item)

# Utils

func check_space(anchor_pos: Vector2i, area_size: Vector2i) -> bool:
	if not slots.is_valid_pos(anchor_pos.x, anchor_pos.y):
		return false
	if not slots.is_valid_pos(anchor_pos.x + area_size.x - 1, anchor_pos.y + area_size.y - 1):
		return false

	for y in range(anchor_pos.y, anchor_pos.y + area_size.y):
		for x in range(anchor_pos.x, anchor_pos.x + area_size.x):
			if slots.data[y][x] != null:
				return false
	return true

func find_first_free_space(area_size: Vector2i):
	for y in range(grid_size.y - area_size.y + 1):
		for x in range(grid_size.x - area_size.x + 1):
			var anchor_pos = Vector2i(x, y)
			if check_space(anchor_pos, area_size):
				return anchor_pos
	return null
