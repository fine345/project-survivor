extends Control

@export var radius := 70.0
@export var deadzone := 0.2
@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"
@export var mouse_active_area_ratio := 0.35

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob

var active := false
var enabled := true
var pointer_id := -1
var input_vector := Vector2.ZERO
var base_center := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.visible = false
	_apply_input(Vector2.ZERO)

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		if active:
			_reset_joystick()
		base.visible = false

func _input(event: InputEvent) -> void:
	if not enabled:
		if active:
			_reset_joystick()
		return
	if get_tree().paused:
		if active:
			_reset_joystick()
		return

	if event is InputEventScreenTouch:
		if event.pressed and not active and _can_use_touch_at(event.position) and not _is_over_ui(event.position):
			active = true
			pointer_id = event.index
			_show_joystick_at(event.position)
			_update_from_position(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and active and event.index == pointer_id:
			_reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and active and event.index == pointer_id:
		_update_from_position(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not active and _can_use_mouse_at(event.position) and not _is_over_ui(event.position):
			active = true
			pointer_id = 0
			_show_joystick_at(event.position)
			_update_from_position(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and active and pointer_id == 0:
			_reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and active and pointer_id == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_from_position(event.position)
		get_viewport().set_input_as_handled()

func _can_use_touch_at(screen_position: Vector2) -> bool:
	return true

func _can_use_mouse_at(screen_position: Vector2) -> bool:
	return true

func _is_over_ui(screen_position: Vector2) -> bool:
	for control in get_tree().get_nodes_in_group("ui_capture"):
		if control is Control and control.visible and control.get_global_rect().has_point(screen_position):
			return true
	return false

func _show_joystick_at(screen_position: Vector2) -> void:
	base.visible = true
	base.size = Vector2(radius * 2.0, radius * 2.0)
	position = screen_position - Vector2(radius, radius)
	base.position = Vector2.ZERO
	base_center = Vector2(radius, radius)
	knob.position = base_center - knob.size * 0.5

func _update_from_position(screen_position: Vector2) -> void:
	var local_position := screen_position - position
	var delta := local_position - base_center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	input_vector = delta / radius
	knob.position = base_center + delta - knob.size * 0.5
	_apply_input(input_vector)

func _reset_joystick() -> void:
	active = false
	pointer_id = -1
	input_vector = Vector2.ZERO
	base.visible = false
	knob.position = base_center - knob.size * 0.5
	_apply_input(Vector2.ZERO)

func _apply_input(vec: Vector2) -> void:
	Input.action_release(action_left)
	Input.action_release(action_right)
	Input.action_release(action_up)
	Input.action_release(action_down)
	if vec.length() < deadzone:
		return
	if vec.x < -deadzone:
		Input.action_press(action_left, -vec.x)
	if vec.x > deadzone:
		Input.action_press(action_right, vec.x)
	if vec.y < -deadzone:
		Input.action_press(action_up, -vec.y)
	if vec.y > deadzone:
		Input.action_press(action_down, vec.y)
