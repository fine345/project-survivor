extends Control

signal joystick_released(direction: Vector2)

@export var radius := 96.0
@export var deadzone := 0.2
@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

@onready var base: Sprite2D = $Base
@onready var knob: Sprite2D = $Knob

var active := false
var enabled := true
var pointer_id := -1
var input_vector := Vector2.ZERO
var base_center := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_center = Vector2(radius, radius)
	knob.position = base_center - Vector2(48, 48)
	_apply_input(Vector2.ZERO)
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.joystick_mode_changed.connect(_on_joystick_mode_changed)
		sm.joystick_height_changed.connect(_on_joystick_height_changed)
		if sm.is_fixed_joystick():
			_show_fixed()
		else:
			base.visible = false
			knob.visible = false
	else:
		base.visible = false
		knob.visible = false

func _on_joystick_mode_changed(mode: String) -> void:
	if mode == "fixed":
		_show_fixed()
	else:
		_reset_joystick(false)
		base.visible = false
		knob.visible = false

func _show_fixed() -> void:
	base.visible = true
	knob.visible = true
	var vp_size := get_viewport_rect().size
	var sm = get_node_or_null("/root/SettingsManager")
	var height: float = sm.joystick_height if sm != null else 300.0
	position = Vector2((vp_size.x - radius * 2.0) / 2.0, vp_size.y - height - radius * 2.0)
	base.position = Vector2.ZERO
	base_center = Vector2(radius, radius)
	knob.position = base_center - Vector2(48, 48)

func _on_joystick_height_changed(height: float) -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null and sm.is_fixed_joystick():
		_show_fixed()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		if active:
			_reset_joystick(false)
		var sm = get_node_or_null("/root/SettingsManager")
		var is_fixed: bool = sm.is_fixed_joystick() if sm != null else false
		if not is_fixed:
			base.visible = false
			knob.visible = false

func _input(event: InputEvent) -> void:
	if not enabled:
		if active:
			_reset_joystick(true)
		return
	if get_tree().paused:
		if active:
			_reset_joystick(false)
		return

	var sm = get_node_or_null("/root/SettingsManager")
	var is_fixed: bool = sm.is_fixed_joystick() if sm != null else false

	if is_fixed:
		_handle_fixed_input(event)
	else:
		_handle_free_input(event)

func _handle_free_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active and not _is_over_ui(event.position):
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
		if event.pressed and not active and not _is_over_ui(event.position):
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

func _handle_fixed_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _is_over_ui(event.position):
			active = true
			pointer_id = event.index
			_update_from_position(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and active and event.index == pointer_id:
			_reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and active and event.index == pointer_id:
		_update_from_position(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _is_over_ui(event.position):
			active = true
			pointer_id = 0
			_update_from_position(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and active and pointer_id == 0:
			_reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and active and pointer_id == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_from_position(event.position)
		get_viewport().set_input_as_handled()

func _is_in_joystick_area(screen_position: Vector2) -> bool:
	var joy_rect := Rect2(global_position, Vector2(radius * 2, radius * 2))
	return joy_rect.has_point(screen_position)

func _is_over_ui(screen_position: Vector2) -> bool:
	for control in get_tree().get_nodes_in_group("ui_capture"):
		if control is Control and control.visible and control.get_global_rect().has_point(screen_position):
			return true
	return false

func _show_joystick_at(screen_position: Vector2) -> void:
	base.visible = true
	knob.visible = true
	position = screen_position - base_center
	base.position = Vector2.ZERO
	knob.position = base_center - Vector2(48, 48)

func _update_from_position(screen_position: Vector2) -> void:
	var local_position := screen_position - position
	var delta := local_position - base_center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	input_vector = delta / radius
	knob.position = base_center + delta - Vector2(48, 48)
	_apply_input(input_vector)

func _reset_joystick(emit_release := true) -> void:
	var last_dir := input_vector.normalized()
	if emit_release and last_dir.length() > 0.01:
		joystick_released.emit(last_dir)
	active = false
	pointer_id = -1
	input_vector = Vector2.ZERO
	var sm = get_node_or_null("/root/SettingsManager")
	if sm != null and sm.is_fixed_joystick():
		knob.position = base_center - Vector2(48, 48)
	else:
		base.visible = false
		knob.visible = false
		knob.position = base_center - Vector2(48, 48)
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
