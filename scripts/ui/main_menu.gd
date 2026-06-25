extends Control

@onready var records_button: Button = $VBox/RecordsButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var achievements_button: Button = $VBox/AchievementsButton
@onready var about_button: Button = $VBox/AboutButton
@onready var placeholder_label: Label = $PlaceholderLabel
@onready var difficulty_panel: Control = $DifficultyPanel

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start)
	records_button.pressed.connect(_on_records)
	settings_button.pressed.connect(_on_settings)
	achievements_button.pressed.connect(_on_achievements)
	about_button.pressed.connect(_on_about)
	placeholder_label.visible = false
	difficulty_panel.visible = false
	$VBox/StartButton.visible = true
	_set_font_size(self, 44)
	_style_menu_button($VBox/StartButton, "开始游戏")
	_style_menu_button(records_button, "游戏记录")
	_style_menu_button(settings_button, "设置")
	_style_menu_button(achievements_button, "成就")
	_style_menu_button(about_button, "关于")
	_style_menu_button($DifficultyPanel/NormalBtn, "正常模式")
	_style_menu_button($DifficultyPanel/HardBtn, "困难模式")
	_style_menu_button($DifficultyPanel/ChallengeBtn, "挑战模式")
	$DifficultyPanel/NormalBtn.pressed.connect(func(): _on_difficulty_selected(0))
	$DifficultyPanel/HardBtn.pressed.connect(func(): _on_difficulty_selected(1))
	$DifficultyPanel/BackBtn.pressed.connect(func(): $VBox.visible = true; $Title.visible = true; difficulty_panel.visible = false)
	$DifficultyPanel/ChallengeBtn.pressed.connect(func(): _on_difficulty_selected(2))

func _set_font_size(node: Node, size: int) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_set_font_size(child, size)

func _style_menu_button(btn: Button, label_text: String) -> void:
	btn.text = ""
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
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
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(lbl)

func _on_start() -> void:
	$VBox.visible = false
	$Title.visible = false
	difficulty_panel.visible = true
	_update_difficulty_locks()

func _update_difficulty_locks() -> void:
	var rm = get_node_or_null("/root/RecordManager")
	var normal_unlocked: bool = rm != null and rm.get_achievement_stat("difficulty_normal_victory") == true
	var hard_unlocked: bool = rm != null and rm.get_achievement_stat("difficulty_hard_victory") == true
	_set_difficulty_button($DifficultyPanel/HardBtn, "困难模式", normal_unlocked)
	_set_difficulty_button($DifficultyPanel/ChallengeBtn, "挑战模式", hard_unlocked)

func _set_difficulty_button(btn: Button, label_text: String, unlocked: bool) -> void:
	btn.disabled = not unlocked
	var lbl: Label = btn.get_child(0) if btn.get_child_count() > 0 and btn.get_child(0) is Label else null
	if lbl != null:
		if unlocked:
			lbl.text = label_text
			lbl.modulate = Color(1, 1, 1, 1)
		else:
			lbl.text = label_text + " 🔒"
			lbl.modulate = Color(0.5, 0.5, 0.5, 0.7)
	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = Color(0, 0, 0, 0)
	disabled_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("disabled", disabled_style)

func _on_difficulty_selected(diff: int) -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	if dm != null:
		dm.set_difficulty(diff)
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")

func _on_records() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_records.tscn")

func _on_settings() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.previous_scene = "res://scenes/ui/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_achievements() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/achievements.tscn")

func _on_about() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/about.tscn")
