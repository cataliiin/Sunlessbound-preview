extends Node

enum EquippedSlot {
	NONE,
	PRIMARY,
	SECONDARY,
}

@export_node_path("Node3D") var hand_path: NodePath
@export_node_path("Control") var inventory_root_path: NodePath

@onready var hand: Node3D = get_node(hand_path)
@onready var inventory_root: Control = get_node(inventory_root_path)

var primary_item: InventoryItem
var secondary_item: InventoryItem

var current_slot: EquippedSlot = EquippedSlot.NONE

func _ready() -> void:
	call_deferred("connect_signals")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_item"):
		var item = op_current_slot()
		if item:
			inventory_root.receive_drop(item)
			op_current_slot(true)
	
	if event.is_action_pressed("slot_primary"):
		if primary_item != null:
			load_item_scene(primary_item.get_hand_scene())
			current_slot = EquippedSlot.PRIMARY
		else:
			clear_hand()
			current_slot = EquippedSlot.NONE
	elif event.is_action_pressed("slot_secondary"):
		if secondary_item != null:
			load_item_scene(secondary_item.get_hand_scene())
			current_slot = EquippedSlot.SECONDARY
		else:
			clear_hand()
			current_slot = EquippedSlot.NONE
	elif event.is_action_pressed("slot_null"):
		clear_hand()
		current_slot = EquippedSlot.NONE

func connect_signals() -> void:
	inventory_root.gear_panel.custom_slot_primary.item_changed.connect(primary_item_changed)
	inventory_root.gear_panel.custom_slot_secondary.item_changed.connect(secondary_item_changed)

func load_item_scene(scene: PackedScene) -> void:
	clear_hand()
	
	var scene_instance: Node3D = scene.instantiate()
	if scene_instance is RigidBody3D:
		(scene_instance as RigidBody3D).freeze = true

	hand.add_child(scene_instance)

func clear_hand() -> void:
	for child in hand.get_children():
		child.queue_free()

# Get the item in hand
func op_current_slot(clear_it: bool = false) -> InventoryItem:
	if current_slot == EquippedSlot.PRIMARY:
		var t = primary_item
		if clear_it:
			inventory_root.gear_panel.custom_slot_primary.remove_item()
		return t
	elif current_slot == EquippedSlot.SECONDARY:
		var t = secondary_item
		if clear_it:
			inventory_root.gear_panel.custom_slot_secondary.remove_item()
		return t
	return null


func primary_item_changed(item: InventoryItem) -> void:
	primary_item = item
	if current_slot == EquippedSlot.PRIMARY:
		if primary_item != null:
			load_item_scene(primary_item.get_hand_scene())
		else:
			clear_hand()
			current_slot = EquippedSlot.NONE

func secondary_item_changed(item: InventoryItem) -> void:
	secondary_item = item
	if current_slot == EquippedSlot.SECONDARY:
		if secondary_item != null:
			load_item_scene(secondary_item.get_hand_scene())
		else:
			clear_hand()
			current_slot = EquippedSlot.NONE
