extends Control

signal reward_selected(reward_id: String)

var reward_ids: Array[String] = []
var reward_titles: Array[String] = []

@onready var option1: Button = $Panel/VBox/Option1
@onready var option2: Button = $Panel/VBox/Option2
@onready var option3: Button = $Panel/VBox/Option3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	option1.process_mode = Node.PROCESS_MODE_ALWAYS
	option2.process_mode = Node.PROCESS_MODE_ALWAYS
	option3.process_mode = Node.PROCESS_MODE_ALWAYS
	option1.mouse_filter = Control.MOUSE_FILTER_STOP
	option2.mouse_filter = Control.MOUSE_FILTER_STOP
	option3.mouse_filter = Control.MOUSE_FILTER_STOP
	option1.pressed.connect(func(): _emit_reward(0))
	option2.pressed.connect(func(): _emit_reward(1))
	option3.pressed.connect(func(): _emit_reward(2))

func set_rewards(new_reward_ids: Array[String], new_reward_titles: Array[String]) -> void:
	reward_ids = new_reward_ids.duplicate()
	reward_titles = new_reward_titles.duplicate()
	var options := [option1, option2, option3]
	for i in range(options.size()):
		var button: Button = options[i]
		if i < reward_ids.size() and i < reward_titles.size():
			button.text = reward_titles[i]
			button.disabled = false
			button.visible = true
		else:
			button.text = ""
			button.disabled = true
			button.visible = false

func _emit_reward(index: int) -> void:
	if index < 0 or index >= reward_ids.size():
		return
	reward_selected.emit(reward_ids[index])
