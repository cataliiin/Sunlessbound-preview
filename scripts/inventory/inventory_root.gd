extends Control

# Data
@onready var player_inventory: Panel = $PlayerInventoryPanel
@onready var gear_panel: Panel = $GearPanel

@export var to_load_inventory_data: InventoryData

func _ready() -> void:
	player_inventory.inventory_data = to_load_inventory_data
	player_inventory.initialize()

# Item Drop

@export var drop_position_node: Node3D

# used to receive the item dragged on the dropcontrol
func receive_drop(item: InventoryItem):
	var inv_data = item.parent_inventory_data
	if inv_data != null: # check if its custom slot or not ( null means it is custom )
		
		var item_index = inv_data.get_item_index(item)
		print(item_index)
		if item_index > -1:
			inv_data.remove_item(item_index)
			print("remove item")
	
	# drop the physical item
	# modify later when scene manager is done so you can get the current world root and add the item there
	var item_scene: RigidBody3D = item.get_ground_scene().instantiate()
	
	get_parent().get_parent().add_child(item_scene)
	item_scene.global_position = drop_position_node.global_position
	var forward_dir = -get_parent().global_transform.basis.z.normalized()
	item_scene.apply_central_impulse(forward_dir * 1)

# UI

func toggle_inventory():
	visible = not visible

func show_inventory():
	visible = true

func hide_inventory():
	visible = false

func set_mouse_mode() -> bool:
	if !visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return true

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()
		set_mouse_mode()
