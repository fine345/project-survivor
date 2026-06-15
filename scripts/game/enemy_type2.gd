extends "res://scripts/game/enemy_base.gd"

func _ready() -> void:
	max_health = 50
	move_speed = 150.0
	experience_drop = 10
	super._ready()

func _apply_visual() -> void:
	var visual: Panel = $Visual
	if visual == null:
		return
	var style: StyleBoxFlat = visual.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = Color(0.95, 0.55, 0.2, 1.0)
