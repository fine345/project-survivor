extends Node

const SETTINGS_PATH := "user://settings.json"
var joystick_mode := "anywhere"
var previous_scene := "res://scenes/ui/main_menu.tscn"
var music_volume := 1.0
var sfx_volume := 1.0

signal joystick_mode_changed(mode: String)

func _ready() -> void:
	_load()
	_apply_volumes()

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data: Dictionary = json.data
	if data.has("joystick_mode"):
		joystick_mode = data["joystick_mode"]
	if data.has("music_volume"):
		music_volume = float(data["music_volume"])
	if data.has("sfx_volume"):
		sfx_volume = float(data["sfx_volume"])

func _save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"joystick_mode": joystick_mode,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}, "\t"))
	file.close()

func set_joystick_mode(mode: String) -> void:
	joystick_mode = mode
	_save()
	joystick_mode_changed.emit(mode)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()
	_save()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()
	_save()

func _apply_volumes() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx < 0:
		AudioServer.add_bus()
		music_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx < 0:
		AudioServer.add_bus()
		sfx_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")
	AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func is_fixed_joystick() -> bool:
	return joystick_mode == "fixed"
