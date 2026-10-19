extends Node2D

const PALETTE = preload("res://prototypes/tower_defense/scripts/prototype_palette.gd")
const PICKUP_BURST = preload("res://prototypes/tower_defense/scripts/pickup_burst.gd")
const AUDIO = preload("res://prototypes/tower_defense/scripts/impact_audio.gd")

@export var experience_value: int = 25
@export var attract_speed: float = 240.0
@export var pickup_distance: float = 4.0

var target: Node2D
var attracted: bool = false
var collected: bool = false

func _ready() -> void:
	$Geometry.fill_color = PALETTE.EXPERIENCE
	$Geometry.border_color = PALETTE.EXPERIENCE.lightened(0.25)

func _physics_process(delta: float) -> void:
	if collected or not is_instance_valid(target) or not target.is_alive():
		return
	var radius: float = target.get_exp_attract_radius()
	if radius <= 0.0:
		# Unequipping the passive also stops already-homing orbs immediately.
		attracted = false
		if target.overlaps_exp_orb(global_position):
			collect()
		return
	var distance := global_position.distance_to(target.global_position)
	if not attracted:
		attracted = distance <= radius
	if not attracted:
		return
	# Once attracted, keep following so a moving player cannot strand the orb.
	global_position = global_position.move_toward(target.global_position, attract_speed * delta)
	if global_position.distance_to(target.global_position) <= pickup_distance:
		collect()

func collect() -> void:
	if collected:
		return
	collected = true
	target.add_experience(experience_value)
	AUDIO.exp_pickup(self, target.global_position)
	var burst := PICKUP_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = target.global_position
	queue_free()
