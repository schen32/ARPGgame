extends Node2D

const ENEMY = preload("res://scenes/enemy.tscn")

@export var spawn_radius: float = 260.0

@onready var player = $Player

func _ready() -> void:
	player.health.depleted.connect(_on_player_defeated)

func _on_player_defeated() -> void:
	# Reload after the current hit/physics callback has finished safely.
	get_tree().reload_current_scene.call_deferred()

func _on_enemy_spawn_timer_timeout() -> void:
	if not player.is_alive():
		$EnemySpawnTimer.stop()
		return
	# Find room for the new circle, rather than spawning it inside another one.
	for attempt in range(48):
		var radius := spawn_radius + floorf(float(attempt) / 16.0) * 24.0
		var spawn_point: Vector2 = player.global_position + Vector2.from_angle(randf() * TAU) * radius
		var clear := true
		for other in get_tree().get_nodes_in_group("enemies"):
			if not other.is_queued_for_deletion() and other.global_position.distance_to(spawn_point) < 20.0:
				clear = false
				break
		if clear:
			var enemy := ENEMY.instantiate()
			enemy.position = to_local(spawn_point)
			add_child(enemy)
			return
