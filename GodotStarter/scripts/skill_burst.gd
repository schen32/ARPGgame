extends Node2D
## Brief blue fragments emitted behind the player during dash.

const SHAPE = preload("res://scripts/prototype_shape.gd")

var kind: StringName = &"dash"
var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var lifetime: float = 0.24
var velocities: Array[Vector2] = []
var origins: Array[Vector2] = []

func _ready() -> void:
	add_to_group("skill_bursts")
	add_to_group("dash_bursts")
	z_index = 2
	lifetime = 0.38
	var count: int = 12
	var flow := -direction
	for i in range(count):
		var particle = SHAPE.new()
		particle.shape = 1
		particle.shape_size = Vector2.ONE * randf_range(1.2, 2.6)
		particle.border_width = 0.0
		particle.fill_color = Color("80c8ef").lerp(Color("d3ecff"), randf() * 0.6)
		var origin := flow * randf_range(0.0, 9.0)
		particle.position = origin
		add_child(particle)
		origins.append(origin)
		var spread_angle := lerpf(-1.15, 1.15, (float(i) + randf()) / count)
		velocities.append(flow.rotated(spread_angle) * randf_range(70.0, 160.0))

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	var progress := age / lifetime
	for i in range(get_child_count()):
		var particle := get_child(i) as Node2D
		particle.position = origins[i] + velocities[i] * (1.0 - exp(-3.0 * age)) / 3.0
		particle.scale = Vector2.ONE * (1.0 - progress * 0.7)
		particle.modulate.a = 1.0 - progress
