extends RigidBody3D

@export var item: InventoryItem

func _ready() -> void:
	self.set_meta("interactable", true)
	if item == null:
		push_error("Dropped item scene data is null!")
	else:
		item = item.duplicate(true)

func get_item() -> InventoryItem:
	return item

func set_item(_item: InventoryItem) -> void:
	item = _item
