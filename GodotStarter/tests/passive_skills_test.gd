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
func orb_at(point: Vector2):
	var orb = load("res://scenes/experience_orb.tscn").instantiate()
	orb.target = player
	orb.position = point
	scene.add_child(orb)
	orb.set_physics_process(false)
	return orb
func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").set_physics_process(false)
	var hud = scene.get_node("HUD/Interface")
	var inventory = hud.inventory
	await process_frame
	check(player.equipped_passives == [&"attract_exp", &"", &""] and player.get_exp_attract_radius() == 32, "Attract EXP must be equipped by default with 2m range")
	check(hud.passive_slots.size() == 3 and inventory.passive_slots.size() == 3 and inventory.slots.size() == 18, "HUD and inventory should show three passive slots while keeping 18 storage slots")
	check(not hud.passive_slots[0].overlay.visible, "Passive skill must not have a cooldown overlay")
	var orb = orb_at(Vector2(32, 0))
	orb._physics_process(0.01)
	check(orb.attracted and orb.position.x < 32, "Equipped passive should attract orbs normally")
	check(not player.move_skill("passive", 0, "inventory", 0), "Closed inventory should block passive rearrangement")
	inventory.show()
	check(player.move_skill("equipped", 0, "inventory", 17), "Active skill should still store normally")
	check(not player.move_skill("passive", 0, "inventory", 17), "Occupied storage swap must not displace an active skill into a passive slot")
	check(player.equipped_passives[0] == &"attract_exp" and player.inventory_skills[17] == &"sweep", "Invalid mixed-type swap must preserve both skills")
	check(player.move_skill("inventory", 17, "equipped", 0), "Active skill should return to its binding")
	check(player.move_skill("passive", 0, "inventory", 0), "Passive must be removable into storage")
	check(player.get_exp_attract_radius() == 0 and hud.passive_slots[0].current_skill() == &"", "Unequipping must immediately disable attraction and update both views")
	var before: Vector2 = orb.position
	orb._physics_process(0.1)
	check(not orb.attracted and orb.position == before and player.experience == 0, "Unequipping must stop an already-homing orb")
	orb.position = Vector2(10.6, 0)
	orb._physics_process(0.1)
	check(not orb.collected and orb.position == Vector2(10.6, 0), "Nearby non-overlapping orbs should stay on the floor without the passive")
	orb.position = Vector2(10.5, 0)
	orb._physics_process(0.01)
	orb._physics_process(0.01)
	check(orb.collected and player.experience == 25, "Walking over an orb should collect once without attraction")
	var corner = orb_at(Vector2(10, 10))
	corner._physics_process(0.1)
	check(not corner.collected, "Walk-over pickup should respect square corner distance")
	corner.position = Vector2(9.5, 9.5)
	corner._physics_process(0.01)
	check(corner.collected and player.experience == 50, "Actual corner overlap should collect")
	check(not player.move_skill("inventory", 0, "equipped", 0), "Passive must not equip into an active binding")
	check(not player.move_skill("equipped", 0, "passive", 0), "Active skill must not equip into a passive slot")
	check(not player.move_skill("inventory", 0, "equipped", 1), "Occupied mixed-type swaps must preserve both items")
	player.sweep_timer = 0.2
	check(player.move_skill("inventory", 0, "passive", 2), "Passive should equip into any passive slot")
	check(player.get_exp_attract_radius() == 32 and is_equal_approx(player.sweep_timer, 0.2), "Re-equipping should restore attraction without changing active cooldowns")
	var resumed = orb_at(Vector2(30, 0))
	resumed._physics_process(0.01)
	check(resumed.attracted, "Re-equipped passive should attract nearby orbs")
	resumed.queue_free()
	inventory.hide()
	check(not player.activate_skill(99, Vector2(100, 0)), "Passive slots must not add active key bindings")
	if "--gui" in OS.get_cmdline_user_args():
		inventory.show()
		await process_frame
		await drag_slot(hud.passive_slots[2], inventory.slots[4])
		check(player.equipped_passives[2] == &"" and player.inventory_skills[4] == &"attract_exp" and player.get_exp_attract_radius() == 0, "Native GUI drag must unequip the passive from HUD to storage")
		await drag_slot(inventory.slots[4], inventory.passive_slots[0])
		check(player.equipped_passives[0] == &"attract_exp" and player.inventory_skills[4] == &"", "Native GUI drag must re-equip the passive")
		check(Rect2(Vector2.ZERO, hud.size).encloses(inventory.get_rect()), "Expanded inventory must fit the screen")
	if "--capture" in OS.get_cmdline_user_args():
		inventory.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/passive-skills-preview.png")
	print("PASS: three passive slots, default attraction, storage/equipment validation, immediate homing cancellation, walk-over/corner pickup, re-equip, cooldown preservation")
	quit()

func drag_slot(source: Control, destination: Control) -> void:
	var from: Vector2 = root.get_stretch_transform() * source.get_global_transform_with_canvas() * (source.size * 0.5)
	var to: Vector2 = root.get_stretch_transform() * destination.get_global_transform_with_canvas() * (destination.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = from
	Input.parse_input_event(motion)
	await process_frame
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.position = from
	button.pressed = true
	Input.parse_input_event(button)
	await process_frame
	motion = InputEventMouseMotion.new()
	motion.position = from + Vector2(64, 0)
	motion.relative = Vector2(64, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	check(root.gui_is_dragging(), "Passive drag should start through the native UI")
	motion = InputEventMouseMotion.new()
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	button = InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.position = to
	button.pressed = false
	Input.parse_input_event(button)
	await process_frame
