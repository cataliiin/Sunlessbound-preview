extends Node

enum BodyType {
	UNDERWEIGHT,
	NORMAL,
	OVERWEIGHT,
	OBESE
}

enum ActivityLevel {
	SLEEPING,
	RESTING,
	LIGHT,
	MODERATE,
	HEAVY,
	COMBAT
}

@export_category("Vitality")

# === CALORIES ===
@export_subgroup("Calories")
@export_range(2000, 5000) var max_calories: float = 3000
@export_range(0, 5000) var base_metabolism: float = 1800
@export_range(0, 60000) var max_reserve: float = 60000

# === HYDRATION ===
@export_subgroup("Hydration")
@export_range(1000, 5000) var max_hydration: float = 2500  # ml
@export_range(0, 3000) var base_water_drain: float = 2000  # ml per day

# === HEALTH ===
@export_subgroup("Health")
@export_range(50, 200) var max_health: float = 100

# === STAMINA ===
@export_subgroup("Stamina")
@export_range(50, 200) var max_stamina: float = 100
@export_range(10, 50) var stamina_regen_rate: float = 20  # per second when resting

# === TEMPERATURE ===
@export_subgroup("Temperature")
@export_range(35.0, 38.0) var normal_body_temp: float = 37.0
@export_range(30.0, 45.0) var current_body_temp: float = 37.0

# === RADIATION ===
@export_subgroup("Radiation")
@export_range(0, 1000) var max_radiation: float = 1000
@export var radiation_decay_rate: float = 5.0  # per day

# Current values
var current_calories: float
var current_reserve: float
var current_hydration: float
var current_health: float
var current_stamina: float
var current_radiation: float = 0.0

# Activity tracking
var current_activity: ActivityLevel = ActivityLevel.RESTING
var activity_multiplier: float = 1.0

# Metabolism rates (calculated)
var metabolism_rate: float  # calories per second
var hydration_rate: float   # ml per second

# Status flags
var is_bloated: bool = false
var bloated_timer: float = 0.0
var is_starving: bool = false
var is_dehydrated: bool = false

# Weight tracking
var current_body_type: BodyType = BodyType.NORMAL

# Debuffs/Buffs
var movement_speed_modifier: float = 1.0
var stamina_regen_modifier: float = 1.0
var max_stamina_modifier: float = 1.0
var carry_capacity_modifier: float = 1.0
var cold_resistance_modifier: float = 1.0

# Signals
signal calories_changed(current: float, max: float)
signal reserve_changed(current: float, max: float)
signal hydration_changed(current: float, max: float)
signal health_changed(current: float, max: float)
signal stamina_changed(current: float, max: float)
signal body_type_changed(new_type: BodyType)
signal player_died(cause: String)
signal status_effect_applied(effect: String)
signal status_effect_removed(effect: String)
signal radiation_changed(current: float, max: float)
signal temperature_changed(temp: float)

func _ready() -> void:
	# Initialize current values
	current_calories = max_calories * 0.2  # Start at 80%
	current_reserve = 20000.0  # Normal weight reserves
	current_hydration = max_hydration * 0.9
	current_health = max_health
	current_stamina = max_stamina
	current_body_temp = normal_body_temp
	
	# Calculate rates
	metabolism_rate = base_metabolism / GlobalUtils.day_lenght  # calories per second
	hydration_rate = base_water_drain / GlobalUtils.day_lenght  # ml per second
	
	# Update initial body type
	update_body_type()
	apply_body_type_modifiers()

func _process(delta: float) -> void:
	# Process all vitals
	process_calories(delta)
	process_hydration(delta)
	process_stamina(delta)
	process_temperature(delta)
	process_radiation(delta)
	process_bloated_timer(delta)
	
	# Check death conditions
	check_death_conditions()

# CALORIE SYSTEM

func process_calories(delta: float) -> void:
	# Calculate burn rate based on activity
	var burn_rate = metabolism_rate * activity_multiplier * delta
	
	# Temperature modifiers
	if current_body_temp < 35.0:  # Hypothermia
		burn_rate *= 1.2
	elif current_body_temp > 38.5:  # Hyperthermia
		burn_rate *= 1.1
	
	# Burn active calories first
	if current_calories > 0:
		current_calories -= burn_rate
		
		if current_calories < 0:
			# Overflow into reserves
			current_reserve += current_calories  # Negative value
			current_calories = 0
			
			if not is_starving:
				is_starving = true
				status_effect_applied.emit("Starving")
	else:
		# Burning reserves
		current_reserve -= burn_rate
		current_reserve = max(0, current_reserve)
		is_starving = true
	
	# Convert excess active calories to reserves (every hour)
	if current_calories > max_calories * 0.85:  # Above 85% capacity
		var excess = (current_calories - max_calories * 0.75) * delta * 0.1
		current_calories -= excess
		current_reserve += excess
		current_reserve = min(current_reserve, max_reserve)
	
	# Check if no longer starving
	if is_starving and current_calories > max_calories * 0.3:
		is_starving = false
		status_effect_removed.emit("Starving")
	
	# Update body type if reserves changed significantly
	update_body_type()
	
	calories_changed.emit(current_calories, max_calories)
	reserve_changed.emit(current_reserve, max_reserve)
	
	# Starvation damage
	if current_reserve <= 0:
		take_starvation_damage(delta)

func eat_food(calories: float) -> bool:
	
	# Cant eat if too full (allow slight overeating up to 120%)
	if current_calories >= max_calories * 1.2:
		print("Too full to eat!")
		return false
	
	# Add calories
	var calories_to_add = min(calories, max_calories * 1.2 - current_calories)
	current_calories += calories_to_add
	
	# Check for bloated effect
	if current_calories > max_calories * 0.85:
		apply_bloated_effect()
	
	# Clear starving status if eating enough
	if is_starving and current_calories > max_calories * 0.3:
		is_starving = false
		status_effect_removed.emit("Starving")
	
	calories_changed.emit(current_calories, max_calories)
	return true

func set_activity_level(activity: ActivityLevel) -> void:
	current_activity = activity
	
	match activity:
		ActivityLevel.SLEEPING:
			activity_multiplier = 0.75
		ActivityLevel.RESTING:
			activity_multiplier = 1.0
		ActivityLevel.LIGHT:
			activity_multiplier = 1.3
		ActivityLevel.MODERATE:
			activity_multiplier = 1.6
		ActivityLevel.HEAVY:
			activity_multiplier = 2.0
		ActivityLevel.COMBAT:
			activity_multiplier = 2.5

func apply_bloated_effect() -> void:
	if not is_bloated:
		is_bloated = true
		bloated_timer = 7200.0  # 2 hours in seconds
		max_stamina_modifier *= 0.85  # -15% max stamina
		movement_speed_modifier *= 0.9  # -10% speed
		status_effect_applied.emit("Bloated")

func process_bloated_timer(delta: float) -> void:
	if is_bloated:
		bloated_timer -= delta
		if bloated_timer <= 0:
			is_bloated = false
			max_stamina_modifier /= 0.85
			movement_speed_modifier /= 0.9
			status_effect_removed.emit("Bloated")

func take_starvation_damage(delta: float) -> void:
	var damage = 1.0 * delta  # 1 HP per second when reserves are at 0
	current_health -= damage
	health_changed.emit(current_health, max_health)

# HYDRATION SYSTEM

func process_hydration(delta: float) -> void:
	var drain_rate = hydration_rate * delta
	
	# Activity modifiers
	drain_rate *= activity_multiplier
	
	# Temperature modifiers
	if current_body_temp > 38.0:
		drain_rate *= 1.5  # Sweating
	
	# Drain hydration
	current_hydration -= drain_rate
	current_hydration = max(0, current_hydration)
	
	# Check dehydration status
	if current_hydration < max_hydration * 0.3:
		if not is_dehydrated:
			is_dehydrated = true
			status_effect_applied.emit("Dehydrated")
	elif is_dehydrated and current_hydration > max_hydration * 0.5:
		is_dehydrated = false
		status_effect_removed.emit("Dehydrated")
	
	# Dehydration damage (faster than starvation)
	if current_hydration <= 0:
		var damage = 2.0 * delta  # 2 HP per second
		current_health -= damage
		health_changed.emit(current_health, max_health)
	
	hydration_changed.emit(current_hydration, max_hydration)

func drink_water(milliliters: float, is_clean: bool = true) -> bool:
	if current_hydration >= max_hydration * 1.1:
		print("Not thirsty!")
		return false
	
	current_hydration += milliliters
	current_hydration = min(current_hydration, max_hydration)
	
	# Dirty water risk
	if not is_clean:
		if randf() < 0.3:  # 30% chance of getting sick
			apply_sickness()
	
	hydration_changed.emit(current_hydration, max_hydration)
	return true

func apply_sickness() -> void:
	# Dysentery/parasites from dirty water
	status_effect_applied.emit("Sick")
	# Lose water and calories over time
	# TODO: Implement disease system

# STAMINA SYSTEM

func process_stamina(delta: float) -> void:
	# Regenerate stamina when not exhausted
	if current_activity == ActivityLevel.RESTING or current_activity == ActivityLevel.SLEEPING:
		var regen = stamina_regen_rate * stamina_regen_modifier * delta
		
		# Cant regen well if malnourished
		if current_calories < max_calories * 0.3:
			regen *= 0.5
		if current_hydration < max_hydration * 0.3:
			regen *= 0.5
		
		current_stamina += regen
		current_stamina = min(current_stamina, get_effective_max_stamina())
		stamina_changed.emit(current_stamina, get_effective_max_stamina())

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina, get_effective_max_stamina())
		return true
	return false

func get_effective_max_stamina() -> float:
	return max_stamina * max_stamina_modifier

# TEMPERATURE SYSTEM

func process_temperature(delta: float) -> void:
	# Temperature naturally returns to normal
	var temp_change = (normal_body_temp - current_body_temp) * 0.1 * delta
	current_body_temp += temp_change
	
	# Check temperature extremes
	if current_body_temp < 35.0:  # Hypothermia
		var damage = (35.0 - current_body_temp) * 0.5 * delta
		current_health -= damage
		health_changed.emit(current_health, max_health)
	elif current_body_temp > 40.0:  # Severe hyperthermia
		var damage = (current_body_temp - 40.0) * 1.0 * delta
		current_health -= damage
		health_changed.emit(current_health, max_health)
	
	temperature_changed.emit(current_body_temp)

func adjust_temperature(change: float) -> void:
	current_body_temp += change
	current_body_temp = clamp(current_body_temp, 30.0, 45.0)
	temperature_changed.emit(current_body_temp)

# RADIATION SYSTEM

func process_radiation(delta: float) -> void:
	# Natural decay
	if current_radiation > 0:
		var decay = (radiation_decay_rate / GlobalUtils.day_lenght) * delta
		current_radiation -= decay
		current_radiation = max(0, current_radiation)
		radiation_changed.emit(current_radiation, max_radiation)
	
	# Radiation sickness effects
	if current_radiation > max_radiation * 0.5:
		# Nausea effects, drain calories/hydration faster
		current_calories -= 0.5 * delta
		current_hydration -= 0.8 * delta
	
	if current_radiation > max_radiation * 0.8:
		# Critical radiation damage
		var damage = 0.5 * delta
		current_health -= damage
		health_changed.emit(current_health, max_health)

func add_radiation(amount: float) -> void:
	current_radiation += amount
	current_radiation = min(current_radiation, max_radiation)
	
	if current_radiation > max_radiation * 0.3:
		status_effect_applied.emit("Irradiated")
	
	radiation_changed.emit(current_radiation, max_radiation)

func take_anti_rad_medicine(effectiveness: float = 200.0) -> void:
	current_radiation -= effectiveness
	current_radiation = max(0, current_radiation)
	radiation_changed.emit(current_radiation, max_radiation)

# BODY TYPE SYSTEM

func update_body_type() -> void:
	var old_type = current_body_type
	
	if current_reserve < 10000:
		current_body_type = BodyType.UNDERWEIGHT
	elif current_reserve < 30000:
		current_body_type = BodyType.NORMAL
	elif current_reserve < 50000:
		current_body_type = BodyType.OVERWEIGHT
	else:
		current_body_type = BodyType.OBESE
	
	if old_type != current_body_type:
		apply_body_type_modifiers()
		body_type_changed.emit(current_body_type)

func apply_body_type_modifiers() -> void:
	# Reset modifiers
	movement_speed_modifier = 1.0
	stamina_regen_modifier = 1.0
	max_stamina_modifier = 1.0
	carry_capacity_modifier = 1.0
	cold_resistance_modifier = 1.0
	
	# Apply based on body type
	match current_body_type:
		BodyType.UNDERWEIGHT:
			max_stamina_modifier = 0.8  # -20%
			carry_capacity_modifier = 0.9  # -10%
			cold_resistance_modifier = 0.7  # Faster cold damage
		
		BodyType.NORMAL:
			# No modifiers - optimal
			pass
		
		BodyType.OVERWEIGHT:
			movement_speed_modifier = 0.9  # -10%
			stamina_regen_modifier = 0.85  # -15%
			cold_resistance_modifier = 1.2  # +20% cold resistance
		
		BodyType.OBESE:
			movement_speed_modifier = 0.75  # -25%
			stamina_regen_modifier = 0.7  # -30%
			cold_resistance_modifier = 1.3  # +30% cold resistance
			# TODO: Add narrow space restrictions

func get_body_type_string() -> String:
	match current_body_type:
		BodyType.UNDERWEIGHT: return "Underweight"
		BodyType.NORMAL: return "Normal"
		BodyType.OVERWEIGHT: return "Overweight"
		BodyType.OBESE: return "Obese"
	return "Unknown"

# HEALTH SYSTEM

func take_damage(amount: float, source: String = "Unknown") -> void:
	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die(source)

func heal(amount: float) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

# DEATH & STATUS CHECKS

func check_death_conditions() -> void:
	if current_health <= 0:
		die("Health depletion")
	elif current_body_temp <= 30.0:
		die("Hypothermia")
	elif current_body_temp >= 43.0:
		die("Hyperthermia")
	elif current_radiation >= max_radiation:
		die("Acute radiation syndrome")

func die(cause: String) -> void:
	print("Player died: ", cause)
	player_died.emit(cause)
	# TODO: Trigger death screen/respawn logic

# UTILITY FUNCTIONS

func get_status_summary() -> Dictionary:
	return {
		"calories": {
			"current": current_calories,
			"max": max_calories,
			"percentage": (current_calories / max_calories) * 100
		},
		"reserves": {
			"current": current_reserve,
			"max": max_reserve,
			"body_type": get_body_type_string()
		},
		"hydration": {
			"current": current_hydration,
			"max": max_hydration,
			"percentage": (current_hydration / max_hydration) * 100
		},
		"health": {
			"current": current_health,
			"max": max_health,
			"percentage": (current_health / max_health) * 100
		},
		"stamina": {
			"current": current_stamina,
			"max": get_effective_max_stamina(),
			"percentage": (current_stamina / get_effective_max_stamina()) * 100
		},
		"temperature": current_body_temp,
		"radiation": current_radiation,
		"status_effects": get_active_status_effects()
	}

func get_active_status_effects() -> Array:
	var effects = []
	if is_bloated: effects.append("Bloated")
	if is_starving: effects.append("Starving")
	if is_dehydrated: effects.append("Dehydrated")
	if current_radiation > max_radiation * 0.3: effects.append("Irradiated")
	if current_body_temp < 35.0: effects.append("Hypothermic")
	if current_body_temp > 38.5: effects.append("Overheating")
	return effects

func get_hunger_status() -> String:
	var percent = (current_calories / max_calories) * 100
	if percent > 85: return "Satisfied"
	elif percent > 50: return "Slightly Hungry"
	elif percent > 30: return "Hungry"
	elif percent > 10: return "Very Hungry"
	else: return "Starving"

func get_thirst_status() -> String:
	var percent = (current_hydration / max_hydration) * 100
	if percent > 80: return "Hydrated"
	elif percent > 50: return "Slightly Thirsty"
	elif percent > 30: return "Thirsty"
	elif percent > 10: return "Very Thirsty"
	else: return "Dehydrated"

# GETTERS FOR MODIFIERS

func get_movement_speed_modifier() -> float:
	return movement_speed_modifier

func get_stamina_regen_modifier() -> float:
	return stamina_regen_modifier

func get_carry_capacity_modifier() -> float:
	return carry_capacity_modifier

func get_cold_resistance_modifier() -> float:
	return cold_resistance_modifier
