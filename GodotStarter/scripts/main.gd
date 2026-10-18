extends Node2D

const ROOM_SIZE := Vector2(4000, 4000)
const GRID_STEP := 64.0
const GOBLIN_SCENE := preload("res://scenes/goblin.tscn")

@export var goblin_spawn_radius: float = 240.0

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	player.defeated.connect(_on_player_defeated)

func _on_player_defeated() -> void:
	for enemy in get_tree().get_nodes_in_group("goblins"):
		enemy.queue_free()

func _on_goblin_spawn_timer_timeout() -> void:
	var goblin := GOBLIN_SCENE.instantiate()
	goblin.target = player
	goblin.position = player.position + Vector2.from_angle(randf() * TAU) * goblin_spawn_radius
	add_child(goblin)
