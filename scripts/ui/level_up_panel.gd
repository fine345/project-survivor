extends Control

signal reward_selected(reward_id: String)

var reward_ids: Array[String] = []
var reward_names: Array[String] = []
var reward_details: Array[String] = []
var reward_details2: Array[String] = []

@onready var dim: Control = $Dim

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_option($Option1, 0)
	_setup_option($Option2, 1)
	_setup_option($Option3, 2)
	$Title.add_theme_font_size_override("font_size", 33)
	$Title.add_theme_color_override("font_color", Color(0, 0, 0))

func _setup_option(btn: Button, index: int) -> void:
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_ALL
	btn.text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0, 0, 0, 0.1)
	pressed_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.pressed.connect(func(): _emit_reward(index))

func set_rewards(new_reward_ids: Array[String], new_reward_names: Array[String], new_reward_details: Array[String] = [], new_reward_details2: Array[String] = []) -> void:
	reward_ids = new_reward_ids.duplicate()
	reward_names = new_reward_names.duplicate()
	reward_details = new_reward_details.duplicate()
	reward_details2 = new_reward_details2.duplicate()
	var options := [$Option1, $Option2, $Option3]
	for i in range(options.size()):
		var button: Button = options[i]
		_clear_labels(button)
		if i < reward_ids.size() and i < reward_names.size():
			button.visible = true
			button.disabled = false
			_add_label(button, reward_names[i], 33, 0)
			var y := 40.0
			if i < reward_details.size() and reward_details[i] != "":
				_add_label(button, reward_details[i], 22, y)
				y += 30.0
			if i < reward_details2.size() and reward_details2[i] != "":
				_add_label(button, reward_details2[i], 22, y)
		else:
			button.visible = false
			button.disabled = true

func _clear_labels(btn: Button) -> void:
	for child in btn.get_children():
		if child is Label:
			child.queue_free()

func _add_label(btn: Button, text: String, font_size: int, y: float) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(btn.size.x, font_size + 8)
	btn.add_child(lbl)

func _emit_reward(index: int) -> void:
	if index < 0 or index >= reward_ids.size():
		return
	reward_selected.emit(reward_ids[index])
