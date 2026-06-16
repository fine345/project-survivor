extends "res://scripts/game/enemy_base.gd"

func _ready() -> void:
	max_health = 30
	move_speed = 200.0
	experience_drop = 5
	super._ready()

func _apply_visual() -> void:
	var visual: Panel = $Visual
	if visual == null:
		return
	var style: StyleBoxFlat = visual.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = Color(0.9, 0.2, 0.3, 1.0)
