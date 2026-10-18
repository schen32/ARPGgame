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
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	var hud = scene.get_node("HUD/Interface")
	check(hud.slots.size() == 3, "HUD should have three slots")
	check(hud.input_indicators[0].text == "LMB" and hud.input_indicators[1].text == "RMB" and hud.input_indicators[2].text == "SPACE", "Skill indicators should show left mouse, right mouse, and Space in order")
	check(hud.exp_bar.position + hud.exp_bar.size * 0.5 == hud.hp_gauge.position, "EXP semicircle should be centered around HP")
	check(Rect2(Vector2.ZERO, hud.size).encloses(hud.dock.get_rect()), "HUD dock should stay inside the visible play area")
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD should not intercept aiming input")
	check(hud.sweep_icon.get_parent() == hud.slots[0], "Sweep skill should occupy the first slot")
	check(not hud.cooldown_overlay.visible, "Ready skill should have no cooldown mask")
	var shot = player.try_sweep(player.position + Vector2(100, -100))
	check(shot != null, "Sweep skill should fire")
	hud._process(0.0)
	check(hud.cooldown_overlay.visible and is_equal_approx(hud.cooldown_overlay.size.y, 20.0), "Shot should cover the skill with a cooldown mask")
	player.sweep_timer = player.sweep_cooldown * 0.5
	hud._process(0.0)
	check(is_equal_approx(hud.cooldown_overlay.size.y, 10.0), "Cooldown mask should recede halfway through recovery")
	player.sweep_timer = 0.0
	hud._process(0.0)
	check(not hud.cooldown_overlay.visible, "Cooldown mask should disappear when shooting is ready")
	check(hud.cooldown_overlays.size() == 3, "Each skill needs an independent cooldown mask")
	player.try_palm(player.position + Vector2(0, -100))
	player.try_dash(Vector2.RIGHT)
	hud._process(0.0)
	check(hud.cooldown_overlays[1].visible and hud.cooldown_overlays[2].visible and not hud.cooldown_overlays[0].visible, "Spread and dash masks should update independently")
	player.palm_timer = 0.0
	player.dash_cooldown_timer = 0.0
	player.dash_timer = 0.0
	player.dash_active_this_frame = false
	hud._process(0.0)
	check(hud.hp_gauge.fill_ratio == 1.0, "HP gauge should start full")
	player.take_damage(42.0)
	check(is_equal_approx(hud.hp_gauge.fill_ratio, 0.58), "HP gauge must update on damage")
	check(hud.exp_bar.value == 0, "EXP should start empty")
	var enemy = scene.get_node("Enemy")
	enemy.take_damage(1000.0)
	check(player.experience == 0 and hud.exp_bar.value == 0, "Enemy death should drop EXP without awarding it immediately")
	var orb = get_nodes_in_group("experience_orbs")[0]
	player.position = orb.position
	orb._physics_process(1.0 / 60.0)
	check(player.experience == 25 and hud.exp_bar.value == 25, "Collecting an orb should award EXP and update the bar")
	enemy.take_damage(1000.0)
	check(player.experience == 25, "Enemy should not award EXP twice")
	player.add_experience(200)
	check(player.level == 3 and player.experience == 25, "Level-ups should carry surplus EXP")
	check(hud.exp_bar.value == 25, "EXP bar should show leftover EXP after leveling")
	check(hud.exp_bar.surface.material.get_shader_parameter("progress") == 0.25, "EXP arc must reflect experience progress")
	if "--capture" in OS.get_cmdline_user_args():
		player.position = Vector2.ZERO
		scene._on_enemy_spawn_timer_timeout()
		var visible_enemy = get_nodes_in_group("enemies").back()
		visible_enemy.position = Vector2(70, 25)
		visible_enemy.set_physics_process(false)
		await create_timer(0.6).timeout
		player.palm_timer = 0.0
		player.dash_cooldown_timer = 0.0
		player.try_palm(player.position + Vector2(100, 0))
		player.try_dash(Vector2.RIGHT)
		await create_timer(0.05).timeout
		player.sweep_timer = player.sweep_cooldown * 0.5
		player.palm_timer = player.palm_cooldown * 0.7
		player.dash_cooldown_timer = player.dash_cooldown * 0.3
		hud._process(0.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/hud-preview.png")
	print("PASS: HP gauge, three labeled input slots, cooldown display, input passthrough, live EXP arc")
	quit()
