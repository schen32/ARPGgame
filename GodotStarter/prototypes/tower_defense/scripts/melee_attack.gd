extends Node2D
## One committed attack: locked aim, one hit per enemy, brief geometric feedback.
const HIT_BURST = preload("res://prototypes/tower_defense/scripts/hit_burst.gd")
const VISUAL = preload("res://prototypes/tower_defense/scripts/attack_visual.gd")
const IMPACT_AUDIO = preload("res://prototypes/tower_defense/scripts/impact_audio.gd")
var player
var crosses_arena_edge: bool = false
var visual: Node2D
var kind: StringName = &"sweep"
var direction: Vector2 = Vector2.RIGHT
var reach: float = 36.0
var area_multiplier: float = 1.0
var arc_degrees: float = 100.0
var damage: float = 4.0
var knockback_strength: float = 330.0
var windup: float = 0.0
var resolved: bool = false
var age: float = 0.0
var hit_ids: Dictionary = {}
var palm_hit: bool = false
const ENEMY_RADIUS: float = 9.0
# Collision forgiveness only: rendering continues to use the original dimensions.
const HITBOX_MARGIN: float = 3.0
const PALM_HALF_WIDTH: float = 8.0
const FLASH_DURATION: float = 0.18

func _ready() -> void:
	add_to_group("melee_attacks")
	z_index = 3
	visual = VISUAL.new()
	add_child(visual)

func start() -> void:
	if windup <= 0.0:
		resolve()
	update_visual()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_alive():
		queue_free()
		return
	age += delta
	global_position = player.global_position
	if age >= windup + FLASH_DURATION:
		queue_free()
		return
	if not resolved and age >= windup:
		resolve()
	elif resolved:
		check_hits()
	update_visual()

func sweep_contains(point: Vector2, enemy_radius: float = ENEMY_RADIUS) -> bool:
	var half_angle := deg_to_rad(arc_degrees * 0.5)
	if absf(direction.angle_to(point)) <= half_angle and point.length() <= reach + enemy_radius + HITBOX_MARGIN:
		return true
	# Intersect the enemy circle with the sector's two straight edges too.
	for side in [-1.0, 1.0]:
		var edge := direction.rotated(half_angle * side) * reach
		var nearest := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, edge)
		if point.distance_to(nearest) <= enemy_radius + HITBOX_MARGIN:
			return true
	return false

func palm_contains(point: Vector2, aim: Vector2, enemy_radius: float = ENEMY_RADIUS) -> bool:
	if point.dot(aim) < 0.0:
		return false
	var nearest := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, aim * reach)
	return point.distance_to(nearest) <= PALM_HALF_WIDTH * area_multiplier + enemy_radius + HITBOX_MARGIN

func resolve() -> void:
	if resolved or not is_instance_valid(player) or not player.is_alive():
		return
	resolved = true
	IMPACT_AUDIO.melee_use(self, global_position, kind)
	check_hits()

func check_hits() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if kind == &"sweep":
		for enemy in enemies:
			if valid_enemy(enemy) and sweep_contains(enemy.global_position - global_position, enemy.body_radius):
				hit(enemy, direction)
	elif not palm_hit:
		var closest = null
		var distance := INF
		for enemy in enemies:
			if not valid_enemy(enemy):
				continue
			var offset: Vector2 = enemy.global_position - global_position
			if not palm_contains(offset, direction, enemy.body_radius):
				continue
			var lateral := offset.cross(direction)
			var radius: float = PALM_HALF_WIDTH * area_multiplier + enemy.body_radius + HITBOX_MARGIN
			var entry := offset.dot(direction) - sqrt(maxf(0.0, radius * radius - lateral * lateral))
			if entry < distance:
				closest = enemy
				distance = entry
		if is_instance_valid(closest):
			var target_id: int = closest.get_instance_id()
			hit(closest, direction)
			palm_hit = hit_ids.has(target_id)

func valid_enemy(enemy) -> bool:
	return not enemy.is_queued_for_deletion() and enemy.health.current > 0.0

func hit(enemy, aim: Vector2) -> void:
	if not valid_enemy(enemy) or hit_ids.has(enemy.get_instance_id()):
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1, [player.get_rid()])
	if not crosses_arena_edge and not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return
	hit_ids[enemy.get_instance_id()] = true
	HIT_BURST.spawn(self, enemy.global_position, aim, maxf(0.0, enemy.body_radius - 2.0))
	IMPACT_AUDIO.attack_hit(self, enemy.global_position, knockback_strength)
	enemy.receive_attack(aim, knockback_strength, damage, 0.22 if kind == &"sweep" else 0.35, player)

func update_visual() -> void:
	var progress := clampf((age - windup) / FLASH_DURATION, 0.0, 1.0)
	var opacity := 1.0 - progress if resolved else 0.2 + 0.4 * clampf(age / maxf(windup, 0.001), 0.0, 1.0)
	visual.update_effect({"effect_kind": 0 if kind == &"sweep" else 1, "radius": reach,
		"aim": direction, "half_angle": deg_to_rad(arc_degrees * 0.5), "half_width": PALM_HALF_WIDTH * area_multiplier,
		"progress": progress, "opacity": opacity, "windup": not resolved})
