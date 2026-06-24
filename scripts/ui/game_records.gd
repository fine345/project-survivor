extends Control

var all_records: Array = []
var current_page := 0
var page_size := 5

@onready var records_list: VBoxContainer = $Panel/VBox/RecordsList
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var page_label: Label = $Panel/VBox/PageInfo/PageLabel
@onready var prev_button: Button = $Panel/VBox/PageInfo/PrevButton
@onready var next_button: Button = $Panel/VBox/PageInfo/NextButton
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var detail_panel: Control = $DetailPanel
@onready var rewards_label: Label = $DetailPanel/DetailBox/VBox/RewardsLabel
@onready var close_button: Button = $DetailPanel/DetailBox/VBox/CloseButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	prev_button.pressed.connect(_prev_page)
	next_button.pressed.connect(_next_page)
	close_button.pressed.connect(_close_detail)
	detail_panel.visible = false
	_load_records()
	page_label.add_theme_font_size_override("font_size", 33)
	title_label.add_theme_font_size_override("font_size", 33)
	prev_button.add_theme_font_size_override("font_size", 33)
	next_button.add_theme_font_size_override("font_size", 33)
	back_button.add_theme_font_size_override("font_size", 33)
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
	style.bg_color = Color(0.45, 0.45, 0.5, 1)
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
	id_label.add_theme_color_override("font_color", Color(0, 0, 0))
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
	date_lbl.add_theme_color_override("font_color", Color(0, 0, 0))
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
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.custom_minimum_size.x = 70
	parent.add_child(lbl)
	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", value_size)
	val.add_theme_color_override("font_color", Color(0, 0, 0))
	val.custom_minimum_size.x = 80
	parent.add_child(val)

func _add_stat_pair(parent: HBoxContainer, label_text: String, value_text: String, label_size: int, value_size: int) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", label_size)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	parent.add_child(lbl)
	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", value_size)
	val.add_theme_color_override("font_color", Color(0, 0, 0))
	parent.add_child(val)

func _add_stat(parent: HBoxContainer, text: String, font_size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	parent.add_child(label)

var _detail_stats_grid: GridContainer = null
var _detail_stats_grid2: GridContainer = null

func _show_detail(record: Dictionary) -> void:
	_clear_detail_dynamic()
	var is_victory: bool = record.get("result", "") == "victory"
	var time_val: float = record.get("time", 0)
	var minutes := int(time_val) / 60
	var seconds := int(time_val) % 60
	$DetailPanel/DetailBox/VBox/TitleRow/TitleLabel.text = "#%d %s %s" % [record.get("id", 0), "胜利" if is_victory else "失败", "%d:%02d" % [minutes, seconds]]
	$DetailPanel/DetailBox/VBox/TitleRow/TitleLabel.add_theme_font_size_override("font_size", 44)
	$DetailPanel/DetailBox/VBox/TitleRow/TitleLabel.add_theme_color_override("font_color", Color(0, 0, 0))
	$DetailPanel/DetailBox/VBox/LevelRow/LevelValue.text = "Lv.%d" % record.get("level", 1)
	$DetailPanel/DetailBox/VBox/LevelRow/LevelValue.add_theme_font_size_override("font_size", 55)
	$DetailPanel/DetailBox/VBox/LevelRow/LevelValue.add_theme_color_override("font_color", Color(0, 0, 0))
	$DetailPanel/DetailBox/VBox/KillsRow/KillsValue.text = "%d" % record.get("kills", 0)
	$DetailPanel/DetailBox/VBox/KillsRow/KillsValue.add_theme_font_size_override("font_size", 55)
	$DetailPanel/DetailBox/VBox/KillsRow/KillsValue.add_theme_color_override("font_color", Color(0, 0, 0))
	$DetailPanel/DetailBox/VBox/TimeRow/TimeValue.text = "%d:%02d" % [minutes, seconds]
	$DetailPanel/DetailBox/VBox/TimeRow/TimeValue.add_theme_font_size_override("font_size", 55)
	$DetailPanel/DetailBox/VBox/TimeRow/TimeValue.add_theme_color_override("font_color", Color(0, 0, 0))
	$DetailPanel/DetailBox/VBox/DealtRow/DealtValue.text = "%d" % record.get("damage_dealt", 0)
	$DetailPanel/DetailBox/VBox/DealtRow/DealtValue.add_theme_font_size_override("font_size", 55)
	$DetailPanel/DetailBox/VBox/DealtRow/DealtValue.add_theme_color_override("font_color", Color(0, 0, 0))
	$DetailPanel/DetailBox/VBox/ScoreRow/ScoreValue.text = "%d" % record.get("score", 0)
	$DetailPanel/DetailBox/VBox/ScoreRow/ScoreValue.add_theme_font_size_override("font_size", 55)
	$DetailPanel/DetailBox/VBox/ScoreRow/ScoreValue.add_theme_color_override("font_color", Color(0, 0, 0))
	var rewards: Array = record.get("rewards", [])
	if rewards.size() > 0:
		$DetailPanel/DetailBox/VBox/RewardsLabel.visible = true
		var rewards_grid: GridContainer = $DetailPanel/DetailBox/VBox/RewardsGrid
		for child in rewards_grid.get_children():
			child.queue_free()
		rewards_grid.columns = 2 if rewards.size() > 1 else 1
		for reward in rewards:
			var lbl := Label.new()
			lbl.text = str(reward)
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.add_theme_color_override("font_color", Color(0, 0, 0))
			rewards_grid.add_child(lbl)
		rewards_grid.visible = true
	else:
		$DetailPanel/DetailBox/VBox/RewardsGrid.visible = false
	_style_summary_button($DetailPanel/DetailBox/VBox/CloseButton, "关闭")
	detail_panel.visible = true

func _close_detail() -> void:
	detail_panel.visible = false
	_clear_detail_dynamic()

func _clear_detail_dynamic() -> void:
	pass

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
	for child in btn.get_children():
		if child is Label:
			child.queue_free()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 33)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(lbl)

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
