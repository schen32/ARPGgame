extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	var enemies: Array[Node2D] = []
	for point in [Vector2(20, 0), Vector2(42, 0), Vector2(24, 35)]:
		var enemy = scene.get_node("Enemy") if enemies.is_empty() else load("res://scenes/enemy.tscn").instantiate()
		if enemy.get_parent() == null:
			scene.add_child(enemy)
		enemy.position = point
		enemy.set_physics_process(false)
		enemies.append(enemy)
	await physics_frame
	player.try_dash(Vector2.RIGHT)
	check(player.dash_visual.visible and player.dash_visual.get_parent() == player, "Dash aura must appear immediately and follow the player")
	check(player.dash_visual.radius == player.dash_hit_radius(), "Dash aura and collision tests must use the same radius")
	player.take_damage(1000.0)
	player.apply_knockback(Vector2.LEFT)
	enemies[0]._physics_process(1.0 / 60.0)
	check(player.health.current == 100.0 and player.knockback_timer == 0.0, "Dash must ignore damage and knockback")
	check(enemies[0].health.current == 60.0, "Invincible dash contact should not trigger normal contact self-damage")
	for frame in range(15):
		await physics_frame
		player._physics_process(1.0 / 60.0)
	check(enemies[0].health.current == 60.0 - player.dash_damage and enemies[1].health.current == 60.0 - player.dash_damage, "Dash must damage each crossed enemy once")
	check(enemies[2].health.current == 60.0, "Dash must not damage enemies away from its path")
	check(enemies[1].knockback_velocity.length() > enemies[1].knockback_speed * 2.0, "Dash should impart much stronger knockback than standard enemy knockback")
	check(enemies[1].knockback_total_duration > enemies[1].knockback_duration, "Dash knockback should last longer than standard enemy knockback")
	check(not player.is_dashing(), "Invincibility must end with the dash")
	check(not player.dash_visual.visible, "Dash aura must disappear when invincibility ends")
	player.take_damage(10.0)
	check(player.health.current == 90.0, "Damage should apply normally after dash")
	# Cross an enemy in one tick; sweeping must still hit, with a new per-dash hit list.
	player.position = Vector2.ZERO
	player.dash_cooldown_timer = 0.0
	player.dash_speed = 4800.0
	player.dash_duration = 0.01
	player.try_dash(Vector2.RIGHT)
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(enemies[0].health.current == 60.0 - 2 * player.dash_damage and enemies[1].health.current == 60.0 - 2 * player.dash_damage, "Fast dash must hit enemies between physics positions")
	check(player.is_dashing(), "Invincibility must cover the final movement tick")
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(not player.is_dashing(), "Final-tick protection should not persist after dash")
	enemies[0].take_damage(enemies[0].health.current - player.dash_damage)
	enemies[1].take_damage(enemies[1].health.current - player.dash_damage)
	player.position = Vector2.ZERO
	player.dash_cooldown_timer = 0.0
	player.try_dash(Vector2.RIGHT)
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(enemies[0].is_queued_for_deletion() and enemies[1].is_queued_for_deletion(), "Dash damage should kill low-health enemies")
	check(get_nodes_in_group("experience_orbs").size() == 2, "Dash kills should drop EXP orbs")
	var pushed_enemy = load("res://scenes/enemy.tscn").instantiate()
	pushed_enemy.position = Vector2(200, 100)
	scene.add_child(pushed_enemy)
	pushed_enemy.set_physics_process(false)
	pushed_enemy.apply_knockback(Vector2.RIGHT, player.dash_knockback_speed, player.dash_knockback_duration)
	var push_start: Vector2 = pushed_enemy.position
	for frame in range(20):
		await physics_frame
		pushed_enemy._physics_process(1.0 / 60.0)
	check(pushed_enemy.position.x - push_start.x > 80.0, "Strong dash knockback should move an unobstructed enemy over five player-widths")
	# Aura must match the damage radius and stay centered in motion.
	player.dash_timer = 0
	player.dash_active_this_frame = false
	player.dash_cooldown_timer = 0
	player.dash_speed = 400
	player.dash_duration = 0.2
	player.try_dash(Vector2.RIGHT)
	check(player.dash_visual.radius == 17 and player.dash_visual.ring.shape_size == Vector2(34, 34), "Dash aura must match the damage radius")
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(player.dash_visual.global_position == player.global_position, "Aura must stay centered while dashing")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/dash-preview.png")
	# Allow one-shot audio playback to drain before engine shutdown.
	await create_timer(0.3).timeout
	print("PASS: dash invincibility, knockback immunity, per-enemy damage, swept hits, final-tick protection, normal damage recovery, kill rewards")
	quit()
