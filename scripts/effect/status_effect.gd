extends Node2D

@export var effect_color: Color = Color(1, 1, 1, 0.4)
@export var effect_size: Vector2 = Vector2(30, 30)
@export var lifetime := 1.5
@export var follow_target := true

var target: Node2D = null
var time_left := 0.0
var sprite: Sprite2D

func _ready() -> void:
	time_left = maxf(lifetime, 0.0)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/generated/effect_box_white.png")
	sprite.centered = true
	sprite.modulate = effect_color
	sprite.scale = effect_size / 32.0
	sprite.z_index = 100
	add_child(sprite)
	_update_visual()

func set_target(target_node: Node2D) -> void:
	target = target_node
	if target != null and is_instance_valid(target):
		global_position = target.global_position

func set_effect_lifetime(new_lifetime: float) -> void:
	lifetime = new_lifetime
	time_left = maxf(new_lifetime, 0.0)

func set_effect_size(new_size: Vector2) -> void:
	effect_size = new_size
	_update_visual()

func set_effect_color(new_color: Color) -> void:
	effect_color = new_color
	_update_visual()

func _update_visual() -> void:
	if sprite != null:
		sprite.modulate = effect_color
		sprite.scale = effect_size / 32.0

func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	if follow_target:
		global_position = target.global_position
