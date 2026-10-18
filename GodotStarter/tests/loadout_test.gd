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
	scene.get_node("Enemy").set_physics_process(false)
	var hud = scene.get_node("HUD/Interface")
	var inventory = hud.inventory
	check(inventory.equipped_slots.size() == 3 and inventory.slots.size() == 18, "Inventory should display equipment and storage slots")
	check(not player.move_skill("equipped", 0, "inventory", 0), "Closed inventory must not permit rearranging skills")
	inventory.show()
	await process_frame
	var data = {"kind": "skill", "owner_id": player.get_instance_id(), "zone": "equipped", "index": 0, "skill": &"shot"}
	check(inventory.slots[0]._can_drop_data(Vector2.ZERO, data), "Storage slot should accept equipped skill")
	inventory.slots[0]._drop_data(Vector2.ZERO, data)
	check(player.equipped_skills[0] == &"" and player.inventory_skills[0] == &"shot", "Moving to storage must unequip skill without duplication")
	check(hud.slots[0].current_skill() == &"" and inventory.equipped_slots[0].current_skill() == &"", "HUD and inventory equipment views must stay synchronized")
	inventory.hide()
	check(not player.activate_skill(0, player.position + Vector2.RIGHT * 100.0), "Empty equipped slot must not activate an ability")
	inventory.show()
	check(player.move_skill("inventory", 0, "equipped", 1), "Stored skill should swap with occupied equipment")
	check(player.equipped_skills[1] == &"shot" and player.inventory_skills[0] == &"spread", "Occupied drop must preserve displaced skill")
	check(player.move_skill("inventory", 0, "inventory", 17), "Skills should move between inventory slots")
	check(player.move_skill("inventory", 17, "equipped", 0), "Skill should equip to an empty slot")
	player.spread_timer = player.spread_cooldown * 0.5
	hud._process(0.0)
	check(hud.cooldown_overlays[0].visible and not hud.cooldown_overlays[1].visible, "Cooldown overlay should follow skill, not original key")
	check(player.move_skill("equipped", 0, "equipped", 2), "Equipped skills should swap")
	hud._process(0.0)
	check(player.equipped_skills[0] == &"dash" and player.equipped_skills[2] == &"spread", "Equipment swap should remap bindings")
	check(hud.cooldown_overlays[2].visible and player.spread_timer > 0.0, "Moving a skill must not reset cooldown")
	check(not inventory.slots[1]._can_drop_data(Vector2.ZERO, {"kind": "other"}), "Invalid drag data must be rejected")
	check(not player.move_skill("inventory", 99, "equipped", 0), "Invalid indices must be rejected")
	inventory.hide()
	check(player.activate_skill(0, player.position + Vector2.RIGHT * 100.0) and player.is_dashing(), "Left mouse slot should activate reassigned dash")
	check(player.activate_skill(1, player.position + Vector2.UP * 100.0), "Right mouse slot should activate reassigned single shot")
	player.spread_timer = 0.0
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	player._unhandled_key_input(space)
	check(player.spread_timer == player.spread_cooldown, "Space must activate the skill equipped in its slot")
	# Test actual Godot GUI drag-and-drop, including the preview and release.
	inventory.show()
	await process_frame
	var source = inventory.equipped_slots[1]
	var destination = inventory.slots[2]
	var from: Vector2 = root.get_stretch_transform() * source.get_global_transform_with_canvas() * (source.size * 0.5)
	var to: Vector2 = root.get_stretch_transform() * destination.get_global_transform_with_canvas() * (destination.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = from
	Input.parse_input_event(motion)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = from
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	motion = InputEventMouseMotion.new()
	motion.position = from + Vector2(64, 0)
	motion.relative = Vector2(64, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	check(root.gui_is_dragging(), "Mouse movement should begin a real skill drag")
	motion = InputEventMouseMotion.new()
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = to
	press.pressed = false
	Input.parse_input_event(press)
	await process_frame
	check(player.inventory_skills[2] == &"shot" and player.equipped_skills[1] == &"", "Mouse release must commit the real GUI drop")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/loadout-preview.png")
	print("PASS: skill storage/equipment swaps, remapped controls, cooldown preservation, validation, real GUI drag/drop")
	quit()
