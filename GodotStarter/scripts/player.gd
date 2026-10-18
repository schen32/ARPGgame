extends CharacterBody2D

@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var max_mana: float = 100.0

signal defeated

var health: float = 100.0
var mana: float = 100.0
var attack_cooldown: float = 0.0
var spell_flash: float = 0.0

func _ready() -> void:
	health = max_health
	mana = max_mana

func take_damage(amount: float) -> void:
	health = clampf(health - maxf(amount, 0.0), 0.0, max_health)
	if health <= 0.0:
		defeated.emit()
		global_position = Vector2.ZERO
		health = max_health
		mana = max_mana

func cast_spell() -> void:
	if attack_cooldown > 0.0 or mana < 15.0:
		return
	mana -= 15.0
	attack_cooldown = 0.4
	spell_flash = 0.18
	for enemy in get_tree().get_nodes_in_group("goblins"):
		if global_position.distance_to(enemy.global_position) <= 100.0:
			enemy.take_damage(20.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			cast_spell()
		elif event.physical_keycode == KEY_H and mana >= 25.0 and health < max_health:
			mana -= 25.0
			health = minf(max_health, health + 35.0)

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	mana = minf(max_mana, mana + delta * 6.0)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	spell_flash = maxf(0.0, spell_flash - delta)
	queue_redraw()
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.is_zero_approx():
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if not input_direction.is_zero_approx():
		# Four facing poses; diagonal movement uses the dominant axis.
		if absf(input_direction.x) > absf(input_direction.y):
			sprite.frame = 1 if input_direction.x > 0.0 else 3
		else:
			sprite.frame = 0 if input_direction.y > 0.0 else 2
	velocity = input_direction * move_speed
	move_and_slide()

func _draw() -> void:
	if spell_flash > 0.0:
		draw_circle(Vector2(0, -10), 100.0 * (1.0 - spell_flash / 0.2), Color(0.4, 0.85, 1.0, spell_flash * 3.0), false, 2.0)
	# The body origin and collision stay at the character's feet.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0.05, 0.08, 0.07, 0.35))
