extends Node

signal received_item(Vector2i, InventoryItem)

var grid_pos: Vector2i

func receive_drop(item) -> bool:
	# REQUEST ITEM MOVE
	emit_signal("received_item", grid_pos, item)
	
	# fix this. always true
	return true
