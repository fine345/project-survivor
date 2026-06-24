extends Control

var all_achievements := []

@onready var grid: GridContainer = $Panel/VBox/GridContainer
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var back_button: Button = $Panel/VBox/BackButton

const COLOR_NONE := Color(0.5, 0.5, 0.55)
const COLOR_BRONZE := Color(0.45, 0.3, 0.15)
const COLOR_SILVER := Color(0.35, 0.35, 0.4)
const COLOR_GOLD := Color(0.5, 0.42, 0.1)

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	_load_achievements()
	title_label.add_theme_font_size_override("font_size", 33)
	title_label.add_theme_color_override("font_color", Color(0, 0, 0))
	back_button.add_theme_font_size_override("font_size", 33)

func _load_achievements() -> void:
	all_achievements = [
		{"key": "kills", "name": "击杀数", "tiers": [100, 500, 2000]},
		{"key": "total_time", "name": "总存活时长", "tiers": [10000, 50000, 200000], "suffix": "秒"},
		{"key": "total_games", "name": "游戏场数", "tiers": [10, 50, 200]},
		{"key": "no_damage_victory", "name": "无伤通关", "tiers": [1], "is_bool": true},
	]
	for i in range(8):
		all_achievements.append({"key": "none_%d" % i, "name": "暂无", "tiers": [1], "is_bool": true, "hidden": true})
	_show_all()

func _show_all() -> void:
	for child in grid.get_children():
		child.queue_free()
	var record_manager = get_node_or_null("/root/RecordManager")
	var stats: Dictionary = record_manager.get_achievements() if record_manager != null else {}
	for def in all_achievements:
		if def.get("hidden", false):
			_create_placeholder_card()
		else:
			_create_card(def, stats)

func _create_card(def: Dictionary, stats: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var current_value = stats.get(def["key"], 0)
	var is_bool: bool = def.get("is_bool", false)
	var tier_index := _get_tier_index(def, current_value, is_bool)
	var bg_color := _get_color(tier_index, is_bool)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var title := Label.new()
	title.text = def["name"]
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color(0, 0, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", Color(0, 0, 0))
	if is_bool:
		value_label.text = "已达成" if bool(current_value) else "未达成"
	else:
		if tier_index >= def["tiers"].size():
			var max_val: int = def["tiers"].back()
			var suffix: String = def.get("suffix", "")
			value_label.text = "%d/%d%s" % [int(current_value), max_val, suffix]
		else:
			var next_val: int = def["tiers"][tier_index]
			var suffix: String = def.get("suffix", "")
			value_label.text = "%d/%d%s" % [mini(int(current_value), next_val), next_val, suffix]
	vbox.add_child(value_label)

	grid.add_child(card)

func _create_placeholder_card() -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	grid.add_child(card)

func _get_tier_index(def: Dictionary, current_value, is_bool: bool) -> int:
	if is_bool:
		return 1 if bool(current_value) else 0
	for i in range(def["tiers"].size() - 1, -1, -1):
		if int(current_value) >= def["tiers"][i]:
			return i + 1
	return 0

func _get_color(tier_index: int, is_bool: bool) -> Color:
	if is_bool:
		return COLOR_GOLD if tier_index >= 1 else COLOR_NONE
	match tier_index:
		0: return COLOR_NONE
		1: return COLOR_BRONZE
		2: return COLOR_SILVER
		_: return COLOR_GOLD
