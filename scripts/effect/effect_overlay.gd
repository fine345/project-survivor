extends Node2D

@export var effect_color: Color = Color(1, 1, 1, 0.5)
@export var effect_size: Vector2 = Vector2(28, 28)
@export var lifetime := 1.5
@export var follow_parent := true

const EFFECT_TEXTURE := preload("res://assets/generated/effect_box_white.png")

var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = EFFECT_TEXTURE
	sprite.centered = true
	sprite.modulate = effect_color
	sprite.scale = effect_size / 32.0
	sprite.z_index = 100
	add_child(sprite)
	if get_parent() is Node2D:
		global_position = (get_parent() as Node2D).global_position
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(_delta: float) -> void:
	if follow_parent and get_parent() is Node2D:
		global_position = (get_parent() as Node2D).global_position
