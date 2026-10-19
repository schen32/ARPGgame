extends Node2D
## Short radial sparks identify enemy-to-enemy impacts.
const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
var age: float = 0.0
func _ready() -> void:
	add_to_group("impact_bursts")
	for i in range(10):
		var spark = SHAPE.new()
		spark.shape_size = Vector2(2, 2)
		spark.border_width = 0.0
		spark.fill_color = Color("ffcf83")
		add_child(spark)
func _process(delta: float) -> void:
	age += delta
	if age >= 0.25:
		queue_free()
		return
	for i in range(get_child_count()):
		get_child(i).position = Vector2.RIGHT.rotated(TAU * i / 10.0) * age * 90.0
		get_child(i).modulate.a = 1.0 - age / 0.25
