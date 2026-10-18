extends Node2D

const ENEMY = preload("res://scenes/enemy.tscn")
const BIG_ENEMY = preload("res://scenes/big_enemy.tscn")

@export var spawn_radius: float = 260.0
@export_range(1, 100) var big_enemy_interval: int = 4
var spawn_count: int = 0

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
	var spawn_big := (spawn_count + 1) % big_enemy_interval == 0
	var body_radius := 18.0 if spawn_big else 9.0
	# Find room for the new circle, rather than spawning it inside another one.
	for attempt in range(48):
		var radius := spawn_radius + floorf(float(attempt) / 16.0) * 24.0
		var spawn_point: Vector2 = player.global_position + Vector2.from_angle(randf() * TAU) * radius
		var clear := true
		for other in get_tree().get_nodes_in_group("enemies"):
			if not other.is_queued_for_deletion() and other.global_position.distance_to(spawn_point) < body_radius + other.body_radius + 2.0:
				clear = false
				break
		if clear:
			var enemy := BIG_ENEMY.instantiate() if spawn_big else ENEMY.instantiate()
			enemy.position = to_local(spawn_point)
			add_child(enemy)
			spawn_count += 1
			return
