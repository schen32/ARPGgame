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

const IMPACT_BURST = preload("res://scripts/impact_burst.gd")
const MIN_IMPACT_SPEED: float = 120.0
const MAX_CHAIN_TARGETS: int = 8
var impact_chain: Dictionary = {}

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

# Derived from base values every time; damage never permanently rewrites tuning.
func health_ratio() -> float:
	return clampf(health.current / health.max_health, 0.0, 1.0)

func current_mass() -> float:
	return lerpf(0.45, 1.0, health_ratio())

func current_move_speed() -> float:
	return move_speed * lerpf(1.6, 1.0, health_ratio())

func current_contact_damage() -> float:
	return contact_damage * lerpf(0.4, 1.0, health_ratio())

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
			target.take_damage(current_contact_damage())
			attack_timer = attack_cooldown
		if in_contact and not touching_target:
			take_damage(contact_self_damage)
			if health.current <= 0.0:
				return
		if distance > stop_distance:
			# Clamp the final chase step so the enemy stops beside the player.
			velocity = offset / distance * minf(current_move_speed(), (distance - stop_distance) / delta)
	touching_target = in_contact
	if knockback_timer > 0.0:
		knockback_timer = maxf(0.0, knockback_timer - delta)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		if knockback_timer <= 0.0:
			knockback_velocity = Vector2.ZERO
		var push_weight := clampf(knockback_timer / maxf(knockback_total_duration, 0.001), 0.0, 1.0)
		velocity = velocity * (1.0 - push_weight) + knockback_velocity
	var launch_velocity := knockback_velocity
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var other = collision.get_collider()
		if is_instance_valid(other) and other.is_in_group("enemies"):
			if transfer_impact(other, launch_velocity, -collision.get_normal()):
				launch_velocity = knockback_velocity
				if is_queued_for_deletion():
					break

func apply_knockback(direction: Vector2, strength: float = -1.0, duration: float = -1.0) -> void:
	if health.current <= 0.0 or is_queued_for_deletion():
		return
	impact_chain = {get_instance_id(): true}
	var speed := (knockback_speed if strength < 0.0 else strength) / current_mass()
	knockback_total_duration = knockback_duration if duration < 0.0 else duration
	knockback_velocity = direction.normalized() * speed
	knockback_timer = knockback_total_duration
	knockback_deceleration = speed / maxf(knockback_total_duration, 0.001)

func transfer_impact(other, launch_velocity: Vector2, normal: Vector2) -> bool:
	var closing_speed := maxf(0.0, (launch_velocity - other.knockback_velocity).dot(normal))
	if launch_velocity.dot(normal) < MIN_IMPACT_SPEED or closing_speed < MIN_IMPACT_SPEED or other.is_queued_for_deletion() or other.health.current <= 0.0:
		return false
	if impact_chain.is_empty():
		impact_chain[get_instance_id()] = true
	if impact_chain.has(other.get_instance_id()) or impact_chain.size() >= MAX_CHAIN_TARGETS:
		return false
	impact_chain[other.get_instance_id()] = true
	# Transfer 60% of normal kinetic energy, retain 25%; the rest dissipates.
	# Use pre-impact mass so damage cannot create extra momentum mid-transfer.
	var mass := current_mass()
	var other_mass: float = other.current_mass()
	var transferred_speed := minf(closing_speed, maxf(0.0, launch_velocity.dot(normal))) * sqrt(0.6 * mass / other_mass)
	var damage := clampf(closing_speed * 0.04, 3.0, 24.0)
	other.take_damage(damage)
	take_damage(damage * 0.5)
	if not other.is_queued_for_deletion():
		other.apply_knockback(normal, transferred_speed * other.current_mass(), 0.3)
		other.impact_chain = impact_chain
	knockback_velocity = launch_velocity * 0.5
	knockback_deceleration = knockback_velocity.length() / maxf(knockback_timer, 0.001)
	var burst := IMPACT_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = (global_position + other.global_position) * 0.5
	return true
