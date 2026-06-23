extends Control

signal restart_requested
signal exit_to_menu_requested

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var time_name: Label = $Panel/VBox/TimeRow/NameLabel
@onready var time_value: Label = $Panel/VBox/TimeRow/ValueLabel
@onready var kills_name: Label = $Panel/VBox/KillsRow/NameLabel
@onready var kills_value: Label = $Panel/VBox/KillsRow/ValueLabel
@onready var level_name: Label = $Panel/VBox/LevelRow/NameLabel
@onready var level_value: Label = $Panel/VBox/LevelRow/ValueLabel
@onready var dealt_name: Label = $Panel/VBox/DealtRow/NameLabel
@onready var dealt_value: Label = $Panel/VBox/DealtRow/ValueLabel
@onready var rewards_label: Label = $Panel/VBox/RewardsLabel
@onready var rewards_grid: GridContainer = $Panel/VBox/RewardsGrid
@onready var score_label: Label = $Panel/VBox/ScoreRow/ScoreLabel
@onready var score_value: Label = $Panel/VBox/ScoreRow/ScoreValue
@onready var retry_button: Button = $Panel/VBox/RetryButton
@onready var exit_button: Button = $Panel/VBox/ExitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_button.pressed.connect(func(): restart_requested.emit())
	exit_button.pressed.connect(func(): exit_to_menu_requested.emit())
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", Color(0, 0, 0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_name.add_theme_font_size_override("font_size", 33)
	time_name.add_theme_color_override("font_color", Color(0, 0, 0))
	kills_name.add_theme_font_size_override("font_size", 33)
	kills_name.add_theme_color_override("font_color", Color(0, 0, 0))
	level_name.add_theme_font_size_override("font_size", 33)
	level_name.add_theme_color_override("font_color", Color(0, 0, 0))
	dealt_name.add_theme_font_size_override("font_size", 33)
	dealt_name.add_theme_color_override("font_color", Color(0, 0, 0))
	time_value.add_theme_font_size_override("font_size", 55)
	time_value.add_theme_color_override("font_color", Color(0, 0, 0))
	kills_value.add_theme_font_size_override("font_size", 55)
	kills_value.add_theme_color_override("font_color", Color(0, 0, 0))
	level_value.add_theme_font_size_override("font_size", 55)
	level_value.add_theme_color_override("font_color", Color(0, 0, 0))
	dealt_value.add_theme_font_size_override("font_size", 55)
	dealt_value.add_theme_color_override("font_color", Color(0, 0, 0))
	rewards_label.add_theme_font_size_override("font_size", 33)
	rewards_label.add_theme_color_override("font_color", Color(0, 0, 0))
	score_label.add_theme_font_size_override("font_size", 33)
	score_label.add_theme_color_override("font_color", Color(0, 0, 0))
	score_value.add_theme_font_size_override("font_size", 55)
	score_value.add_theme_color_override("font_color", Color(0, 0, 0))
	retry_button.add_theme_font_size_override("font_size", 33)
	exit_button.add_theme_font_size_override("font_size", 33)
	_style_summary_button(retry_button, "再试一次")
	_style_summary_button(exit_button, "退出到主菜单")

func _style_summary_button(btn: Button, label_text: String) -> void:
	if btn == null:
		return
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0, 0, 0, 0.15)
	pressed_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 33)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(lbl)

func show_summary(stats: Dictionary) -> void:
	visible = true
	var is_victory: bool = stats.get("is_victory", false)
	title_label.text = "通关！" if is_victory else "本局复盘"
	var time: float = stats.get("time", 0.0)
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	_set_row(time_name, time_value, "存活时间", "%d:%02d" % [minutes, seconds])
	_set_row(kills_name, kills_value, "击杀数量", str(stats.get("kills", 0)))
	_set_row(level_name, level_value, "最终等级", "Lv.%d" % stats.get("level", 1))
	_set_row(dealt_name, dealt_value, "造成伤害", str(stats.get("damage_dealt", 0)))
	var rewards: Dictionary = stats.get("rewards", {})
	var keys: Array = rewards.keys()
	rewards_label.text = "获得奖励"
	for key in keys:
		var count: int = rewards[key] if rewards[key] is int else 1
		var lbl := Label.new()
		lbl.text = "%s ×%d" % [key, count] if count > 1 else str(key)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		lbl.custom_minimum_size.x = 200
		rewards_grid.add_child(lbl)
	score_value.text = str(stats.get("score", 0))
	get_tree().paused = true

func _set_row(name_label: Label, value_label: Label, name_text: String, value_text: String) -> void:
	name_label.text = name_text
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
