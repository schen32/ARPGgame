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
func enemy_at(point: Vector2):
	var enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = point
	scene.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy
func clear_combat() -> void:
	for group in ["enemies", "melee_attacks"]:
		for child in get_nodes_in_group(group):
			child.queue_free()
	player.sweep_timer = 0
	player.palm_timer = 0
	player.position = Vector2.ZERO
func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	player = scene.get_node("Player")
	player.set_physics_process(false)
	scene.get_node("Enemy").queue_free()
	await process_frame
	var front = enemy_at(Vector2(25, 0))
	var side = enemy_at(Vector2.RIGHT.rotated(deg_to_rad(45)) * 25)
	var behind = enemy_at(Vector2(-25, 0))
	var far = enemy_at(Vector2(50, 0))
	var sweep = player.try_sweep(Vector2(100, 0))
	check(sweep != null and front.health.current == 60 - player.sweep_damage and side.health.current == 60 - player.sweep_damage, "Sweep should hit multiple enemies in its short forward arc")
	check(behind.health.current == 60 and far.health.current == 60, "Sweep must exclude rear and distant enemies")
	check(front.knockback_velocity.x > 0 and side.knockback_velocity.x > 0 and is_zero_approx(side.knockback_velocity.y), "Sweep must push the group toward aim, rather than scatter radially")
	sweep.resolve()
	check(front.health.current == 60 - player.sweep_damage, "One swing must never hit an enemy twice")
	check(player.try_sweep(Vector2(100, 0)) == null and player.sweep_timer == 0.4, "Sweep cooldown must block held-button spam")
	clear_combat()
	await process_frame
	front = enemy_at(Vector2(22, 0))
	var rear = enemy_at(Vector2(40, 0))
	side = enemy_at(Vector2(20, 23))
	var palm = player.try_palm(Vector2(100, 0))
	palm.set_physics_process(false)
	check(not palm.resolved and front.health.current == 60, "Palm must telegraph before dealing damage")
	palm._physics_process(0.14)
	check(front.health.current == 60, "Palm must respect 0.15s windup")
	# The palm retains its initial aim during windup.
	palm._physics_process(0.02)
	check(front.health.current == 60 - player.palm_damage and rear.health.current == 60 and side.health.current == 60, "Base palm must strike only nearest enemy in narrow lane")
	check(is_equal_approx(front.knockback_velocity.x, player.palm_knockback), "Palm launch must use mass at contact before direct damage")
	check(player.try_palm(Vector2(100, 0)) == null, "Palm must have a longer cooldown")
	clear_combat()
	await process_frame
	# Real melee knockback must feed the existing collision-chain system.
	front = enemy_at(Vector2(25, 0))
	rear = enemy_at(Vector2(47, 0))
	rear.set_physics_process(true)
	front.set_physics_process(true)
	front.target = null
	rear.target = null
	palm = player.try_palm(Vector2(100, 0))
	palm.resolve()
	for frame in range(12):
		await physics_frame
	check(rear.health.current < 60, "Heavy palm must cause secondary collision damage")
	clear_combat()
	await process_frame
	# Active attack shapes and visuals track movement, without repeat damage.
	clear_combat()
	await process_frame
	front = enemy_at(Vector2(65, 0))
	sweep = player.try_sweep(Vector2(100, 0))
	sweep.set_physics_process(false)
	check(front.health.current == 60, "Enemy should begin outside enlarged sweep")
	player.position = Vector2(30, 0)
	sweep._physics_process(0.04)
	check(sweep.global_position == player.global_position and front.health.current == 60 - player.sweep_damage, "Moving sweep must stay centered and hit enemies entering its active arc")
	player.position = Vector2(32, 0)
	sweep._physics_process(0.04)
	check(sweep.global_position == player.global_position and front.health.current == 60 - player.sweep_damage, "Moving sweep must not repeatedly damage the same enemy")
	clear_combat()
	await process_frame
	front = enemy_at(Vector2(80, 0))
	rear = enemy_at(Vector2(95, 0))
	palm = player.try_palm(Vector2(100, 0))
	palm.set_physics_process(false)
	player.position = Vector2(15, 0)
	palm._physics_process(0.16)
	check(palm.global_position == player.global_position and front.health.current == 60, "Palm should follow through windup and initially miss out-of-range target")
	player.position = Vector2(25, 0)
	palm._physics_process(0.02)
	check(palm.global_position == player.global_position and front.health.current == 60 - player.palm_damage, "Active palm must follow movement and hit at its new center")
	player.position = Vector2(50, 0)
	palm._physics_process(0.02)
	check(palm.global_position == player.global_position and front.health.current == 60 - player.palm_damage and rear.health.current == 60, "Used palm lane must remain centered without hitting additional targets")
	clear_combat()
	await process_frame
	front = enemy_at(Vector2(41, 0))
	player.try_sweep(Vector2(100, 0))
	check(front.health.current == 60 - player.sweep_damage, "Sweep must reach beyond old hitbox")
	clear_combat()
	await process_frame
	front = enemy_at(Vector2(48, 15))
	palm = player.try_palm(Vector2(100, 0))
	palm.resolve()
	check(front.health.current == 60 - player.palm_damage, "Palm must have longer reach and a wider lane")
	clear_combat()
	await process_frame
	# Solid geometry blocks melee, just as it blocks movement.
	var wall := StaticBody2D.new()
	wall.position = Vector2(14, 0)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2, 80)
	collision.shape = rectangle
	wall.add_child(collision)
	scene.add_child(wall)
	front = enemy_at(Vector2(27, 0))
	await physics_frame
	player.try_sweep(Vector2(100, 0))
	palm = player.try_palm(Vector2(100, 0))
	palm.resolve()
	check(front.health.current == 60, "Melee attacks must not damage through walls")
	wall.queue_free()
	clear_combat()
	await process_frame
	player.inventory_open = true
	check(player.try_sweep(Vector2(100, 0)) == null and player.try_palm(Vector2(100, 0)) == null, "Inventory must block both melee attacks")
	player.inventory_open = false
	check(player.try_sweep(player.position) == null and player.try_palm(player.position) == null, "Zero aim must not consume a cooldown")
	check(player.sweep_timer == 0 and player.palm_timer == 0, "Invalid attacks must preserve cooldowns")
	# Small forgiving margins surround the rendered shapes; distant targets miss.
	sweep = player.try_sweep(Vector2(100, 0))
	check(sweep.sweep_contains(Vector2(sweep.reach + 11.5, 0)), "Sweep should accept contact slightly beyond the visible arc")
	check(not sweep.sweep_contains(Vector2(sweep.reach + 12.5, 0)), "Sweep margin must remain small")
	palm = player.try_palm(Vector2(100, 0))
	check(palm.palm_contains(Vector2(25, 19.5), Vector2.RIGHT), "Palm should accept contact slightly outside its visible width")
	check(not palm.palm_contains(Vector2(25, 20.5), Vector2.RIGHT), "Palm width margin must remain small")
	check(palm.palm_contains(Vector2(palm.reach + 19.5, 0), Vector2.RIGHT), "Palm end cap should include the forgiving margin")
	check(not palm.palm_contains(Vector2(palm.reach + 20.5, 0), Vector2.RIGHT), "Palm end margin must remain bounded")
	clear_combat()
	await process_frame
	# Capture a readable windup and sweep together for visual verification.
	if "--capture" in OS.get_cmdline_user_args():
		front = enemy_at(Vector2(30, 0))
		player.try_sweep(Vector2(100, 0))
		palm = player.try_palm(Vector2(100, 0))
		palm.set_physics_process(false)
		palm._physics_process(0.1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.codex/melee-preview.png")
	# Let asynchronous one-shot playback finish before headless engine shutdown.
	await create_timer(0.35).timeout
	print("PASS: melee arc/range, nearest palm target, windup, once-per-attack hits, cooldowns, chain damage, walls, input guards, enlarged hitboxes, moving active attacks")
	quit()
