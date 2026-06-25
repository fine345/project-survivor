extends Control

var all_achievements := []

@onready var grid: GridContainer = $Panel/VBox/GridContainer
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var back_button: Button = $Panel/VBox/BackButton

const COLOR_NONE := Color(0.412, 0.416, 0.416)
const COLOR_BRONZE := Color(0.875, 0.443, 0.149)
const COLOR_SILVER := Color(0.796, 0.859, 0.988)
const COLOR_GOLD := Color(0.984, 0.949, 0.212)

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	_load_achievements()
	title_label.add_theme_font_size_override("font_size", 33)
	title_label.add_theme_color_override("font_color", Color(0, 0, 0))
	back_button.add_theme_font_size_override("font_size", 33)

func _load_achievements() -> void:
	all_achievements = [
		{"key": "difficulty_clear", "name": "毕业典礼", "desc": "通关游戏", "tiers": [1, 2, 3], "suffix": ""},
		{"key": "total_time", "name": "持之以恒", "desc": "累计存活时长", "tiers": [3000, 9000, 20000], "suffix": "秒"},
		{"key": "total_games", "name": "轻车熟路", "desc": "游戏场数", "tiers": [20, 50, 100], "suffix": "场"},
		{"key": "boss1_kills", "name": "订书钉之怒", "desc": "击败BOSS订书机", "tiers": [1, 5, 20], "suffix": "次"},
		{"key": "boss2_kills", "name": "闹钟停了", "desc": "击败BOSS闹钟", "tiers": [1, 5, 20], "suffix": "次"},
		{"key": "boss3_kills", "name": "学士的陨落", "desc": "击败BOSS学士帽", "tiers": [1, 5, 20], "suffix": "次"},
		{"key": "kills", "name": "开卷有益", "desc": "击杀普通敌人", "tiers": [100, 1000, 5000], "suffix": "本"},
		{"key": "ranged_interrupts", "name": "打断施法", "desc": "远程敌人攻击中击杀", "tiers": [5, 30, 100], "suffix": "次"},
		{"key": "laser_double_kills", "name": "一石二鸟", "desc": "一根激光同时击杀2只", "tiers": [5, 30, 100], "suffix": "次"},
		{"key": "low_hp_boss_kills", "name": "临终反扑", "desc": "1血无护盾击杀BOSS", "tiers": [1, 2, 5], "suffix": "次"},
		{"key": "no_damage_clear", "name": "完美闪避", "desc": "不受伤通关", "tiers": [1, 2, 3], "suffix": ""},
		{"key": "master", "name": "全能学霸", "desc": "所有成就达到对应等级", "tiers": [1, 2, 3], "suffix": ""},
	]
	_show_all()

func _show_all() -> void:
	for child in grid.get_children():
		child.queue_free()
	var record_manager = get_node_or_null("/root/RecordManager")
	var stats: Dictionary = record_manager.get_achievements() if record_manager != null else {}
	var other_tiers: Array[int] = []
	for def in all_achievements:
		if def["key"] == "master":
			_create_master_card(def, stats, other_tiers)
		else:
			_create_card(def, stats)
			var tier := _get_tier_index(def, stats.get(def["key"], 0), false)
			other_tiers.append(tier)

func _create_card(def: Dictionary, stats: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var current_value = stats.get(def["key"], 0)
	var tier_index := _get_tier_index(def, current_value, false)
	var bg_color := _get_color(tier_index, false)

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

	var desc_label := Label.new()
	desc_label.text = def.get("desc", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
	vbox.add_child(desc_label)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", Color(0, 0, 0))
	var max_val: int = def["tiers"].back()
	var suffix: String = def.get("suffix", "")
	if tier_index >= def["tiers"].size():
		value_label.text = "%d/%d%s" % [int(current_value), max_val, suffix]
	else:
		var next_val: int = def["tiers"][tier_index]
		value_label.text = "%d/%d%s" % [mini(int(current_value), next_val), next_val, suffix]
	vbox.add_child(value_label)

	grid.add_child(card)

func _create_master_card(def: Dictionary, stats: Dictionary, other_tiers: Array[int]) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var min_tier := 3
	for t in other_tiers:
		min_tier = mini(min_tier, t)
	var bg_color := _get_color(min_tier, false)

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
	title.text = "全能学霸"
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color(0, 0, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc_label := Label.new()
	desc_label.text = "所有成就达到对应等级"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
	vbox.add_child(desc_label)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", Color(0, 0, 0))
	var tier_names := ["未达成", "I级", "II级", "III级"]
	value_label.text = tier_names[min_tier]
	vbox.add_child(value_label)

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
