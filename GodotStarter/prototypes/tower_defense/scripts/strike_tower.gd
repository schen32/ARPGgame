extends StaticBody2D
## Place outside the enemy corridor; reuse Strike's arc, knockback, and feedback.
const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
const ATTACK = preload("res://prototypes/tower_defense/scripts/melee_attack.gd")
const PASSIVES = preload("res://prototypes/tower_defense/scripts/passive_tree.gd")
const REACH := 48.0
const COOLDOWN := 0.4
var passive_tree = PASSIVES.new()
var cooldown := 0.0
var strikes_fired := 0

func _ready() -> void:
	add_to_group("strike_towers")
	var geometry := SHAPE.new()
	geometry.shape = 1
	geometry.shape_size = Vector2(20, 20)
	geometry.fill_color = Color("80c8ef")
	geometry.border_color = Color("d3ecff")
	add_child(geometry)
	var collider := CollisionShape2D.new()
	var square := RectangleShape2D.new()
	square.size = Vector2(20, 20)
	collider.shape = square
	add_child(collider)

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown > 0:
		return
	var target = null
	var nearest := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.health.current <= 0:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= REACH + enemy.body_radius + ATTACK.HITBOX_MARGIN and distance < nearest:
			nearest = distance
			target = enemy
	if target == null:
		return
	var attack := ATTACK.new()
	attack.player = self
	attack.reach = REACH
	attack.direction = global_position.direction_to(target.global_position)
	attack.crosses_arena_edge = true
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.start()
	strikes_fired += 1
	cooldown = COOLDOWN

func is_alive() -> bool:
	return not is_queued_for_deletion()

func force_multiplier(_enemy = null) -> float:
	return 1.0

func launch_duration_multiplier() -> float:
	return 1.0

func collision_damage_multiplier(_source, _victim, _previous_impacts: int) -> float:
	return 1.0

func collision_kill() -> void:
	pass
