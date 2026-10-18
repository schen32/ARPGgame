extends CharacterBody2D

const MELEE_ATTACK = preload("res://scripts/melee_attack.gd")
const DASH_EFFECT = preload("res://scripts/dash_effect.gd")
const SKILL_BURST = preload("res://scripts/skill_burst.gd")
const PIXELS_PER_METER: float = 16.0 # The player's 16-pixel side is one meter.

signal experience_changed(current: int, required: int, player_level: int)
signal loadout_changed

@export var move_speed: float = 180.0
@export var sweep_cooldown: float = 0.4
@export var palm_cooldown: float = 1.0
@export var sweep_reach: float = 36.0
@export var sweep_angle_degrees: float = 100.0
@export var sweep_damage: float = 8.0
@export var sweep_knockback: float = 330.0
@export var palm_reach: float = 43.2
@export var palm_windup: float = 0.15
@export var palm_damage: float = 12.0
@export var palm_knockback: float = 975.0
@export var dash_cooldown: float = 1.2
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_damage: float = 25.0
@export var dash_knockback_speed: float = 975.0
@export var dash_knockback_duration: float = 0.35
@export var knockback_speed: float = 320.0
@export var knockback_duration: float = 0.18
@export_range(1, 10000) var experience_per_level: int = 100
@export_range(0.0, 20.0, 0.1) var exp_attract_range_meters: float = 2.0

var experience: int = 0
var level: int = 1

var sweep_timer: float = 0.0
var palm_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_active_this_frame: bool = false
var dash_hits: Dictionary = {}
var inventory_open: bool = false
var equipped_skills: Array[StringName] = [&"sweep", &"palm", &"dash"]
var dash_visual: Node2D
var inventory_skills: Array[StringName] = []
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

@onready var health = $Health

func _ready() -> void:
	dash_visual = DASH_EFFECT.new()
	dash_visual.player = self
	add_child(dash_visual)
	inventory_skills.resize(18)
	inventory_skills.fill(&"")
	health.changed.connect(_on_health_changed)
	_on_health_changed(health.current, health.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	$Geometry.fill_ratio = current / maximum

func take_damage(amount: float) -> void:
	if is_dashing():
		return
	health.take_damage(amount)

func is_dashing() -> bool:
	return dash_timer > 0.0 or dash_active_this_frame

func is_alive() -> bool:
	return health.current > 0.0

func get_exp_attract_radius() -> float:
	return exp_attract_range_meters * PIXELS_PER_METER

func add_experience(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	experience += amount
	while experience >= experience_per_level:
		experience -= experience_per_level
		level += 1
	experience_changed.emit(experience, experience_per_level, level)

func apply_knockback(direction: Vector2) -> void:
	if not is_alive() or is_dashing():
		return
	knockback_velocity = direction.normalized() * knockback_speed
	knockback_timer = knockback_duration

func movement_direction() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return direction

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed and not event.echo:
		activate_skill(2, get_global_mouse_position())

func _physics_process(delta: float) -> void:
	dash_active_this_frame = dash_timer > 0.0
	if not is_alive():
		velocity = Vector2.ZERO
		dash_visual.update_display()
		return
	sweep_timer = maxf(0.0, sweep_timer - delta)
	palm_timer = maxf(0.0, palm_timer - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	var direction := movement_direction()
	velocity = direction * move_speed
	if dash_timer > 0.0:
		# Clamp the final frame so distance stays consistent at different frame rates.
		velocity = dash_direction * dash_speed * minf(1.0, dash_timer / maxf(delta, 0.001))
		dash_timer = maxf(0.0, dash_timer - delta)
	elif knockback_timer > 0.0:
		# Restore steering continuously instead of waiting through a near-zero push.
		knockback_timer = maxf(0.0, knockback_timer - delta)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_speed / maxf(knockback_duration, 0.001) * delta)
		if knockback_timer <= 0.0:
			knockback_velocity = Vector2.ZERO
		var push_weight := clampf(knockback_timer / maxf(knockback_duration, 0.001), 0.0, 1.0)
		velocity = velocity * (1.0 - push_weight) + knockback_velocity
	var previous_position := global_position
	move_and_slide()
	if dash_active_this_frame:
		damage_dash_enemies(previous_position, global_position)
	dash_visual.update_display()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		activate_skill(0, get_global_mouse_position())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		activate_skill(1, get_global_mouse_position())

func try_sweep(aim_position: Vector2) -> Node2D:
	var aim := aim_position - global_position
	if not is_alive() or inventory_open or sweep_timer > 0.0 or aim.is_zero_approx():
		return null
	sweep_timer = sweep_cooldown
	return create_melee(&"sweep", aim.normalized())

func try_palm(aim_position: Vector2) -> Node2D:
	var aim := aim_position - global_position
	if not is_alive() or inventory_open or palm_timer > 0.0 or aim.is_zero_approx():
		return null
	palm_timer = palm_cooldown
	return create_melee(&"palm", aim.normalized())

func create_melee(kind: StringName, direction: Vector2) -> Node2D:
	var attack := MELEE_ATTACK.new()
	attack.player = self
	attack.kind = kind
	attack.direction = direction.normalized()
	attack.reach = sweep_reach if kind == &"sweep" else palm_reach
	attack.damage = sweep_damage if kind == &"sweep" else palm_damage
	attack.knockback_strength = sweep_knockback if kind == &"sweep" else palm_knockback
	attack.arc_degrees = sweep_angle_degrees
	attack.windup = palm_windup if kind == &"palm" else 0.0
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.start()
	return attack

func try_dash(direction: Vector2) -> bool:
	if not is_alive() or inventory_open or dash_cooldown_timer > 0.0 or direction.is_zero_approx():
		return false
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	dash_active_this_frame = true
	dash_hits.clear()
	dash_cooldown_timer = dash_cooldown
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	emit_skill_burst(&"dash", dash_direction)
	dash_visual.update_display()
	return true

func dash_hit_radius() -> float:
	return 17.0

func damage_dash_enemies(from: Vector2, to: Vector2) -> void:
	# Sweep the traveled segment so a quick dash cannot skip a circle between ticks.
	# Hit radius combines the player's 8px half-width with the enemy's 9px radius.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or dash_hits.has(enemy.get_instance_id()):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, from, to)
		if enemy.global_position.distance_to(closest) <= dash_hit_radius():
			dash_hits[enemy.get_instance_id()] = true
			enemy.take_damage(dash_damage)
			if not enemy.is_queued_for_deletion():
				enemy.apply_knockback(dash_direction, dash_knockback_speed, dash_knockback_duration)

func item_list(zone: String) -> Array[StringName]:
	match zone:
		"equipped": return equipped_skills
		"inventory": return inventory_skills
	return []

func skill_at(zone: String, index: int) -> StringName:
	var list := item_list(zone)
	return list[index] if index >= 0 and index < list.size() else &""

func accepts_item(zone: String, item: StringName) -> bool:
	return zone in ["inventory", "equipped"] and item in [&"", &"sweep", &"palm", &"dash"]

func can_move_skill(from_zone: String, from_index: int, to_zone: String, to_index: int) -> bool:
	var source := item_list(from_zone)
	var destination := item_list(to_zone)
	if not inventory_open or from_index < 0 or from_index >= source.size() or to_index < 0 or to_index >= destination.size():
		return false
	return source[from_index] != &"" and (from_zone != to_zone or from_index != to_index) and accepts_item(to_zone, source[from_index]) and accepts_item(from_zone, destination[to_index])

func move_skill(from_zone: String, from_index: int, to_zone: String, to_index: int) -> bool:
	if not can_move_skill(from_zone, from_index, to_zone, to_index):
		return false
	var source := item_list(from_zone)
	var destination := item_list(to_zone)
	var displaced := destination[to_index]
	destination[to_index] = source[from_index]
	source[from_index] = displaced
	loadout_changed.emit()
	return true

func skill_cooldown(skill: StringName) -> Vector2:
	match skill:
		&"sweep": return Vector2(sweep_timer, sweep_cooldown)
		&"palm": return Vector2(palm_timer, palm_cooldown)
		&"dash": return Vector2(dash_cooldown_timer, dash_cooldown)
	return Vector2.ZERO

func activate_skill(index: int, aim_position: Vector2) -> bool:
	if inventory_open or not is_alive() or index < 0 or index >= equipped_skills.size():
		return false
	match equipped_skills[index]:
		&"sweep": return try_sweep(aim_position) != null
		&"palm": return try_palm(aim_position) != null
		&"dash":
			var direction := movement_direction()
			if direction.is_zero_approx():
				direction = aim_position - global_position
			return try_dash(direction)
	return false

func emit_skill_burst(kind: StringName, direction: Vector2) -> void:
	var burst := SKILL_BURST.new()
	burst.kind = kind
	burst.direction = direction
	burst.position = position
	get_parent().add_child(burst)
