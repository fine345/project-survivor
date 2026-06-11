extends Control

@onready var records_list: VBoxContainer = $Panel/VBox/ScrollContainer/RecordsList
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_load_records()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _load_records() -> void:
	var record_manager = get_node_or_null("/root/RecordManager")
	if record_manager == null:
		return
	var records: Array = record_manager.get_records()
	if records.is_empty():
		empty_label.visible = true
		return
	empty_label.visible = false
	records = records.duplicate()
	records.reverse()
	for record in records:
		_add_record_card(record)

func _add_record_card(record: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var is_victory: bool = record.get("result", "") == "victory"
	var result_text := "胜利" if is_victory else "失败"
	var result_color := Color(0.3, 0.9, 0.3) if is_victory else Color(0.9, 0.3, 0.3)

	var header := HBoxContainer.new()
	var id_label := Label.new()
	id_label.text = "#%d" % record.get("id", 0)
	id_label.add_theme_font_size_override("font_size", 24)
	id_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(id_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var result_label := Label.new()
	result_label.text = result_text
	result_label.add_theme_font_size_override("font_size", 24)
	result_label.add_theme_color_override("font_color", result_color)
	header.add_child(result_label)
	vbox.add_child(header)

	var date_label := Label.new()
	date_label.text = record.get("date", "")
	date_label.add_theme_font_size_override("font_size", 20)
	date_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(date_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var time: float = record.get("time", 0)
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	_add_stat(stats_row, "时间", "%d:%02d" % [minutes, seconds])
	_add_stat(stats_row, "等级", "Lv.%d" % record.get("level", 1))
	_add_stat(stats_row, "击杀", str(record.get("kills", 0)))
	vbox.add_child(stats_row)

	var stats_row2 := HBoxContainer.new()
	stats_row2.add_theme_constant_override("separation", 20)
	_add_stat(stats_row2, "输出", str(record.get("damage_dealt", 0)))
	_add_stat(stats_row2, "承伤", str(record.get("damage_taken", 0)))
	_add_stat(stats_row2, "总分", str(record.get("score", 0)))
	vbox.add_child(stats_row2)

	var rewards: Array = record.get("rewards", [])
	if rewards.size() > 0:
		var rewards_label := Label.new()
		rewards_label.text = "奖励：" + "、".join(rewards)
		rewards_label.add_theme_font_size_override("font_size", 20)
		rewards_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(rewards_label)

	records_list.add_child(card)

func _add_stat(parent: HBoxContainer, name: String, value: String) -> void:
	var label := Label.new()
	label.text = "%s %s" % [name, value]
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
