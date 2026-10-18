extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("EnemySpawnTimer").stop()
	var player = scene.get_node("Player")
	var enemy = scene.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.position = Vector2(20, 0)
	var was_in_contact := false
	var contacts := 0
	var contacts_during_cooldown := 0
	# No movement input: let the same enemy repeatedly approach and hit the player.
	for frame in range(180):
		await physics_frame
		player._physics_process(1.0 / 60.0)
		var in_contact: bool = enemy.global_position.distance_to(player.global_position) <= enemy.stop_distance + 0.5
		var entered_contact: bool = in_contact and not was_in_contact
		if entered_contact:
			contacts += 1
			if enemy.attack_timer > 1.0 / 60.0:
				contacts_during_cooldown += 1
		var hp_before: float = player.health.current
		var enemy_hp_before: float = enemy.health.current
		enemy._physics_process(1.0 / 60.0)
		var expected_enemy_hp: float = enemy_hp_before - (1.0 if entered_contact else 0.0)
		if enemy.health.current != expected_enemy_hp:
			push_error("Enemy should lose exactly 1 HP on each new contact")
			quit(1)
			return
		if entered_contact and player.health.current != maxf(0.0, hp_before - enemy.contact_damage):
			push_error("Contact %d did not deal damage immediately" % contacts)
			quit(1)
			return
		if entered_contact and player.knockback_timer <= 0.0:
			push_error("Contact %d did not knock the stationary player back immediately (damage cooldown %.3f)" % [contacts, enemy.attack_timer])
			quit(1)
			return
		was_in_contact = in_contact
	if contacts < 3 or contacts_during_cooldown < 1:
		push_error("Test did not exercise repeated contact during damage cooldown")
		quit(1)
		return
	print("PASS: %d immediate contact damage and knockbacks, %d before the previous cooldown expired" % [contacts, contacts_during_cooldown])
	quit()
