extends Node

@export_category("Other Systems")
@export_node_path("Control") var inventory_root_path
@export_node_path("Control") var player_ui_interact_text_path

@export_category("Nodes")
@export_node_path("RayCast3D") var interact_raycast_path

@onready var interact_raycast: RayCast3D = get_node(interact_raycast_path)
@onready var inventory_root = get_node(inventory_root_path)
@onready var player_ui_interact_text = get_node(player_ui_interact_text_path)

var player_inventory_data: InventoryData

func _ready() -> void:
	call_deferred("reference_inventory_data")

func reference_inventory_data():
	player_inventory_data = inventory_root.player_inventory.inventory_data
	if player_inventory_data == null:
		push_warning("Inventory root or player_inventory not found!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if interact_raycast.is_colliding():
			var collider = interact_raycast.get_collider()
			if collider.has_meta("interactable") and collider.get_meta("interactable"):
				if GlobalUtils.has_property("interact_text", collider):
					player_ui_interact_text = collider.interact_text
				else:
					player_ui_interact_text = " "
				
				
				var target = collider
				while target and not target.has_method("interact"):
					target = target.get_parent()
				
				if target and target.has_method("interact"):
					target.interact()
				elif collider.has_method("get_item"):
					var item: InventoryItem = collider.get_item()
					if player_inventory_data.add_item(item):
						collider.queue_free()
		else:
			player_ui_interact_text = " "
