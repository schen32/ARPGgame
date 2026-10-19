extends Node2D
## Three short-lived square afterimages along the actual traveled path.
const SHAPE = preload("res://prototypes/tower_defense/scripts/prototype_shape.gd")
const LIFETIME: float = 0.10
var player
var ghosts: Array[Dictionary] = []
var last_position: Vector2
var sample_timer: float = 0.0

func _ready() -> void:
	add_to_group("dash_trails")
	z_index = -1
	last_position = player.global_position
	add_ghost(last_position)

func add_ghost(at: Vector2) -> void:
	if ghosts.size() >= 3:
		ghosts.pop_front().shape.queue_free()
	var ghost = SHAPE.new()
	ghost.shape = 1
	ghost.shape_size = Vector2(16, 16)
	ghost.fill_color = Color("80c8ef")
	ghost.border_width = 0
	add_child(ghost)
	ghost.global_position = at
	ghost.modulate.a = 0.22
	ghosts.append({"shape": ghost, "remaining": LIFETIME})

func _physics_process(delta: float) -> void:
	if is_instance_valid(player) and player.is_alive() and player.is_dashing():
		sample_timer += delta
		if sample_timer >= 0.025 and player.global_position.distance_to(last_position) >= 4.0:
			sample_timer = 0.0
			last_position = player.global_position
			add_ghost(last_position)

func _process(delta: float) -> void:
	for i in range(ghosts.size() - 1, -1, -1):
		ghosts[i].remaining -= delta
		if ghosts[i].remaining <= 0:
			ghosts[i].shape.queue_free()
			ghosts.remove_at(i)
		else:
			ghosts[i].shape.modulate.a = 0.22 * ghosts[i].remaining / LIFETIME
	if ghosts.is_empty() and (not is_instance_valid(player) or not player.is_dashing()):
		queue_free()
