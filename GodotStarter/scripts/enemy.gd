extends CharacterBody2D

const DEATH_BURST = preload("res://scripts/death_burst.gd")
const EXPERIENCE_ORB = preload("res://scenes/experience_orb.tscn")

@export var move_speed: float = 40.0
@export var stop_distance: float = 20.0
@export var target_path: NodePath
@export var knockback_speed: float = 300.0
@export var knockback_duration: float = 0.2
@export var contact_damage: float = 10.0
@export var contact_self_damage: float = 1.0
@export var attack_cooldown: float = 0.8
@export var experience_reward: int = 25

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var attack_timer: float = 0.0
var touching_target: bool = false
var knockback_total_duration: float = 0.2
var knockback_deceleration: float = 1500.0

@onready var target: Node2D = get_node_or_null(target_path) as Node2D
@onready var health = $Health

func _ready() -> void:
	health.changed.connect(_on_health_changed)
	health.depleted.connect(_on_depleted)
	_on_health_changed(health.current, health.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	$Geometry.fill_ratio = current / maximum

func take_damage(amount: float) -> void:
	health.take_damage(amount)

func _on_depleted() -> void:
	var orb := EXPERIENCE_ORB.instantiate()
	orb.position = position
	orb.target = target
	orb.experience_value = experience_reward
	get_parent().add_child(orb)
	var burst := DEATH_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = global_position
	queue_free()

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	attack_timer = maxf(0.0, attack_timer - delta)
	if health.current <= 0.0:
		return
	var in_contact := false
	if is_instance_valid(target) and (not target.has_method("is_alive") or target.is_alive()):
		var offset := target.global_position - global_position
		var distance := offset.length()
		var target_dashing: bool = target.has_method("is_dashing") and target.is_dashing()
		in_contact = not target_dashing and knockback_timer <= 0.0 and distance <= stop_distance + 0.5
		# New contacts immediately push and damage; cooldown only limits sustained contact.
		# Latch contact so sustained overlap does not restart knockback every frame.
		if in_contact and not touching_target and target.has_method("apply_knockback"):
			var push_direction := offset.normalized() if distance > 0.001 else Vector2.RIGHT
			target.apply_knockback(push_direction)
		if in_contact and (not touching_target or attack_timer <= 0.0) and target.has_method("take_damage"):
			target.take_damage(contact_damage)
			attack_timer = attack_cooldown
		if in_contact and not touching_target:
			take_damage(contact_self_damage)
			if health.current <= 0.0:
				return
		if distance > stop_distance:
			# Clamp the final chase step so the enemy stops beside the player.
			velocity = offset / distance * minf(move_speed, (distance - stop_distance) / delta)
	touching_target = in_contact
	if knockback_timer > 0.0:
		knockback_timer = maxf(0.0, knockback_timer - delta)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		if knockback_timer <= 0.0:
			knockback_velocity = Vector2.ZERO
		var push_weight := clampf(knockback_timer / maxf(knockback_total_duration, 0.001), 0.0, 1.0)
		velocity = velocity * (1.0 - push_weight) + knockback_velocity
	move_and_slide()

func apply_knockback(direction: Vector2, strength: float = -1.0, duration: float = -1.0) -> void:
	var speed := knockback_speed if strength < 0.0 else strength
	knockback_total_duration = knockback_duration if duration < 0.0 else duration
	knockback_velocity = direction.normalized() * speed
	knockback_timer = knockback_total_duration
	knockback_deceleration = speed / maxf(knockback_total_duration, 0.001)

