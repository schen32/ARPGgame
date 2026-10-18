extends CharacterBody2D

const SPLIT_SPAWN = preload("res://scripts/split_spawn.gd")
const IMPACT_AUDIO = preload("res://scripts/impact_audio.gd")
const DEATH_BURST = preload("res://scripts/death_burst.gd")
const EXPERIENCE_ORB = preload("res://scenes/experience_orb.tscn")

@export var body_radius: float = 9.0
@export var mass_multiplier: float = 1.0
@export var splits_on_death: bool = false
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
const MIN_IMPACT_SPEED: float = 30.0
const IMPACT_CONTACT_TIME: float = 0.05
const IMPACT_DAMAGE_PER_FORCE: float = 0.003
const IMPACT_RESTITUTION: float = 0.55
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
	# Each size variant needs its own collision resource, not a shared scene shape.
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = body_radius
	$Geometry.shape_size = Vector2.ONE * body_radius * 2.0
	health.changed.connect(_on_health_changed)
	health.depleted.connect(_on_depleted)
	_on_health_changed(health.current, health.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	$Geometry.fill_ratio = current / maximum

# Derived from base values every time; damage never permanently rewrites tuning.
func health_ratio() -> float:
	return clampf(health.current / health.max_health, 0.0, 1.0)

func current_mass() -> float:
	return mass_multiplier * lerpf(0.45, 1.0, health_ratio())

func current_move_speed() -> float:
	return move_speed * lerpf(1.6, 1.0, health_ratio())

func current_contact_damage() -> float:
	return contact_damage * lerpf(0.4, 1.0, health_ratio())

func take_damage(amount: float) -> void:
	health.take_damage(amount)

func _on_depleted() -> void:
	if splits_on_death:
		# Defer new physics bodies until the lethal hit's physics callback is over.
		SPLIT_SPAWN.spawn_children.call_deferred(get_parent(), global_position, target)
	var orb := EXPERIENCE_ORB.instantiate()
	orb.position = position
	orb.target = target
	orb.experience_value = experience_reward
	get_parent().add_child(orb)
	var burst := DEATH_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.scale = Vector2.ONE * body_radius / 9.0
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
		# Chase steering must not add energy to a launched body's collisions.
		if knockback_timer > 0.0:
			velocity = knockback_velocity
	var launch_velocity := knockback_velocity
	var incoming_velocity := velocity
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var other = collision.get_collider()
		if is_instance_valid(other) and other.is_in_group("enemies"):
			var closing_speed := maxf(0.0, (incoming_velocity - other.velocity).dot(-collision.get_normal()))
			IMPACT_AUDIO.collision(self, other, (global_position + other.global_position) * 0.5, closing_speed)
			if transfer_impact(other, launch_velocity, -collision.get_normal()):
				launch_velocity = knockback_velocity
				if is_queued_for_deletion():
					break

func apply_knockback(direction: Vector2, strength: float = -1.0, duration: float = -1.0) -> void:
	if health.current <= 0.0 or is_queued_for_deletion():
		return
	impact_chain = {get_instance_id(): true}
	# Strength is an impulse (force integrated over the hit), so delta-v = impulse / mass.
	var speed := (knockback_speed if strength < 0.0 else strength) / current_mass()
	var existing := knockback_velocity if knockback_timer > 0.0 else Vector2.ZERO
	set_launch_velocity(existing + direction.normalized() * speed, knockback_duration if duration < 0.0 else duration)

func set_launch_velocity(launch: Vector2, duration: float) -> void:
	knockback_total_duration = maxf(duration, 0.001)
	knockback_velocity = launch
	knockback_timer = knockback_total_duration
	knockback_deceleration = launch.length() / knockback_total_duration

func receive_attack(direction: Vector2, impulse: float, damage: float, duration: float) -> void:
	# Snapshot mass at contact, before the same hit changes the HP-based mass.
	apply_knockback(direction, impulse, duration)
	take_damage(damage)

func transfer_impact(other, launch_velocity: Vector2, normal: Vector2) -> bool:
	var closing_speed := maxf(0.0, (launch_velocity - other.knockback_velocity).dot(normal))
	if launch_velocity.dot(normal) < MIN_IMPACT_SPEED or closing_speed < MIN_IMPACT_SPEED or other.is_queued_for_deletion() or other.health.current <= 0.0:
		return false
	if impact_chain.is_empty():
		impact_chain[get_instance_id()] = true
	if impact_chain.has(other.get_instance_id()) or impact_chain.size() >= MAX_CHAIN_TARGETS:
		return false
	IMPACT_AUDIO.collision(self, other, (global_position + other.global_position) * 0.5, closing_speed)
	impact_chain[other.get_instance_id()] = true
	# Resolve a normal impulse using both masses and relative velocity. Tangential
	# motion survives; restitution below one dissipates energy along each chain.
	var mass := current_mass()
	var other_mass: float = other.current_mass()
	var impulse := (1.0 + IMPACT_RESTITUTION) * closing_speed / (1.0 / mass + 1.0 / other_mass)
	var source_after := launch_velocity - normal * impulse / mass
	var target_after: Vector2 = other.knockback_velocity + normal * impulse / other_mass
	# Acceleration is the contact's change in velocity / contact time, rather than
	# acceleration at launch or a frame-rate-dependent per-frame measurement.
	var contact_acceleration := impulse / mass / IMPACT_CONTACT_TIME
	var impact_force := mass * contact_acceleration
	var damage := impact_force * IMPACT_DAMAGE_PER_FORCE
	other.take_damage(damage)
	take_damage(damage)
	if not other.is_queued_for_deletion():
		# Use the pre-hit solution directly; newly lost HP must not amplify this impulse.
		other.set_launch_velocity(target_after, 0.3)
		other.impact_chain = impact_chain
	knockback_velocity = source_after
	knockback_deceleration = knockback_velocity.length() / maxf(knockback_timer, 0.001)
	var burst := IMPACT_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = (global_position + other.global_position) * 0.5
	return true
