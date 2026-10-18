extends SceneTree
var scene
var player
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func children_alive() -> Array:
	return get_nodes_in_group("enemies").filter(func(enemy): return not enemy.is_queued_for_deletion() and enemy.body_radius == 6.0)
func big_at(point: Vector2):
	var big = load("res://scenes/big_enemy.tscn").instantiate()
	big.position = point
	scene.add_child(big)
	big.set_physics_process(false)
	return big
func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	# Freeze newly spawned offspring before their first movement tick so placement
	# assertions inspect the spawn positions, rather than subsequent collisions.
	scene.child_entered_tree.connect(func(node):
		if node.is_in_group("enemies") and node.body_radius == 6.0:
			node.process_mode = Node.PROCESS_MODE_DISABLED)
	player = scene.get_node("Player")
	player.set_physics_process(false)
	player.exp_attract_range_meters = 0
	var regular = scene.get_node("Enemy")
	regular.set_physics_process(false)
	regular.position = Vector2(1000, 0)
	var big = big_at(Vector2(55, 0))
	check(big.body_radius == 18 and big.health.current == 120 and big.current_mass() == 2, "Big enemy should be twice the diameter and have more health/weight")
	check(big.get_node("CollisionShape2D").shape.radius == 18 and big.get_node("Geometry").shape_size == Vector2(36, 36), "Big collision and visible sizes must match")
	check(regular.get_node("CollisionShape2D").shape.radius == 9, "Big enemy must not resize shared regular collision resources")
	player.try_sweep(Vector2(100, 0))
	check(big.health.current == 120 - player.sweep_damage, "Sweep must hit the edge of a larger body")
	check(big.knockback_velocity.length() < player.sweep_knockback, "Big enemy must resist launch with its higher mass")
	var palm = player.try_palm(Vector2(100, 0))
	palm.resolve()
	check(big.health.current == 120 - player.sweep_damage - player.palm_damage, "Palm range must account for larger enemy radius")
	big.position = Vector2(40, 24)
	player.try_dash(Vector2.RIGHT)
	player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
	check(big.health.current == 120 - player.sweep_damage - player.palm_damage - player.dash_damage, "Dash must intersect the large enemy edge")
	player.dash_timer = 0
	player.dash_active_this_frame = false
	for attack in get_nodes_in_group("melee_attacks"):
		attack.queue_free()
	big.position = Vector2(200, 0)
	player.position = Vector2(180, 0)
	var wall := StaticBody2D.new()
	wall.position = Vector2(214, 0)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4, 64)
	collider.shape = shape
	wall.add_child(collider)
	scene.add_child(wall)
	await physics_frame
	big.take_damage(1000)
	big.take_damage(1000)
	await process_frame
	await process_frame
	var kids := children_alive()
	check(kids.size() == 4, "Big enemy should split exactly once into four smaller enemies")
	for kid in kids:
		kid.set_physics_process(false)
		check(kid.health.current == 20 and not kid.splits_on_death and kid.target == player, "Offspring should have their own health, chase player, and never split recursively")
		check(kid.get_node("CollisionShape2D").shape.radius == 6, "Offspring collision must match small visuals")
		for other in kids:
			if kid != other:
				check(kid.position.distance_to(other.position) >= 14, "Offspring should appear without overlapping each other")
		var query := PhysicsShapeQueryParameters2D.new()
		var footprint := CircleShape2D.new()
		footprint.radius = 6.9
		query.shape = footprint
		query.collision_mask = 1
		query.transform = Transform2D(0.0, kid.global_position)
		var overlaps = scene.get_world_2d().direct_space_state.intersect_shape(query, 1)
		check(overlaps.is_empty(), "Offspring at %s must avoid player at %s and walls: %s" % [kid.global_position, player.global_position, overlaps])
	for kid in kids:
		kid.take_damage(1000)
	await process_frame
	await process_frame
	check(children_alive().is_empty(), "Small enemies must die normally instead of multiplying")
	check(get_nodes_in_group("experience_orbs").size() == 5, "Parent and four offspring should each drop one EXP orb")
	wall.queue_free()
	regular.queue_free()
	await process_frame
	# All existing lethal attack paths must trigger the same single split.
	for method in ["palm", "dash", "chain"]:
		player.position = Vector2.ZERO
		big = big_at(Vector2(40, 0))
		big.take_damage(119)
		if method == "palm":
			player.palm_timer = 0
			player.try_palm(Vector2(100, 0)).resolve()
		elif method == "dash":
			player.dash_cooldown_timer = 0
			player.try_dash(Vector2.RIGHT)
			player.damage_dash_enemies(Vector2.ZERO, Vector2(48, 0))
			player.dash_timer = 0
			player.dash_active_this_frame = false
		else:
			var source = load("res://scenes/enemy.tscn").instantiate()
			source.position = Vector2(100, 80)
			scene.add_child(source)
			source.set_physics_process(false)
			check(source.transfer_impact(big, Vector2(400, 0), Vector2.RIGHT), "Chain should deliver a lethal impact")
			source.queue_free()
		await process_frame
		await process_frame
		check(children_alive().size() == 4, method + " kill should split into exactly four")
		for kid in children_alive():
			kid.queue_free()
		await process_frame
	for orb in get_nodes_in_group("experience_orbs"):
		orb.queue_free()
	# Every fourth timed spawn is a splitter, with size-aware spawn clearance.
	for i in range(4):
		scene._on_enemy_spawn_timer_timeout()
		var latest = get_nodes_in_group("enemies").back()
		latest.set_physics_process(false)
		check(latest.splits_on_death == (i == 3), "Only every fourth timed spawn should be big")
		for other in get_nodes_in_group("enemies"):
			if other != latest and not other.is_queued_for_deletion():
				check(latest.position.distance_to(other.position) >= latest.body_radius + other.body_radius + 1.9, "Mixed enemy sizes need clear spawn positions")
	if "--capture" in OS.get_cmdline_user_args():
		for enemy in get_nodes_in_group("enemies"):
			enemy.queue_free()
		await process_frame
		big = big_at(Vector2(70, -35))
		var dying = big_at(Vector2(80, 35))
		dying.take_damage(1000)
		await process_frame
		await process_frame
		for kid in children_alive():
			kid.set_physics_process(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/split-enemy-preview.png")
	await create_timer(0.3).timeout
	print("PASS: large/small geometry and health, mass, size-aware melee/dash, four-way split, safe placement, no recursive splitting, rewards, all kill paths, spawn cadence")
	quit()
