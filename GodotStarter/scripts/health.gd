extends Node
## Shared health pool for player and enemy prototypes.

signal changed(current: float, maximum: float)
signal depleted

@export_range(1.0, 10000.0) var max_health: float = 100.0
var current: float = 100.0

func _ready() -> void:
	current = max_health
	changed.emit(current, max_health)

func take_damage(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = maxf(0.0, current - amount)
	changed.emit(current, max_health)
	if current <= 0.0:
		depleted.emit()

func ratio() -> float:
	return clampf(current / max_health, 0.0, 1.0)

func heal(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = minf(max_health, current + amount)
	changed.emit(current, max_health)
