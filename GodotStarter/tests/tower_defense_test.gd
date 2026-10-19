extends SceneTree

const SCENE = preload("res://prototypes/tower_defense/scenes/main.tscn")

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        push_error(message)
        quit(1)
        assert(condition, message)

func run_checks() -> void:
    change_scene_to_packed(SCENE)
    await scene_changed
    var game = current_scene
    check(game.has_node("Floor") and game.has_node("Enemy") and game.has_node("EnemySpawnTimer"), "Copy retains the ARPG world and spawner")
    check(game.has_node("HUD/Interface") and game.has_node("ImpactAudio"), "Copy retains the ARPG HUD and sound")
    check(not game.has_node("Player"), "Tower defense has no player-controlled box")
    check(game.gold == game.STARTING_GOLD and game.selected_tower == &"", "New run starts with gold and no selected tower")
    check(game.get_node("Enemy").get_script().resource_path.begins_with("res://prototypes/tower_defense/"), "Copied enemy script is independent")
    await check_arena(game)
    await check_wall_damage(game)
    await check_towers(game)
    await check_split_rewards(game)
    var restart := InputEventKey.new()
    restart.keycode = KEY_R
    restart.pressed = true
    Input.parse_input_event(restart)
    await scene_changed
    await process_frame
    check(current_scene.scene_file_path == SCENE.resource_path, "R restarts tower defense")
    check(current_scene.gold == current_scene.STARTING_GOLD and get_nodes_in_group("strike_towers").is_empty(), "Restart resets towers and currency")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_QUOTELEFT
    key.pressed = true
    Input.parse_input_event(key)
    await scene_changed
    await process_frame
    check(current_scene.scene_file_path == "res://scenes/main.tscn", "Backtick switches to original ARPG")
    check(current_scene.get_node("Player").get_script().resource_path == "res://scripts/player.gd", "Original ARPG keeps its own scripts")
    paused = true
    Input.parse_input_event(key)
    await scene_changed
    await process_frame
    check(not paused and current_scene.scene_file_path == SCENE.resource_path, "Backtick switches from a paused ARPG to the copy")
    check(not root.get_node("PrototypeSwitcher").switching, "Switcher releases transition guard")
    print("Arena, copied gameplay, and prototype switching checks passed")
    quit()

func check_arena(game) -> void:
    game.get_node("EnemySpawnTimer").stop()
    var enemy = game.get_node("Enemy")
    enemy.set_physics_process(false)
    check(game.get_node("Camera2D").get_parent() == game, "Camera is fixed to the arena")
    check(game.get_node("ArenaWalls").get_child_count() == game.LAYOUT.outline().size(), "Every winding path edge has a physical wall")
    check(not game.is_inside_arena(Vector2(0, -65)), "Separated runs of the winding path cannot be crossed")
    check(game.is_inside_arena(Vector2(0, -110), 9), "Horizontal path is navigable")
    for gap_center in [Vector2(0, -65), Vector2(0, 25)]:
        check(not game.is_inside_arena(gap_center), "Tower space stays outside the path")
        for i in range(game.LAYOUT.outline().size()):
            var boundary = game.LAYOUT.outline()
            var closest := Geometry2D.get_closest_point_to_segment(gap_center, boundary[i], boundary[(i + 1) % boundary.size()])
            check(gap_center.distance_to(closest) >= 18.0, "Gaps leave at least 36 pixels of clear tower space")
    check(is_equal_approx(enemy.position.y, game.SPAWN_Y), "Initial enemy starts at entrance")
    enemy.position = Vector2(0, -110)
    for i in range(8):
        game._on_enemy_spawn_timer_timeout()
    check(game.spawn_count > 0, "Entrance spawns enemies")
    for body in get_nodes_in_group("enemies"):
        body.set_physics_process(false)
        if body == enemy:
            continue
        check(is_equal_approx(body.position.y, game.SPAWN_Y), "All enemies spawn at top entrance")
        check(game.is_inside_arena(body.position, body.body_radius), "Spawn footprints fit inside angled arena")
    await physics_frame
    await physics_frame
    for body in get_nodes_in_group("enemies"):
        if body != enemy:
            body.queue_free()
    await process_frame
    enemy.position = Vector2(-210, -110)
    enemy._physics_process(1.0 / 60.0)
    check(enemy.position.x > -210, "Enemy follows path even with player behind it")
    enemy.position = Vector2(-210, -132)
    enemy.move_and_collide(Vector2(0, -200))
    check(enemy.position.y >= -142 + enemy.body_radius - 0.1, "Top wall contains launched enemies")
    var escaped = game.BIG_ENEMY.instantiate()
    escaped.position = Vector2(game.EXIT_X, game.EXIT_Y + 1)
    escaped.next_waypoint = game.LAYOUT.FLOW.size() - 1
    game.add_child(escaped)
    escaped.set_physics_process(false)
    var orb_count := get_nodes_in_group("experience_orbs").size()
    var enemy_count := get_nodes_in_group("enemies").size()
    var gold_before_escape: int = game.gold
    escaped._physics_process(1.0 / 60.0)
    game.enemy_reached_exit(escaped)
    check(game.escaped_count == 1, "Exit counts each enemy exactly once")
    check(game.gold == gold_before_escape, "Escaped enemies award no currency")
    await process_frame
    await process_frame
    check(not is_instance_valid(escaped), "Enemies reaching exit are removed")
    check(get_nodes_in_group("experience_orbs").size() == orb_count, "Escape grants no kill rewards")
    check(get_nodes_in_group("enemies").size() == enemy_count - 1, "Escaping splitter produces no offspring")
    # Check the full winding journey, including every hairpin.
    for body in get_nodes_in_group("enemies"):
        body.queue_free()
    await process_frame
    for offset_x in [-5.0, 5.0]:
        var runner = game.BIG_ENEMY.instantiate()
        runner.position = Vector2(game.SPAWN_X + offset_x, game.SPAWN_Y)
        game.add_child(runner)
        runner.set_physics_process(false)
        var before: int = game.escaped_count
        for tick in range(6000):
            await physics_frame
            runner._physics_process(1.0 / 60.0)
            if runner.is_queued_for_deletion():
                break
            check(game.is_inside_arena(runner.position, runner.body_radius - 0.2), "Runner remains inside angled arena")
        check(game.escaped_count == before + 1, "Large enemy can traverse arena: position %s, velocity %s" % [runner.position, runner.velocity])
        await process_frame

func check_wall_damage(game) -> void:
    game.select_tower(&"strike")
    var owner = game.place_tower(Vector2(0, -65))
    owner.set_physics_process(false)
    var gold_before: int = game.gold
    var wall = game.get_node("ArenaWalls")
    var enemy = game.ENEMY.instantiate()
    enemy.position = Vector2(0, -124)
    game.add_child(enemy)
    enemy.set_physics_process(false)
    enemy.wall_impact(wall, Vector2(0, -300), Vector2.DOWN, enemy.position)
    check(enemy.health.current == 60.0, "Ordinary wall contact without knockback causes no damage")
    enemy.set_launch_velocity(Vector2(300, -20), 1.0)
    enemy.wall_impact(wall, enemy.knockback_velocity, Vector2.DOWN, enemy.position)
    check(enemy.health.current == 60.0, "A glancing wall contact causes no heavy damage")
    enemy.apply_knockback(Vector2.UP, 240.0, 1.0)
    await physics_frame
    enemy._physics_process(1.0 / 60.0)
    check(enemy.health.current < 20.0 and enemy.health.current > 0, "A real wall slam removes most of a regular enemy's HP")
    var after_hit: float = enemy.health.current
    for i in range(12):
        await physics_frame
        enemy._physics_process(1.0 / 60.0)
    check(is_equal_approx(enemy.health.current, after_hit), "Sustained wall contact cannot repeat damage")
    enemy.receive_attack(Vector2.UP, 240.0, 0.0, 1.0, owner)
    await physics_frame
    enemy._physics_process(1.0 / 60.0)
    check(enemy.is_queued_for_deletion(), "A fresh launch can cause a second lethal slam")
    check(game.gold == gold_before + 10, "Wall kill awards gold")
    enemy._on_depleted()
    check(game.gold == gold_before + 10, "Duplicate lethal callbacks cannot duplicate rewards")
    await process_frame
    check(get_nodes_in_group("experience_orbs").is_empty(), "Currency replaces uncollectable player EXP")
    owner.queue_free()
    await process_frame
func check_towers(game) -> void:
    check(game.get_node("HUD/Interface").has_node("TowerPalette"), "Sidebar palette replaces the player HUD")
    check(game.place_tower(Vector2(0, -110)) == null, "Cannot build on enemy path")
    check(game.place_tower(Vector2(0, -82)) == null, "Cannot build overlapping a path edge")
    check(game.place_tower(Vector2(-310, 0)) == null, "Cannot build outside map")
    game.select_tower(&"")
    var gold_before: int = game.gold
    check(game.place_tower(Vector2(0, -65)) == null and game.gold == gold_before, "Building requires selecting a tower")
    var palette = game.get_node("HUD/Interface")
    var palette_click := InputEventMouseButton.new()
    palette_click.button_index = MOUSE_BUTTON_LEFT
    palette_click.position = palette.tower_button.get_global_rect().get_center()
    palette_click.pressed = true
    Input.parse_input_event(palette_click)
    await process_frame
    palette_click.pressed = false
    Input.parse_input_event(palette_click)
    await process_frame
    check(game.selected_tower == &"strike", "Palette button selects Strike")
    var tower = game.place_tower(Vector2(0, -65))
    check(game.gold == gold_before - game.TOWER_COST, "Successful placement spends tower cost")
    check(tower != null, "Square tower fits between path runs")
    tower.set_physics_process(false)
    check(game.place_tower(Vector2(10, -65)) == null, "Cannot overlap towers")
    check(game.gold == gold_before - game.TOWER_COST, "Invalid placement never spends gold")
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    click.position = game.get_global_transform_with_canvas() * Vector2(90, -65)
    Input.parse_input_event(click)
    await process_frame
    check(get_nodes_in_group("strike_towers").size() == 2, "Left-click places a tower on clear ground")
    click.pressed = false
    Input.parse_input_event(click)
    for placed in get_nodes_in_group("strike_towers"):
        if placed != tower:
            placed.queue_free()
    check(game.gold == gold_before - 2 * game.TOWER_COST, "Click placement also spends gold")
    check(game.gold < game.TOWER_COST and palette.tower_button.disabled, "Unaffordable tower is disabled in palette")
    check(game.place_tower(Vector2(160, -65)) == null, "Cannot place towers without enough gold")
    tower._physics_process(1.0)
    check(tower.strikes_fired == 0, "Empty tower does not attack")
    var enemy = game.ENEMY.instantiate()
    enemy.position = Vector2(0, -110)
    game.add_child(enemy)
    enemy.set_physics_process(false)
    await physics_frame
    tower._physics_process(1.0 / 60.0)
    check(tower.strikes_fired == 1 and enemy.health.current == 56.0, "Tower automatically strikes across the path boundary")
    check(enemy.knockback_timer > 0 and enemy.current_launch_owner() == tower, "Tower Strike retains knockback and collision credit")
    tower._physics_process(0.1)
    check(tower.strikes_fired == 1, "Tower respects Strike cooldown")
    tower._physics_process(0.4)
    check(tower.strikes_fired == 2 and enemy.health.current == 52.0, "Tower attacks repeatedly while target stays near")
    enemy.position = Vector2(180, -20)
    tower._physics_process(1.0)
    check(tower.strikes_fired == 2, "Tower ignores distant enemies")
    tower.set_physics_process(true)
    tower.cooldown = 0.3
    paused = true
    await physics_frame
    await physics_frame
    check(is_equal_approx(tower.cooldown, 0.3), "Paused menus also pause towers")
    paused = false
    await process_frame
    var cancel := InputEventMouseButton.new()
    cancel.button_index = MOUSE_BUTTON_RIGHT
    cancel.position = game.get_global_transform_with_canvas() * Vector2(90, -65)
    cancel.pressed = true
    Input.parse_input_event(cancel)
    await process_frame
    check(game.selected_tower == &"", "Right-click cancels tower selection")
    cancel.pressed = false
    Input.parse_input_event(cancel)
    tower.queue_free()
    enemy.queue_free()
    await process_frame

func check_split_rewards(game) -> void:
    var gold_before: int = game.gold
    var big = game.BIG_ENEMY.instantiate()
    big.position = Vector2(0, -20)
    big.next_waypoint = 5
    game.add_child(big)
    big.set_physics_process(false)
    big.take_damage(1000.0)
    check(game.gold == gold_before + 20, "Large enemies award 20 gold")
    await process_frame
    await process_frame
    var children := get_nodes_in_group("enemies")
    check(children.size() == 4, "Large enemies still split without a player target")
    for child in children:
        check(child.next_waypoint == 5 and game.is_inside_arena(child.position, child.body_radius), "Split children retain path progress")
        child.take_damage(1000.0)
    check(game.gold == gold_before + 40, "Small split enemies award 5 gold each")
    check(not game.get_node("HUD/Interface").tower_button.disabled, "Kill rewards restore tower affordability")
    check(game.get_node("HUD/Interface").gold_label.text == "Gold  %d" % game.gold, "Currency label follows spending and rewards")
    await process_frame
