extends "res://scripts/game/enemy_base.gd"

func _ready() -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	var mult: float = dm.get_enemy_health_multiplier() if dm != null else 1.0
	max_health = int(30 * mult)
	move_speed = 200.0
	experience_drop = 5
	super._ready()

func _apply_visual() -> void:
	_setup_animations(
		"res://assets/sprites/enemies/enemy_1_idle-Sheet.png",
		"res://assets/sprites/enemies/enemy_1_walk-Sheet.png",
		"res://assets/sprites/enemies/enemy_124_hurt-Sheet.png"
	)
