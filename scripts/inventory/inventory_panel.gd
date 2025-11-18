extends Control

@export_category("InventoryPanel")
var inventory_data: InventoryData
@export var auto_init: bool
@export var grid_size: Vector2i = Vector2i.ZERO

@export_group("Panel")
@export var title: String
@export var slot_size: int
@export var slot_scene: PackedScene
@export var item_scene: PackedScene

@onready var slots_grid: GridContainer = $VBoxContainer/MarginContainer/SlotsGrid
@onready var top_panel: Panel = $VBoxContainer/TopPanel
@onready var title_label: Label = $VBoxContainer/TopPanel/Title

var slots_list: Dictionary = {}
var built: bool = false

var item_scenes_list: Array = []

func _ready() -> void:
	
	top_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if auto_init:
		initialize()

func setup_config(_title: String, _grid_size: Vector2i, _slot_size: int, _slot_scene: PackedScene, _item_scene: PackedScene) -> void:
	self.title = _title
	self.grid_size = _grid_size
	self.slot_size = _slot_size
	self.slot_scene = _slot_scene
	self.item_scene = _item_scene

func initialize() -> void:
	if built:
		return
	if not is_inside_tree():
		call_deferred("initialize")
		return
	
	if grid_size.x <= 0 or grid_size.y <= 0 or slot_size <= 0 or slot_scene == null:
		push_error("InventoryPanel: invalid config (grid_size/slot_size/slot_scene).")
		return
	
	init_panel()
	load_slots()
	
	init_inventory_data()
	inventory_data.connect("inventory_changed", load_items)
	load_items()
	
	
	built = true

func init_panel() -> void:
	title_label.text = title
	
	var mh = grid_size.x * (slot_size + slots_grid.get_theme_constant("h_separation")) + 5
	var mv = grid_size.y * (slot_size + slots_grid.get_theme_constant("v_separation")) + top_panel.custom_minimum_size.y + 8
	
	self.set_custom_minimum_size(Vector2(mh, mv))
	
	slots_grid.columns = grid_size.x

# Slots

func load_slots() -> void:
	for c in slots_grid.get_children():
		c.queue_free()
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var slot = slot_scene.instantiate()
			slot.custom_minimum_size = Vector2(slot_size, slot_size)
			slots_list[Vector2i(x,y)] = slot
			slot.grid_pos = Vector2i(x,y)
			slot.connect("received_item", handle_received_item)
			slot.name = str(slots_list.size() - 1)
			slots_grid.add_child(slot)

func get_slot_by_grid_pos(pos: Vector2i):
	return slots_list.get(pos)

# Items

func init_inventory_data() -> void:
	if inventory_data == null:
		inventory_data = InventoryData.new()
	inventory_data.setup(grid_size)

func load_items() -> void:
	for it_scene in item_scenes_list:
		if it_scene != null:
			it_scene.queue_free()
	item_scenes_list.clear()
	
	for it: InventoryItem in inventory_data.items:
		var it_scene = item_scene.instantiate()
		it_scene.set_item(it)
		it_scene.size = Vector2(slot_size * it.get_size().x, slot_size * it.get_size().y)
		get_slot_by_grid_pos(it.placed_anchor_slot_pos).add_child(it_scene)
		item_scenes_list.append(it_scene)

func handle_received_item(new_slot_pos: Vector2i, item: InventoryItem):
	if inventory_data.has_item(item):
		var item_index = inventory_data.get_item_index(item)
		inventory_data.move_item(item_index, new_slot_pos)
	elif item.parent_inventory_data != null:
		item.parent_inventory_data.transfer_item(inventory_data, item, new_slot_pos)
	else: # case used when the item comes from a custom slot like from the gear panel
		inventory_data.add_item(item, new_slot_pos)

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
