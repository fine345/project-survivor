extends Node

enum Difficulty { NORMAL, HARD, CHALLENGE }

var current_difficulty: Difficulty = Difficulty.NORMAL

func set_difficulty(diff: int) -> void:
	current_difficulty = diff as Difficulty

func get_enemy_health_multiplier() -> float:
	match current_difficulty:
		Difficulty.HARD: return 1.0
		Difficulty.CHALLENGE: return 1.5
		_: return 1.0

func get_boss_health_multiplier() -> float:
	match current_difficulty:
		Difficulty.HARD: return 1.5
		Difficulty.CHALLENGE: return 2.0
		_: return 1.0

func get_spawn_interval_multiplier() -> float:
	match current_difficulty:
		Difficulty.HARD, Difficulty.CHALLENGE: return 1.0 / 1.5
		_: return 1.0

func get_difficulty_name() -> String:
	match current_difficulty:
		Difficulty.HARD: return "困难"
		Difficulty.CHALLENGE: return "挑战"
		_: return "正常"
