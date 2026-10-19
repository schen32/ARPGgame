extends Node2D
## Small geometric particles using the same crisp shape shader as the actors.

const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
const PARTICLE_COUNT: int = 18
const LIFETIME: float = 0.55

var age: float = 0.0
var velocities: Array[Vector2] = []
var spins: Array[float] = []

func _ready() -> void:
	add_to_group("death_bursts")
	z_index = 1
	for i in range(PARTICLE_COUNT):
		var fragment := SHAPE.new()
		fragment.shape = 1
		fragment.shape_size = Vector2.ONE * randf_range(2.0, 4.0)
		fragment.border_width = 0.0
		fragment.fill_color = Color("de6b67").lerp(Color("ffd0bd"), randf() * 0.5)
		add_child(fragment)
		# Spread particles all around the circle with slight random variation.
		var angle := TAU * (float(i) + randf()) / PARTICLE_COUNT
		velocities.append(Vector2.from_angle(angle) * randf_range(75.0, 165.0))
		spins.append(randf_range(-8.0, 8.0))

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	var progress := age / LIFETIME
	for i in range(get_child_count()):
		var fragment := get_child(i) as Node2D
		fragment.position = velocities[i] * (1.0 - exp(-4.0 * age)) / 4.0 + Vector2(0, 25.0 * age * age)
		fragment.rotation = spins[i] * age
		fragment.scale = Vector2.ONE * (1.0 - progress * 0.6)
		fragment.modulate.a = 1.0 - progress
