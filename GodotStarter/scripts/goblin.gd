extends CharacterBody2D

@export var move_speed: float = 65.0
@export var stop_distance: float = 12.0

var target: Node2D
@export var max_health: float = 60.0
var health: float = 60.0
var attack_cooldown: float = 0.0

func _ready() -> void:
	health = max_health

func take_damage(amount: float) -> void:
	health = clampf(health - maxf(amount, 0.0), 0.0, max_health)
	queue_redraw()
	if health <= 0.0:
		queue_free()

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	velocity = Vector2.ZERO
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance <= 18.0 and attack_cooldown <= 0.0 and target.has_method("take_damage"):
		target.take_damage(8.0)
		attack_cooldown = 0.8
	if distance <= stop_distance:
		return
	var direction := offset / distance
	if absf(direction.x) > absf(direction.y):
		sprite.frame = 1 if direction.x > 0.0 else 3
	else:
		sprite.frame = 0 if direction.y > 0.0 else 2
	# Clamp the final step so the goblin stops at the player's feet.
	velocity = direction * minf(move_speed, (distance - stop_distance) / delta)
	move_and_slide()

func _draw() -> void:
	# World-space bars follow each enemy and use the HUD's silver/navy palette.
	draw_rect(Rect2(-17, -40, 34, 6), Color("101827"))
	draw_rect(Rect2(-16, -39, 32 * health / max_health, 4), Color("d62d50"))
	draw_rect(Rect2(-17, -40, 34, 6), Color("afc9df"), false, 1.0)
	draw_line(Vector2(-18, -38), Vector2(-20, -37), Color("71d5ff"))
	draw_line(Vector2(18, -38), Vector2(20, -37), Color("71d5ff"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0.05, 0.08, 0.07, 0.35))
