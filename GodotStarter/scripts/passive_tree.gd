extends RefCounted
## Run-local progression. No active abilities or equipment slots are granted here.
signal changed
const BRANCHES = ["Force", "Chains", "Control", "Survival"]
const NODES = [
	{"id": &"heavy_hands", "name": "Heavy Hands", "branch": 0, "tier": 0, "ranks": 3, "text": "+8% attack force per rank."},
	{"id": &"follow_through", "name": "Follow Through", "branch": 0, "tier": 1, "ranks": 3, "text": "+10% force per rank against already launched enemies."},
	{"id": &"giant_killer", "name": "Giant Killer", "branch": 0, "tier": 2, "ranks": 3, "text": "+12% force per rank against large enemies."},
	{"id": &"wrecking_ball", "name": "Wrecking Ball", "branch": 0, "tier": 3, "ranks": 1, "text": "Large enemies you launch deal +30% collision damage."},
	{"id": &"hard_knocks", "name": "Hard Knocks", "branch": 1, "tier": 0, "ranks": 3, "text": "+8% collision damage per rank."},
	{"id": &"carry_through", "name": "Carry Through", "branch": 1, "tier": 1, "ranks": 3, "text": "Collisions retain more motion: +0.05 restitution per rank."},
	{"id": &"fresh_target", "name": "Fresh Target", "branch": 1, "tier": 2, "ranks": 3, "text": "+10% collision damage per rank against enemies not in knockback."},
	{"id": &"domino", "name": "Domino Effect", "branch": 1, "tier": 3, "ranks": 1, "text": "+10% damage for each previous collision in a chain, up to +50%."},
	{"id": &"extended_reach", "name": "Extended Reach", "branch": 2, "tier": 0, "ranks": 3, "text": "+5% attack reach and area per rank, including dash contact area."},
	{"id": &"driving_force", "name": "Driving Force", "branch": 2, "tier": 1, "ranks": 3, "text": "+8% enemy knockback duration per rank; launches travel farther."},
	{"id": &"stagger", "name": "Stagger", "branch": 2, "tier": 2, "ranks": 3, "text": "Enemies cannot chase or contact attack for 0.1s per rank after knockback."},
	{"id": &"crowd_breaker", "name": "Crowd Breaker", "branch": 2, "tier": 3, "ranks": 1, "text": "+20% attack force with 3 or more living enemies within 3m."},
	{"id": &"vitality", "name": "Vitality", "branch": 3, "tier": 0, "ranks": 3, "text": "+10% maximum HP per rank. Does not heal current HP."},
	{"id": &"quick_recovery", "name": "Quick Recovery", "branch": 3, "tier": 1, "ranks": 3, "text": "Player knockback ends 10% sooner per rank."},
	{"id": &"second_wind", "name": "Second Wind", "branch": 3, "tier": 2, "ranks": 3, "text": "Heal 1 HP per rank for each enemy killed by your collision chains."},
	{"id": &"last_stand", "name": "Last Stand", "branch": 3, "tier": 3, "ranks": 1, "text": "Take 25% less damage while at or below 30% HP."},
]
var points: int = 0
var earned_points: int = 0
var ranks: Dictionary = {}

func rank(id: StringName) -> int:
	return ranks.get(id, 0)

func definition(id: StringName) -> Dictionary:
	for node in NODES:
		if node.id == id:
			return node
	return {}

func spent_in_branch(branch: int) -> int:
	var total := 0
	for node in NODES:
		if node.branch == branch:
			total += rank(node.id)
	return total

func can_buy(id: StringName) -> bool:
	var node := definition(id)
	return not node.is_empty() and points > 0 and rank(id) < node.ranks and spent_in_branch(node.branch) >= node.tier * 3

func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	points -= 1
	ranks[id] = rank(id) + 1
	changed.emit()
	return true

func award(amount: int) -> void:
	if amount <= 0:
		return
	points += amount
	earned_points += amount
	changed.emit()

func respec() -> void:
	ranks.clear()
	points = earned_points
	changed.emit()
