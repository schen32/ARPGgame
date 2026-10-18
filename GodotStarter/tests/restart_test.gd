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
	await process_frame
	# Exercise two automatic restarts to catch stale connections or duplicate scenes.
	for attempt in range(2):
		var old_scene = current_scene
		var player = old_scene.get_node("Player")
		player.set_physics_process(false)
		player.position = Vector2(200, 100)
		player.add_experience(150)
		old_scene.get_node("Enemy").take_damage(1000.0)
		player.try_shoot(player.global_position + Vector2.RIGHT * 100.0)
		player.try_spread(player.global_position + Vector2.UP * 100.0)
		player.try_dash(Vector2.RIGHT)
		old_scene._on_enemy_spawn_timer_timeout()
		player.dash_timer = 0.0
		player.dash_active_this_frame = false
		old_scene.get_node("HUD/Interface").inventory.show()
		player.move_skill("equipped", 0, "inventory", 0)
		player.take_damage(1000.0)
		await process_frame
		await process_frame
		check(not is_instance_valid(old_scene), "Death should replace the old game scene automatically")
		var fresh_player = current_scene.get_node("Player")
		check(fresh_player.health.current == 100.0, "Restart should restore full player HP")
		check(fresh_player.level == 1 and fresh_player.experience == 0, "Restart should reset EXP and level")
		check(current_scene.get_node("HUD/Interface").exp_bar.value == 0, "Restart should reset the EXP display")
		check(fresh_player.position == Vector2.ZERO, "Restart should restore starting position")
		check(not fresh_player.inventory_open and not current_scene.get_node("HUD/Interface").inventory.visible, "Restart should close inventory and restore skill input")
		check(fresh_player.equipped_skills == [&"shot", &"spread", &"dash"] and fresh_player.inventory_skills[0] == &"", "Restart should restore default equipped skills and empty storage")
		check(fresh_player.shot_timer == 0.0 and fresh_player.knockback_timer == 0.0, "Restart should clear cooldowns and knockback")
		check(fresh_player.spread_timer == 0.0 and fresh_player.dash_cooldown_timer == 0.0 and fresh_player.dash_timer == 0.0, "Restart should clear spread and dash state")
		check(get_nodes_in_group("enemies").size() == 1, "Restart should restore only the initial enemy")
		check(get_nodes_in_group("projectiles").is_empty(), "Restart should clear projectiles")
		check(get_nodes_in_group("skill_bursts").is_empty(), "Restart should clear active skill particles")
		check(get_nodes_in_group("experience_orbs").is_empty(), "Restart should clear dropped EXP orbs")
		var spawn_timer = current_scene.get_node("EnemySpawnTimer")
		check(not spawn_timer.is_stopped() and spawn_timer.time_left > 3.8, "Restart should reset the spawn timer")
	# An enemy at 1 HP should die and emit its burst on touching the player.
	var enemy = current_scene.get_node("Enemy")
	enemy.set_physics_process(false)
	enemy.take_damage(59.0)
	enemy.position = Vector2(20, 0)
	enemy._physics_process(1.0 / 60.0)
	check(enemy.health.current == 0.0 and enemy.is_queued_for_deletion(), "Contact should kill an enemy at 1 HP")
	check(get_nodes_in_group("death_bursts").size() == 1, "Contact death should emit particles")
	check(current_scene.get_node("Player").health.current == 90.0, "Lethal enemy contact should still damage player")
	print("PASS: automatic repeated restarts, full game reset, 1-HP enemy contact death and particles")
	quit()
