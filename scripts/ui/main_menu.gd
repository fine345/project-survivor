extends Control

@onready var records_button: Button = $VBox/RecordsButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var achievements_button: Button = $VBox/AchievementsButton
@onready var about_button: Button = $VBox/AboutButton
@onready var placeholder_label: Label = $PlaceholderLabel

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start)
	records_button.pressed.connect(_on_records)
	settings_button.pressed.connect(func(): _show_placeholder("设置"))
	achievements_button.pressed.connect(func(): _show_placeholder("成就"))
	about_button.pressed.connect(func(): _show_placeholder("关于"))
	placeholder_label.visible = false

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")

func _on_records() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_records.tscn")

func _show_placeholder(section_name: String) -> void:
	placeholder_label.text = "%s — 敬请期待" % section_name
	placeholder_label.visible = true
	var tween := create_tween()
	tween.tween_property(placeholder_label, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(func(): placeholder_label.visible = false; placeholder_label.modulate.a = 1.0)
