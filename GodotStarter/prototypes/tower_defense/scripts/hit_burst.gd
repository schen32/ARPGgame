extends Node2D
## Small blue-white flecks at a successful attack contact, including lethal hits.
const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
const LIFETIME: float = 0.22
var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var velocities: Array[Vector2] = []

static func spawn(source: Node2D, at: Vector2, aim: Vector2, contact_radius: float = 7.0) -> void:
	var burst = load("res://prototypes/tower_defense/scripts/hit_burst.gd").new()
	burst.direction = aim.normalized()
	source.get_parent().add_child(burst)
	burst.global_position = at - aim.normalized() * contact_radius

func _ready() -> void:
	add_to_group("hit_bursts")
	z_index = 5
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(8):
		var spark = SHAPE.new()
		spark.shape_size = Vector2.ONE * rng.randf_range(0.9, 1.8)
		spark.border_width = 0.0
		spark.fill_color = Color("dff6ff") if i % 3 == 0 else Color("80c8ef")
		add_child(spark)
		var angle := TAU * (i + rng.randf_range(-0.2, 0.2)) / 8.0
		velocities.append(Vector2.RIGHT.rotated(angle) * rng.randf_range(30.0, 65.0) + direction * 35.0)

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	var progress := age / LIFETIME
	for i in range(get_child_count()):
		var spark := get_child(i) as Node2D
		spark.position = velocities[i] * (1.0 - exp(-7.0 * age)) / 7.0
		spark.modulate.a = 1.0 - progress
		spark.scale = Vector2.ONE * (1.0 - progress * 0.5)
