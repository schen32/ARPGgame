extends CharacterBody2D

@export var speed: float = 300.0
@export var max_lifetime: float = 12.0
@export var damage: float = 25.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	# Sweep the entire movement step so fast shots cannot skip small enemies.
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var enemy := collision.get_collider()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction)
		queue_free()
