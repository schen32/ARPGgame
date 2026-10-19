extends Node2D

const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
const PALETTE = preload("res://prototypes/tower_defense/scripts/prototype_palette.gd")
const LIFETIME: float = 0.3

var age: float = 0.0
var directions: Array[Vector2] = []

func _ready() -> void:
	add_to_group("pickup_bursts")
	z_index = 2
	for i in range(8):
		var particle = SHAPE.new()
		particle.shape_size = Vector2.ONE * randf_range(1.2, 2.2)
		particle.border_width = 0.0
		particle.fill_color = PALETTE.EXPERIENCE
		add_child(particle)
		directions.append(Vector2.from_angle(TAU * (float(i) + randf()) / 8.0) * randf_range(25.0, 45.0))

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	var progress := age / LIFETIME
	for i in range(get_child_count()):
		var particle := get_child(i) as Node2D
		particle.position = directions[i] * age + Vector2(0, -8.0 * age)
		particle.scale = Vector2.ONE * (1.0 - progress * 0.7)
		particle.modulate.a = 1.0 - progress
