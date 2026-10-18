extends SceneTree
var scene
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func enemy_at(at: Vector2, big: bool = false):
	var body = load("res://scenes/big_enemy.tscn" if big else "res://scenes/enemy.tscn").instantiate()
	body.position = at
	scene.add_child(body)
	body.set_physics_process(false)
	body.target = null
	return body
func run_checks() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.get_node("EnemySpawnTimer").stop()
	scene.get_node("Enemy").queue_free()
	var player = scene.get_node("Player")
	player.set_physics_process(false)
	await process_frame
	var tree = player.passive_tree
	check(tree.NODES.size() == 16 and tree.points == 0, "Tree should start with 16 passive nodes and no points")
	check(not tree.buy(&"heavy_hands") and not tree.buy(&"invalid"), "No free purchases or unknown nodes")
	player.add_experience(450)
	check(player.level == 5 and tree.points == 4 and player.experience == 50, "Every crossed level must grant exactly one point and preserve overflow")
	check(not tree.buy(&"follow_through") and not tree.buy(&"wrecking_ball"), "Branch tiers must require 3/6/9 spent points")
	for i in range(3):
		check(tree.buy(&"heavy_hands"), "First node should accept three ranks")
	check(not tree.buy(&"heavy_hands") and tree.can_buy(&"follow_through"), "Rank caps and tier unlock should be enforced")
	tree.respec()
	check(tree.points == 4 and tree.ranks.is_empty(), "Respec should refund spent points exactly")
	player.add_experience(3550)
	check(tree.points == 40 and tree.earned_points == player.level - 1, "Total point budget should equal levels earned")
	for node in tree.NODES:
		for i in range(node.ranks):
			check(tree.buy(node.id), "All sixteen nodes should be reachable through branch prerequisites")
	check(tree.points == 0 and not tree.buy(&"domino"), "Spending must never create negative points")
	check(is_equal_approx(player.health.max_health, 130) and player.health.current == 100, "Vitality must increase max HP without free healing")
	check(is_equal_approx(player.attack_area_multiplier(), 1.15), "Extended Reach must increase every attack area")
	check(is_equal_approx(player.launch_duration_multiplier(), 1.24), "Driving Force must increase all launch travel times")
	var target = enemy_at(Vector2(51, 0))
	var sweep = player.try_sweep(Vector2(100, 0))
	check(target.health.current == 56, "Global reach must let Strike hit beyond its base range")
	check(is_equal_approx(target.knockback_velocity.x, 330 * 1.24), "Heavy Hands must increase actual Strike impulse")
	check(is_equal_approx(target.knockback_total_duration, 0.22 * 1.24), "Driving Force must affect actual knockback")
	check(is_equal_approx(player.force_multiplier(target), 1.54), "Follow Through should boost force against a launched target")
	var large = enemy_at(Vector2(1000, 0), true)
	check(is_equal_approx(player.force_multiplier(large), 1.6), "Giant Killer should boost large-target force")
	large.knockback_timer = 1
	check(is_equal_approx(player.force_multiplier(large), 1.9), "Conditional force bonuses should combine")
	var palm = player.try_palm(Vector2(100, 0))
	check(is_equal_approx(palm.reach, 43.2 * 1.15) and is_equal_approx(palm.area_multiplier, 1.15), "Global area must affect Palm reach and width")
	palm.resolve()
	check(target.health.current == 50, "Palm must still apply its contact damage")
	check(is_equal_approx(player.dash_hit_radius(), 18.2), "Global area must affect dash contact area")
	var dash_target = enemy_at(Vector2(10, 30))
	player.try_dash(Vector2.RIGHT)
	player.damage_dash_enemies(Vector2(0, 30), Vector2(30, 30))
	check(is_equal_approx(dash_target.knockback_velocity.x, 975 * 1.24), "Heavy Hands must affect Dash impulse too")
	player.dash_timer = 0
	player.dash_active_this_frame = false
	for attack in get_nodes_in_group("melee_attacks"):
		attack.queue_free()
	for body in [target, dash_target]:
		body.position = Vector2(1000, 500)
	var fresh = enemy_at(Vector2(1000, 600))
	check(is_equal_approx(player.collision_damage_multiplier(large, fresh, 10), 2.34), "Hard Knocks, Wrecking Ball, Fresh Target and capped Domino must combine")
	fresh.knockback_timer = 1
	check(is_equal_approx(player.collision_damage_multiplier(large, fresh, 0), 1.54), "Fresh Target must not boost already launched targets; first Domino hit has no ramp")
	var source = enemy_at(Vector2(1000, 1000))
	var victim = enemy_at(Vector2(1020, 1000))
	source.receive_attack(Vector2.RIGHT, 400, 0, 0.3, player)
	check(source.transfer_impact(victim, Vector2(400, 0), Vector2.RIGHT), "Upgraded collision should resolve")
	check(is_equal_approx(victim.knockback_velocity.x, 340), "Carry Through should raise restitution from .55 to .70")
	check(victim.current_launch_owner() == player, "Collision chain must retain player attribution")
	check(60 - victim.health.current > 18.6, "Collision passives must increase actual collision damage")
	victim.target = player
	victim._physics_process(1.0)
	check(is_equal_approx(victim.stagger_timer, 0.3), "Stagger must start after actual knockback ends")
	var frozen: Vector2 = victim.position
	victim._physics_process(0.1)
	check(victim.position == frozen, "Stagger must prevent chasing")
	player.health.current = 39
	player.take_damage(20)
	check(player.health.current == 24, "Last Stand must reduce damage at 30 percent HP")
	player.apply_knockback(Vector2.LEFT)
	check(is_equal_approx(player.knockback_timer, 0.18 * 0.7), "Quick Recovery must shorten actual player knockback")
	var projectile = enemy_at(Vector2(800, 800))
	var doomed = enemy_at(Vector2(820, 800))
	doomed.take_damage(59)
	projectile.receive_attack(Vector2.RIGHT, 400, 0, 0.3, player)
	projectile.transfer_impact(doomed, Vector2(400, 0), Vector2.RIGHT)
	check(player.health.current == 27, "Second Wind must heal three HP for an attributed collision kill")
	doomed.take_damage(100, player)
	check(player.health.current == 27, "Duplicate lethal hits must not heal twice")
	var direct = enemy_at(Vector2(800, -800))
	direct.take_damage(1000)
	check(player.health.current == 27, "Non-collision kills must not trigger Second Wind")
	var crowd: Array = []
	for at in [Vector2(20, 0), Vector2(-20, 0), Vector2(0, 20)]:
		crowd.append(enemy_at(at))
	check(is_equal_approx(player.force_multiplier(), 1.44), "Crowd Breaker must activate with three nearby living enemies")
	crowd[0].queue_free()
	check(is_equal_approx(player.force_multiplier(), 1.24), "Crowd Breaker must ignore dead/queued enemies")
	tree.respec()
	check(tree.points == 40 and player.health.max_health == 100 and player.health.current == 27, "Respec must refund points, remove Vitality and never heal")
	check(player.force_multiplier() == 1 and player.attack_area_multiplier() == 1, "Respec must remove passive bonuses without changing base stats")
	check(player.equipped_passives == [&"attract_exp", &"", &""], "Tree progression must not consume passive equipment slots")
	await create_timer(0.4).timeout
	scene.free()
	await create_timer(0.2).timeout
	var restarted = load("res://scenes/main.tscn").instantiate()
	root.add_child(restarted)
	var new_player = restarted.get_node("Player")
	check(new_player.level == 1 and new_player.passive_tree.points == 0 and new_player.passive_tree.ranks.is_empty(), "A fresh run must reset all progression")
	check(new_player.health.max_health == 100, "A fresh run must restore base stats")
	restarted.free()
	await process_frame
	print("PASS: point awards/overflow, 16 nodes, tiers/ranks, all core passive effects, collision attribution, free respec without healing, separate equipment")
	quit()
