extends Control

@onready var back_button: Button = $Panel/VBox/BackButton
@onready var anywhere_button: Button = $Panel/VBox/JoystickRow/AnywhereButton
@onready var fixed_button: Button = $Panel/VBox/JoystickRow/FixedButton
@onready var music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXRow/SFXSlider

var is_overlay := false

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	anywhere_button.pressed.connect(func(): _set_mode("anywhere"))
	fixed_button.pressed.connect(func(): _set_mode("fixed"))
	music_slider.value_changed.connect(_on_music_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume)
	_update_display()
	_set_font_size(self, 44)

func _set_font_size(node: Node, size: int) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_set_font_size(child, size)

func _on_back() -> void:
	if is_overlay:
		visible = false
		var pause_menu = get_node_or_null("/root/Main/Layer/Panel/PauseMenu")
		if pause_menu != null:
			pause_menu.visible = true
	else:
		var sm = get_node_or_null("/root/SettingsManager")
		var target = sm.previous_scene if sm != null else "res://scenes/ui/main_menu.tscn"
		get_tree().change_scene_to_file(target)

func _set_mode(mode: String) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.set_joystick_mode(mode)
	_update_display()

func _on_music_volume(value: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.set_music_volume(value)

func _on_sfx_volume(value: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.set_sfx_volume(value)

func _update_display() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	var is_fixed: bool = sm.is_fixed_joystick() if sm != null else false
	anywhere_button.text = "任意位置 ✓" if not is_fixed else "任意位置"
	fixed_button.text = "固定位置 ✓" if is_fixed else "固定位置"
	if sm != null:
		music_slider.value = sm.music_volume
		sfx_slider.value = sm.sfx_volume
