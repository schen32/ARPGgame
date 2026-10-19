extends Node2D
## Player-centered aura marks the same enemy-center contact radius used by dash hits.
const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
var player
var ring: Node2D
var radius: float = 17.0

func _ready() -> void:
	z_index = 3
	ring = SHAPE.new()
	ring.fill_color = Color(0.5, 0.8, 1.0, 0.035)
	ring.border_color = Color(0.66, 0.91, 1.0, 0.9)
	ring.border_width = 1.0
	add_child(ring)
	update_display()

func _process(_delta: float) -> void:
	update_display()

func update_display() -> void:
	visible = is_instance_valid(player) and player.is_alive() and player.is_dashing()
	if not visible or not is_instance_valid(ring):
		return
	radius = player.dash_hit_radius()
	ring.shape_size = Vector2.ONE * radius * 2.0
