extends RefCounted
## Deferred split placement respects living circles, the player and solid geometry.
const CHILD_RADIUS: float = 6.0

static func spawn_children(world, origin: Vector2, target) -> void:
	if not is_instance_valid(world) or world.is_queued_for_deletion():
		return
	if is_instance_valid(target) and target.has_method("is_alive") and not target.is_alive():
		return
	# Runtime load avoids an enemy-script / inherited-scene preload cycle.
	var scene := load("res://scenes/small_enemy.tscn") as PackedScene
	for i in range(4):
		var point := find_clear_position(world, origin, i)
		if point == Vector2.INF:
			push_warning("No clear space for split offspring")
			continue
		var child := scene.instantiate()
		child.position = world.to_local(point)
		world.add_child(child)
		child.target = target if is_instance_valid(target) else null
		child.apply_knockback((point - origin).normalized(), 80.0 * child.current_mass(), 0.18)

static func find_clear_position(world: Node2D, origin: Vector2, index: int) -> Vector2:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = CHILD_RADIUS + 1.0
	query.shape = shape
	query.collision_mask = 1 # Player and walls; living enemies checked explicitly below.
	for attempt in range(256):
		var radius := 12.0 + floorf(attempt / 16.0) * 12.0
		var angle := PI * 0.25 + index * PI * 0.5 + (attempt % 16) * TAU / 16.0
		var point := origin + Vector2.from_angle(angle) * radius
		var clear := true
		for enemy in world.get_tree().get_nodes_in_group("enemies"):
			if enemy.is_queued_for_deletion() or enemy.health.current <= 0:
				continue
			if point.distance_to(enemy.global_position) < CHILD_RADIUS + enemy.body_radius + 2.0:
				clear = false
				break
		if not clear:
			continue
		query.transform = Transform2D(0.0, point)
		if world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return point
	return Vector2.INF
