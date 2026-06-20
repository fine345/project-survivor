extends Control

@onready var records_button: Button = $VBox/RecordsButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var achievements_button: Button = $VBox/AchievementsButton
@onready var about_button: Button = $VBox/AboutButton
@onready var placeholder_label: Label = $PlaceholderLabel

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start)
	records_button.pressed.connect(_on_records)
	settings_button.pressed.connect(_on_settings)
	achievements_button.pressed.connect(_on_achievements)
	about_button.pressed.connect(_on_about)
	placeholder_label.visible = false
	_set_font_size(self, 44)

func _set_font_size(node: Node, size: int) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_set_font_size(child, size)

func _on_start() -> void:
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

func _show_placeholder(section_name: String) -> void:
	placeholder_label.text = "%s — 敬请期待" % section_name
	placeholder_label.visible = true
	var tween := create_tween()
	tween.tween_property(placeholder_label, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(func(): placeholder_label.visible = false; placeholder_label.modulate.a = 1.0)
