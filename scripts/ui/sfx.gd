extends Node

var _click: AudioStream = preload("res://assets/audio/click.mp3")
var _bullet: AudioStream = preload("res://assets/audio/bullet.mp3")
var _pickup: AudioStream = preload("res://assets/audio/pickup.mp3")

var _players: Array[AudioStreamPlayer] = []

func _get_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	_players.append(player)
	return player

func play_click() -> void:
	var p := _get_player()
	p.stream = _click
	p.volume_db = 0.0
	p.play()

func play_bullet() -> void:
	var p := _get_player()
	p.stream = _bullet
	p.volume_db = 0.0
	p.play()

func play_pickup() -> void:
	var p := _get_player()
	p.stream = _pickup
	p.volume_db = -12.0
	p.play()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered is Button or hovered is TextureButton:
			play_click()
	elif event is InputEventScreenTouch and event.pressed:
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered is Button or hovered is TextureButton:
			play_click()
