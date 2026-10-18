extends Node2D
## Scene-owned positional voice pool; original short billiard-style samples.
signal sound_played(kind: StringName, at: Vector2, strength: float)
const CUE_SOUNDS = [preload("res://audio/impacts/cue_1.wav"), preload("res://audio/impacts/cue_2.wav"), preload("res://audio/impacts/cue_3.wav")]
const BALL_SOUNDS = [preload("res://audio/impacts/ball_1.wav"), preload("res://audio/impacts/ball_2.wav"), preload("res://audio/impacts/ball_3.wav")]
const DASH_SOUND = preload("res://audio/dash_whoosh.wav")
const EXP_SOUND = preload("res://audio/exp_pickup.wav")
const STRIKE_SOUND = preload("res://audio/strike_use.wav")
const PALM_SOUND = preload("res://audio/palm_use.wav")
const VOICE_LIMIT: int = 12
const BUS: StringName = &"ImpactSFX"
@export_range(-40.0, 0.0, 0.5) var volume_db: float = -2.0
var voices: Array[AudioStreamPlayer2D] = []
var next_voice: int = 0
var pair_contacts: Dictionary = {}
var budget_frame: int = -1
var frame_counts: Dictionary = {}
var rng := RandomNumberGenerator.new()

static func attack_hit(source: Node, at: Vector2, strength: float) -> void:
	var audio = source.get_tree().get_first_node_in_group("impact_audio")
	if is_instance_valid(audio):
		audio.play_sound(&"attack", at, strength)

static func dash_start(source: Node, at: Vector2) -> void:
	var audio = source.get_tree().get_first_node_in_group("impact_audio")
	if is_instance_valid(audio):
		audio.play_sound(&"dash", at, 0.0)

static func exp_pickup(source: Node, at: Vector2) -> void:
	var audio = source.get_tree().get_first_node_in_group("impact_audio")
	if is_instance_valid(audio):
		audio.play_sound(&"exp", at, 0.0)

static func melee_use(source: Node, at: Vector2, kind: StringName) -> void:
	var audio = source.get_tree().get_first_node_in_group("impact_audio")
	if is_instance_valid(audio):
		audio.play_sound(&"strike" if kind == &"sweep" else &"palm", at, 0.0)

static func collision(source: Node2D, other: Node2D, at: Vector2, strength: float) -> void:
	var audio = source.get_tree().get_first_node_in_group("impact_audio")
	if is_instance_valid(audio):
		audio.report_collision(source.get_instance_id(), other.get_instance_id(), at, strength)

func _ready() -> void:
	add_to_group("impact_audio")
	rng.randomize()
	if AudioServer.get_bus_index(BUS) < 0:
		var index := AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(index, BUS)
		AudioServer.set_bus_send(index, &"Master")
		AudioServer.add_bus_effect(index, AudioEffectLimiter.new())
	for i in range(VOICE_LIMIT):
		var voice := AudioStreamPlayer2D.new()
		voice.bus = BUS
		voice.max_distance = 900.0
		voice.attenuation = 1.2
		voice.panning_strength = 0.6
		add_child(voice)
		voices.append(voice)

func _exit_tree() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null

func _physics_process(_delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame % 120 == 0:
		for pair in pair_contacts.keys():
			if frame - pair_contacts[pair].frame > 120:
				pair_contacts.erase(pair)

func report_collision(first: int, second: int, at: Vector2, strength: float) -> void:
	var key := "%d:%d" % [mini(first, second), maxi(first, second)]
	var frame := Engine.get_physics_frames()
	var previous: Dictionary = pair_contacts.get(key, {})
	var new_contact: bool = previous.is_empty() or frame > previous.frame + 2
	var sounded: bool = false if new_contact else previous.sounded
	pair_contacts[key] = {"frame": frame, "sounded": sounded}
	# Slow, resting contact is silent. Both colliders can report the same hit.
	if not sounded and strength >= 20.0:
		play_sound(&"collision", at, strength)
		pair_contacts[key].sounded = true

func play_sound(kind: StringName, at: Vector2, strength: float) -> void:
	if kind not in [&"attack", &"collision", &"dash", &"exp", &"strike", &"palm"] or voices.is_empty():
		return
	var frame := Engine.get_physics_frames()
	if frame != budget_frame:
		budget_frame = frame
		frame_counts.clear()
	# Coalesce large simultaneous crowds; the limiter protects overlapping chains.
	var count: int = frame_counts.get(kind, 0)
	if count >= {&"attack": 3, &"collision": 4, &"dash": 1, &"exp": 2, &"strike": 1, &"palm": 1}[kind]:
		return
	frame_counts[kind] = count + 1
	var voice: AudioStreamPlayer2D = null
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		voice = voices[next_voice]
		next_voice = (next_voice + 1) % VOICE_LIMIT
	voice.stop()
	var sounds: Array = CUE_SOUNDS if kind == &"attack" else BALL_SOUNDS
	voice.stream = DASH_SOUND if kind == &"dash" else sounds[rng.randi_range(0, sounds.size() - 1)]
	if kind == &"exp":
		voice.stream = EXP_SOUND
	if kind in [&"strike", &"palm"]:
		voice.stream = STRIKE_SOUND if kind == &"strike" else PALM_SOUND
	var energy := clampf(strength / 1000.0, 0.0, 1.0)
	voice.pitch_scale = rng.randf_range(0.96, 1.04) * (lerpf(1.08, 0.96, energy) if kind == &"attack" else 1.0)
	voice.volume_db = volume_db + (lerpf(-13.0, -8.0, energy) if kind == &"attack" else lerpf(-24.0, -8.0, sqrt(energy)))
	if kind == &"dash":
		voice.pitch_scale = rng.randf_range(0.98, 1.02)
		voice.volume_db = volume_db - 10.0
	if kind == &"exp":
		voice.pitch_scale = rng.randf_range(0.97, 1.05)
		voice.volume_db = volume_db - 16.0
	if kind in [&"strike", &"palm"]:
		voice.pitch_scale = rng.randf_range(0.96, 1.04)
		voice.volume_db = volume_db - 12.0
	voice.global_position = at
	voice.play()
	sound_played.emit(kind, at, strength)
