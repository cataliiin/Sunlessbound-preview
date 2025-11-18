extends Resource
class_name InventoryItem

@export var item_data: ItemData
@export var placed_anchor_slot_pos: Vector2i
var parent_inventory_data: InventoryData

func _init(_item_data: ItemData = null):
	if _item_data:
		item_data = _item_data

# GET

func get_id() -> String:
	return item_data.id

func get_item_name() -> String:
	return item_data.name

func get_icon() -> Texture2D:
	return item_data.icon

func get_size() -> Vector2i:
	return item_data.size

func get_ground_scene() -> PackedScene:
	return load(item_data.ground_item_scene_path)

func get_hand_scene() -> PackedScene:
	return load(item_data.hand_item_scene_path)

func get_type() -> ItemData.GearSlotType:
	return item_data.slot_type

func set_placed_position(pos) -> void:
	placed_anchor_slot_pos = pos

func is_placed() -> bool:
	if placed_anchor_slot_pos == null:
		return false
	else:
		return true

func set_parent_inventory_data(node):
	parent_inventory_data = node
