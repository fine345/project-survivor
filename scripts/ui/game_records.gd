extends Control

var all_records: Array = []
var current_page := 0
var page_size := 6

@onready var records_list: VBoxContainer = $Panel/VBox/RecordsList
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var page_label: Label = $Panel/VBox/PageInfo/PageLabel
@onready var prev_button: Button = $Panel/VBox/PageInfo/PrevButton
@onready var next_button: Button = $Panel/VBox/PageInfo/NextButton
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var detail_panel: Control = $DetailPanel
@onready var id_label: Label = $DetailPanel/DetailBox/VBox/InfoRow1/IDLabel
@onready var result_label: Label = $DetailPanel/DetailBox/VBox/InfoRow1/ResultLabel
@onready var date_label: Label = $DetailPanel/DetailBox/VBox/InfoRow1/DateLabel
@onready var level_label: Label = $DetailPanel/DetailBox/VBox/StatsRow1/LevelLabel
@onready var kills_label: Label = $DetailPanel/DetailBox/VBox/StatsRow1/KillsLabel
@onready var time_label: Label = $DetailPanel/DetailBox/VBox/StatsRow1/TimeLabel
@onready var damage_label: Label = $DetailPanel/DetailBox/VBox/StatsRow2/DamageLabel
@onready var score_label: Label = $DetailPanel/DetailBox/VBox/StatsRow2/ScoreLabel
@onready var rewards_label: Label = $DetailPanel/DetailBox/VBox/RewardsLabel
@onready var close_button: Button = $DetailPanel/DetailBox/VBox/CloseButton
@onready var dim: ColorRect = $DetailPanel/Dim

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	prev_button.pressed.connect(_prev_page)
	next_button.pressed.connect(_next_page)
	close_button.pressed.connect(_close_detail)
	dim.gui_input.connect(_on_dim_input)
	detail_panel.visible = false
	_load_records()
	page_label.add_theme_font_size_override("font_size", 33)
	title_label.add_theme_font_size_override("font_size", 33)
	prev_button.add_theme_font_size_override("font_size", 33)
	next_button.add_theme_font_size_override("font_size", 33)
	back_button.add_theme_font_size_override("font_size", 33)
	id_label.add_theme_font_size_override("font_size", 33)
	result_label.add_theme_font_size_override("font_size", 33)
	date_label.add_theme_font_size_override("font_size", 22)
	damage_label.add_theme_font_size_override("font_size", 33)
	score_label.add_theme_font_size_override("font_size", 33)
	close_button.add_theme_font_size_override("font_size", 33)

func _load_records() -> void:
	var record_manager = get_node_or_null("/root/RecordManager")
	if record_manager == null:
		return
	all_records = record_manager.get_records()
	all_records = all_records.duplicate()
	all_records.reverse()
	if all_records.is_empty():
		empty_label.visible = true
		records_list.visible = false
		$Panel/VBox/PageInfo.visible = false
		return
	empty_label.visible = false
	records_list.visible = true
	$Panel/VBox/PageInfo.visible = true
	current_page = 0
	_show_page()

func _show_page() -> void:
	for child in records_list.get_children():
		child.queue_free()
	var total_pages := maxi(1, ceili(float(all_records.size()) / float(page_size)))
	current_page = clampi(current_page, 0, total_pages - 1)
	var start := current_page * page_size
	var end_idx := mini(start + page_size, all_records.size())
	for i in range(start, end_idx):
		_create_record_card(all_records[i])
	var remaining := page_size - (end_idx - start)
	for i in range(remaining):
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spacer.size_flags_stretch_ratio = 1.0
		records_list.add_child(spacer)
	page_label.text = "第%d/%d页" % [current_page + 1, total_pages]
	prev_button.disabled = current_page <= 0
	next_button.disabled = current_page >= total_pages - 1

func _create_record_card(record: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_detail(record)
	)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var is_victory: bool = record.get("result", "") == "victory"
	var result_text := "胜利" if is_victory else "失败"
	var result_color := Color(0.3, 0.9, 0.3) if is_victory else Color(0.9, 0.3, 0.3)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	vbox.add_child(row1)

	var font_main := 22
	var font_small := 22
	var font_result := 44
	var font_value := 44

	var id_label := Label.new()
	id_label.text = "#%d" % record.get("id", 0)
	id_label.add_theme_font_size_override("font_size", font_main)
	id_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row1.add_child(id_label)

	var result_lbl := Label.new()
	result_lbl.text = result_text
	result_lbl.add_theme_font_size_override("font_size", font_result)
	result_lbl.add_theme_color_override("font_color", result_color)
	row1.add_child(result_lbl)

	var row1_spacer := Control.new()
	row1_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(row1_spacer)

	var date_lbl := Label.new()
	date_lbl.text = record.get("date", "")
	date_lbl.add_theme_font_size_override("font_size", font_small)
	date_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row1.add_child(date_lbl)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var row2a := GridContainer.new()
	row2a.columns = 6
	row2a.add_theme_constant_override("h_separation", 12)
	row2a.add_theme_constant_override("v_separation", 4)
	vbox.add_child(row2a)

	var time_val: float = record.get("time", 0)
	var minutes := int(time_val) / 60
	var seconds := int(time_val) % 60
	_add_grid_pair(row2a, "等级：", "Lv.%d" % record.get("level", 1), font_small, font_value)
	_add_grid_pair(row2a, "击杀：", "%d" % record.get("kills", 0), font_small, font_value)
	_add_grid_pair(row2a, "时间：", "%d:%02d" % [minutes, seconds], font_small, font_value)

	var row2b := GridContainer.new()
	row2b.columns = 4
	row2b.add_theme_constant_override("h_separation", 12)
	row2b.add_theme_constant_override("v_separation", 4)
	vbox.add_child(row2b)
	_add_grid_pair(row2b, "输出：", "%d" % record.get("damage_dealt", 0), font_small, font_value)
	_add_grid_pair(row2b, "总分：", "%d" % record.get("score", 0), font_small, font_value)

	records_list.add_child(card)

func _add_grid_pair(parent: GridContainer, label_text: String, value_text: String, label_size: int, value_size: int) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", label_size)
	lbl.custom_minimum_size.x = 70
	parent.add_child(lbl)
	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", value_size)
	val.custom_minimum_size.x = 80
	parent.add_child(val)

func _add_stat_pair(parent: HBoxContainer, label_text: String, value_text: String, label_size: int, value_size: int) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", label_size)
	parent.add_child(lbl)
	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", value_size)
	parent.add_child(val)

func _add_stat(parent: HBoxContainer, text: String, font_size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _show_detail(record: Dictionary) -> void:
	var is_victory: bool = record.get("result", "") == "victory"
	$DetailPanel/DetailBox/VBox/TitleLabel.add_theme_font_size_override("font_size", 33)
	id_label.text = "#%d" % record.get("id", 0)
	id_label.add_theme_font_size_override("font_size", 22)
	result_label.text = "胜利" if is_victory else "失败"
	result_label.add_theme_font_size_override("font_size", 44)
	result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if is_victory else Color(0.9, 0.3, 0.3))
	date_label.text = record.get("date", "")
	date_label.add_theme_font_size_override("font_size", 22)
	level_label.visible = false
	kills_label.visible = false
	time_label.visible = false
	damage_label.visible = false
	score_label.visible = false
	var level_val: int = record.get("level", 1)
	var kills_val: int = record.get("kills", 0)
	var time_val: float = record.get("time", 0)
	var minutes := int(time_val) / 60
	var seconds := int(time_val) % 60
	var damage_val: int = record.get("damage_dealt", 0)
	var score_val: int = record.get("score", 0)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 6
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 4)
	var vbox: VBoxContainer = $DetailPanel/DetailBox/VBox
	var sep2_idx := vbox.get_node("Separator2").get_index()
	vbox.add_child(stats_grid)
	vbox.move_child(stats_grid, sep2_idx + 1)
	_add_grid_pair(stats_grid, "等级：", "Lv.%d" % level_val, 33, 44)
	_add_grid_pair(stats_grid, "击杀：", "%d" % kills_val, 33, 44)
	_add_grid_pair(stats_grid, "时间：", "%d:%02d" % [minutes, seconds], 33, 44)
	_add_grid_pair(stats_grid, "输出：", "%d" % damage_val, 33, 44)
	_add_grid_pair(stats_grid, "总分：", "%d" % score_val, 33, 44)
	var rewards: Array = record.get("rewards", [])
	if rewards.size() > 0:
		rewards_label.text = "获得奖励："
		rewards_label.add_theme_font_size_override("font_size", 33)
		rewards_label.visible = true
		var rewards_grid: GridContainer = $DetailPanel/DetailBox/VBox/RewardsGrid
		if rewards_grid != null:
			for child in rewards_grid.get_children():
				child.queue_free()
			rewards_grid.columns = 2 if rewards.size() > 1 else 1
			for reward in rewards:
				var lbl := Label.new()
				var reward_str := str(reward)
				if "×" in reward_str and not " ×" in reward_str:
					reward_str = reward_str.replace("×", " ×")
				lbl.text = reward_str
				lbl.add_theme_font_size_override("font_size", 22)
				rewards_grid.add_child(lbl)
			rewards_grid.visible = true
	else:
		rewards_label.visible = false
		var rewards_grid: GridContainer = $DetailPanel/DetailBox/VBox/RewardsGrid
		if rewards_grid != null:
			rewards_grid.visible = false
	close_button.add_theme_font_size_override("font_size", 33)
	$DetailPanel/DetailBox/VBox/StatsRow1.visible = false
	$DetailPanel/DetailBox/VBox/StatsRow2.visible = false
	detail_panel.visible = true

func _close_detail() -> void:
	detail_panel.visible = false

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_detail()

func _prev_page() -> void:
	current_page -= 1
	_show_page()

func _next_page() -> void:
	current_page += 1
	_show_page()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
