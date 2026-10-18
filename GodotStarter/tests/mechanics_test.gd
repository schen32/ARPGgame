extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	var enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	var full_speed: float = enemy.current_move_speed()
	var full_damage: float = enemy.current_contact_damage()
	enemy.apply_knockback(Vector2.RIGHT)
	var full_launch: float = enemy.knockback_velocity.length()
	enemy.take_damage(30)
	check(enemy.current_mass() < 1.0 and enemy.current_move_speed() > full_speed and enemy.current_contact_damage() < full_damage, "Wounded enemies must be lighter, faster, less damaging")
	enemy.apply_knockback(Vector2.RIGHT)
	check(enemy.knockback_velocity.length() > full_launch, "Health-based mass must amplify knockback")
	var next = load("res://scenes/enemy.tscn").instantiate()
	scene.add_child(next)
	next.position = enemy.position + Vector2.RIGHT * 18
	next.set_physics_process(false)
	var launch := Vector2(400, 0)
	var initial_energy: float = enemy.current_mass() * launch.length_squared()
	var source_mass: float = enemy.current_mass()
	var target_mass: float = next.current_mass()
	check(enemy.transfer_impact(next, launch, Vector2.RIGHT), "Fast enemy must transfer an impact")
	check(next.health.current < 60 and enemy.health.current < 30 and next.knockback_velocity.x > 0, "Impact must damage both bodies and launch target")
	check(source_mass * enemy.knockback_velocity.length_squared() + target_mass * next.knockback_velocity.length_squared() < initial_energy, "Chain must dissipate kinetic energy")
	check(not next.transfer_impact(enemy, Vector2(-400, 0), Vector2.LEFT), "Shared chain history must prevent ping-pong")
	enemy.impact_chain = {}
	check(not enemy.transfer_impact(next, Vector2(20, 0), Vector2.RIGHT), "Resting contact must not create impacts")
	check(get_nodes_in_group("impact_bursts").size() == 1, "Impact should emit sparks once")
	enemy.impact_chain = {enemy.get_instance_id(): true}
	for i in range(7):
		enemy.impact_chain[-i - 1] = true
	check(not enemy.transfer_impact(next, Vector2(800, 0), Vector2.RIGHT), "Chain size must stop at eight bodies")
	# Actual CharacterBody collision, rather than only calling the transfer helper.
	enemy.queue_free()
	next.queue_free()
	await process_frame
	var bodies: Array = []
	for i in range(3):
		var body = load("res://scenes/enemy.tscn").instantiate()
		body.position = Vector2(100 + i * 22, 0)
		scene.add_child(body)
		body.target = null
		bodies.append(body)
	bodies[0].apply_knockback(Vector2.RIGHT, 650, 0.35)
	for frame in range(12):
		await physics_frame
	check(bodies[1].health.current < 60 and bodies[2].health.current < 60, "Real collisions should chain through three enemies")
	for body in bodies:
		body.queue_free()
	await process_frame
	check(player.inventory_skills.all(func(item): return item == &""), "Inventory should begin with empty storage")
	check(scene.get_node("HUD/Interface").slots.size() == 3, "HUD should expose only the three base skill slots")
	print("PASS: health weight, real impact chains, energy loss, loop guards, empty starter inventory")
	quit()
