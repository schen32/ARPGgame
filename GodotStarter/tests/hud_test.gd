extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.get_node("GoblinSpawnTimer").stop()
	var player = scene.player
	assert(player.health == player.max_health)
	assert(player.mana == player.max_mana)
	player.take_damage(32.0)
	assert(player.health == 68.0)
	var enemy = load("res://scenes/goblin.tscn").instantiate()
	enemy.target = player
	enemy.position = Vector2(50, 0)
	scene.add_child(enemy)
	player.cast_spell()
	assert(player.mana == 85.0)
	assert(enemy.health == 40.0)
	player.cast_spell()
	assert(player.mana == 85.0, "Cooldown must prevent repeated mana spending")
	var heal := InputEventKey.new()
	heal.pressed = true
	heal.physical_keycode = KEY_H
	player._unhandled_key_input(heal)
	assert(player.health == 100.0)
	assert(player.mana == 60.0)
	player.mana = 0.0
	player.attack_cooldown = 0.0
	player.cast_spell()
	assert(enemy.health == 40.0, "No spell damage without mana")
	player._physics_process(1.0)
	assert(player.mana > 0.0, "Mana must regenerate")
	enemy.position = player.position + Vector2(12, 0)
	enemy._physics_process(0.01)
	assert(player.health == 92.0, "Contact should damage player")
	enemy.take_damage(100.0)
	assert(enemy.is_queued_for_deletion())
	await process_frame
	player.position = Vector2(100, 100)
	player.take_damage(1000.0)
	assert(player.health == player.max_health)
	assert(player.position == Vector2.ZERO)
	assert(scene.get_node("HUD/Interface").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	if "--capture" in OS.get_cmdline_user_args():
		player.take_damage(32.0)
		player.mana = 58.0
		for pos in [Vector2(95, 40), Vector2(-70, -25), Vector2(180, -80)]:
			var goblin = load("res://scenes/goblin.tscn").instantiate()
			goblin.position = pos
			goblin.target = player
			scene.add_child(goblin)
			goblin.take_damage(15.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../output/ui-variants-2026-10-16/moonlit-in-game.png")
	print("PASS: HUD loads, damage, mana cost/cooldown/regeneration, heal, enemy death, contact, respawn")
	quit()
