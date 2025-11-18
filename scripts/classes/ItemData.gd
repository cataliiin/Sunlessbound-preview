extends Resource
class_name ItemData

enum GearSlotType {
	NONE,
	HAND_PRIMARY,
	HAND_SECONDARY
}

@export var id: String
@export var name: String
@export var icon: Texture2D
@export var size: Vector2i
@export_file_path("*.tscn") var ground_item_scene_path: String = ""
@export_file_path("*.tscn") var hand_item_scene_path: String = ""
@export var slot_type: GearSlotType = GearSlotType.NONE
var ground_scene: PackedScene
var hand_scene: PackedScene
