extends Node2D

const ENEMY = preload("res://prototypes/tower_defense/scenes/enemy.tscn")
const BIG_ENEMY = preload("res://prototypes/tower_defense/scenes/big_enemy.tscn")

const LAYOUT = preload("res://prototypes/tower_defense/scripts/floor.gd")
const TOWER = preload("res://prototypes/tower_defense/scripts/strike_tower.gd")
const BUILD_BOUNDS := Rect2(-244, -142, 488, 286)
const TOWER_HALF_SIZE := 10.0
const TOWER_COST := 40
const STARTING_GOLD := 120
signal currency_changed(gold: int)
signal selection_changed
const SPAWN_X = LAYOUT.SPAWN_X
const SPAWN_Y = LAYOUT.SPAWN_Y
const EXIT_X = LAYOUT.EXIT_X
const EXIT_Y = LAYOUT.EXIT_Y
@export_range(1, 100) var big_enemy_interval: int = 4
var spawn_count: int = 0
var escaped_count: int = 0
var placement_preview
var gold: int = STARTING_GOLD
var selected_tower: StringName = &""

func _ready() -> void:
	_build_walls()
	placement_preview = TOWER.SHAPE.new()
	placement_preview.shape = 1
	placement_preview.shape_size = Vector2.ONE * TOWER_HALF_SIZE * 2.0
	placement_preview.modulate.a = 0.4
	placement_preview.z_index = 5
	add_child(placement_preview)
	placement_preview.hide()

func _process(_delta: float) -> void:
	var point := get_global_mouse_position()
	placement_preview.visible = selected_tower == &"strike" and BUILD_BOUNDS.has_point(point) and not is_inside_arena(point)
	if placement_preview.visible:
		placement_preview.position = point
		var valid := can_place_tower(point)
		placement_preview.fill_color = Color("80c8ef") if valid else Color("de6b67")
		placement_preview.border_color = Color("d3ecff") if valid else Color("ffd0bd")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		select_tower(&"")
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if place_tower(point) != null:
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			select_tower(&"strike")
		elif event.keycode == KEY_ESCAPE:
			select_tower(&"")
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene.call_deferred()

func select_tower(kind: StringName) -> void:
	selected_tower = kind if kind == &"strike" else &""
	selection_changed.emit()

func enemy_defeated(enemy) -> void:
	gold += enemy.currency_reward
	currency_changed.emit(gold)

func can_place_tower(point: Vector2) -> bool:
	if selected_tower != &"strike" or gold < TOWER_COST or not BUILD_BOUNDS.grow(-TOWER_HALF_SIZE - 2.0).has_point(point):
		return false
	var footprint := Rect2(point - Vector2.ONE * 12.0, Vector2.ONE * 24.0)
	var corners := [footprint.position, footprint.position + Vector2(footprint.size.x, 0), footprint.end, footprint.position + Vector2(0, footprint.size.y)]
	for corner in corners:
		if is_inside_arena(corner):
			return false
	var boundary := LAYOUT.outline()
	for i in range(boundary.size()):
		if footprint.has_point(boundary[i]):
			return false
		for j in range(4):
			if Geometry2D.segment_intersects_segment(boundary[i], boundary[(i + 1) % boundary.size()], corners[j], corners[(j + 1) % 4]) != null:
				return false
	for tower in get_tree().get_nodes_in_group("strike_towers"):
		if not tower.is_queued_for_deletion() and absf(point.x - tower.position.x) < 24.0 and absf(point.y - tower.position.y) < 24.0:
			return false
	return not is_inside_arena(point)

func place_tower(point: Vector2):
	if not can_place_tower(point):
		return null
	var tower := TOWER.new()
	tower.position = point
	add_child(tower)
	gold -= TOWER_COST
	currency_changed.emit(gold)
	return tower

func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "ArenaWalls"
	walls.add_to_group("arena_walls")
	add_child(walls)
	var boundary := LAYOUT.outline()
	for i in range(boundary.size()):
		var a: Vector2 = boundary[i]
		var b: Vector2 = boundary[(i + 1) % boundary.size()]
		# Edge shapes follow concave corners without filling adjacent chambers.
		var collider := CollisionShape2D.new()
		var edge := SegmentShape2D.new()
		edge.a = a
		edge.b = b
		collider.shape = edge
		walls.add_child(collider)

func is_inside_arena(point: Vector2, radius: float = 0.0) -> bool:
	return LAYOUT.contains_point(point, radius)

func enemy_travel_direction(enemy) -> Vector2:
	var point: Vector2 = enemy.global_position
	while enemy.next_waypoint < LAYOUT.FLOW.size() - 1 and point.distance_to(LAYOUT.FLOW[enemy.next_waypoint]) <= 5.0:
		enemy.next_waypoint += 1
	return point.direction_to(LAYOUT.FLOW[enemy.next_waypoint])

func enemy_reached_exit(enemy) -> void:
	if enemy.is_queued_for_deletion() or enemy.health.current <= 0:
		return
	escaped_count += 1
	# Escaping is not a kill: no EXP, death effects, or split offspring.
	enemy.queue_free()

func _on_enemy_spawn_timer_timeout() -> void:
	var spawn_big := (spawn_count + 1) % big_enemy_interval == 0
	var body_radius := 18.0 if spawn_big else 9.0
	# Find room for the new circle, rather than spawning it inside another one.
	for attempt in range(48):
		var spawn_point := Vector2(SPAWN_X + randf_range(-LAYOUT.PATH_HALF_WIDTH + body_radius + 3, LAYOUT.PATH_HALF_WIDTH - body_radius - 3), SPAWN_Y)
		var clear := true
		for other in get_tree().get_nodes_in_group("enemies"):
			if not other.is_queued_for_deletion() and other.global_position.distance_to(spawn_point) < body_radius + other.body_radius + 2.0:
				clear = false
				break
		if clear:
			var enemy := BIG_ENEMY.instantiate() if spawn_big else ENEMY.instantiate()
			enemy.position = to_local(spawn_point)
			add_child(enemy)
			spawn_count += 1
			return
