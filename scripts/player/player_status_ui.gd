extends Panel

@onready var body_type_label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer/BodyTypeLabel

@onready var health: ProgressBar = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/Health
@onready var stamina: ProgressBar = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/Stamina
@onready var calories: ProgressBar = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/Calories
@onready var hydration: ProgressBar = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/Hydration
@onready var stored_calories: ProgressBar = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/StoredCalories

@onready var effects_label: RichTextLabel = $VBoxContainer/MarginContainer/TabContainer/Effects/EffectsLabel

@export_node_path() var vitals_node_path: NodePath

@onready var health_label: Label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer2/HealthLabel
@onready var stamina_label: Label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer3/StaminaLabel
@onready var calories_label: Label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer4/CaloriesLabel
@onready var hydration_label: Label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer5/HydrationLabel
@onready var stored_calories_label: Label = $VBoxContainer/MarginContainer/TabContainer/Status/ScrollContainer/VBoxContainer/HBoxContainer6/StoredCaloriesLabel

# NOT DONE. JUST FOR TESTING

var vitals = null

func _ready():
	if vitals_node_path != null and vitals_node_path != NodePath(""):
		vitals = get_node(vitals_node_path)
	else:
		push_error("Vitals node path not assigned!")
func update_ui() -> void:
	if vitals == null:
		return
	
	health.value = (vitals.current_health / vitals.max_health) * 100
	stamina.value = (vitals.current_stamina / vitals.get_effective_max_stamina()) * 100
	calories.value = (vitals.current_calories / vitals.max_calories) * 100
	hydration.value = (vitals.current_hydration / vitals.max_hydration) * 100
	stored_calories.value = (vitals.current_reserve / vitals.max_reserve) * 100
	
	health_label.text = "(%d / %d) HP" % [int(vitals.current_health), int(vitals.max_health)]
	stamina_label.text = "(%d / %d)" % [int(vitals.current_stamina), int(vitals.get_effective_max_stamina())]
	calories_label.text = "(%d / %d) kcal" % [int(vitals.current_calories), int(vitals.max_calories)]
	hydration_label.text = "(%d / %d) ml" % [int(vitals.current_hydration), int(vitals.max_hydration)]
	stored_calories_label.text = "(%d / %d) kcal" % [int(vitals.current_reserve), int(vitals.max_reserve)]
	
	var effects = []
	if vitals.is_bloated:
		effects.append("Bloated")
	if vitals.is_starving:
		effects.append("Starving")
	if vitals.is_dehydrated:
		effects.append("Dehydrated")
	if vitals.current_radiation > vitals.max_radiation * 0.3:
		effects.append("Irradiated")
	
	effects_label.bbcode_text = "[b]Status Effects:[/b]\n" + ( "None"  if effects.size() <= 0 else effects.join("\n"))

func _process(delta):
	update_ui()


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
