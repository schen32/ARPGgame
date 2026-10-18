extends Node2D
## One committed attack: locked aim, one hit per enemy, brief geometric feedback.
var player
var kind: StringName = &"sweep"
var direction: Vector2 = Vector2.RIGHT
var reach: float = 36.0
var arc_degrees: float = 100.0
var damage: float = 8.0
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

func start() -> void:
	if windup <= 0.0:
		resolve()
	queue_redraw()

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
	queue_redraw()

func sweep_contains(point: Vector2) -> bool:
	var half_angle := deg_to_rad(arc_degrees * 0.5)
	if absf(direction.angle_to(point)) <= half_angle and point.length() <= reach + ENEMY_RADIUS + HITBOX_MARGIN:
		return true
	# Intersect the enemy circle with the sector's two straight edges too.
	for side in [-1.0, 1.0]:
		var edge := direction.rotated(half_angle * side) * reach
		var nearest := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, edge)
		if point.distance_to(nearest) <= ENEMY_RADIUS + HITBOX_MARGIN:
			return true
	return false

func palm_contains(point: Vector2, aim: Vector2) -> bool:
	if point.dot(aim) < 0.0:
		return false
	var nearest := Geometry2D.get_closest_point_to_segment(point, Vector2.ZERO, aim * reach)
	return point.distance_to(nearest) <= PALM_HALF_WIDTH + ENEMY_RADIUS + HITBOX_MARGIN

func resolve() -> void:
	if resolved or not is_instance_valid(player) or not player.is_alive():
		return
	resolved = true
	check_hits()

func check_hits() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if kind == &"sweep":
		for enemy in enemies:
			if valid_enemy(enemy) and sweep_contains(enemy.global_position - global_position):
				hit(enemy, direction)
	elif not palm_hit:
		var closest = null
		var distance := INF
		for enemy in enemies:
			if not valid_enemy(enemy):
				continue
			var offset: Vector2 = enemy.global_position - global_position
			if not palm_contains(offset, direction):
				continue
			var lateral := offset.cross(direction)
			var radius := PALM_HALF_WIDTH + ENEMY_RADIUS + HITBOX_MARGIN
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
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return
	hit_ids[enemy.get_instance_id()] = true
	enemy.take_damage(damage)
	if not enemy.is_queued_for_deletion():
		enemy.apply_knockback(aim, knockback_strength, 0.22 if kind == &"sweep" else 0.35)

func _draw() -> void:
	var color := Color("80c8ef")
	var progress := clampf((age - windup) / FLASH_DURATION, 0.0, 1.0)
	if not resolved:
		color.a = 0.2 + 0.4 * clampf(age / maxf(windup, 0.001), 0.0, 1.0)
	else:
		color.a = 1.0 - progress
	if kind == &"sweep":
		var center := direction.angle()
		var half := deg_to_rad(arc_degrees * 0.5)
		var points := PackedVector2Array([Vector2.ZERO])
		for i in range(25):
			points.append(Vector2.RIGHT.rotated(center - half + 2.0 * half * i / 24.0) * reach)
		draw_colored_polygon(points, Color(color, color.a * 0.12))
		draw_arc(Vector2.ZERO, reach, center - half, center + half, 32, color, 2.0, true)
		var tip := Vector2.RIGHT.rotated(center - half + progress * half * 2.0) * reach
		draw_line(tip * 0.45, tip, Color(color, color.a * 0.8), 3.0, true)
	else:
		var tip := direction * reach
		draw_line(direction * 8.0, tip, Color(color, color.a * 0.35), PALM_HALF_WIDTH * 2.0, true)
		draw_line(direction * 8.0, tip, color, 1.0 if not resolved else 3.0, true)
		var side := direction.orthogonal() * PALM_HALF_WIDTH
		draw_line(tip - side, tip + side, color, 2.0, true)
