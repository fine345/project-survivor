extends Area2D

@export var rotation_speed := 1.0
@export var laser_damage := 1
@export var laser_length := 1200.0
@export var laser_width := 12.0

func _ready() -> void:
	add_to_group("boss_laser")
	body_entered.connect(_on_body_entered)
	_setup_visual()
	_setup_collision()

func _setup_visual() -> void:
	var visual: ColorRect = ColorRect.new()
	visual.color = Color(1, 0.2, 0.2, 0.8)
	visual.position = Vector2(0, -laser_width / 2)
	visual.size = Vector2(laser_length, laser_width)
	add_child(visual)

func _setup_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(laser_length, laser_width)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(laser_length / 2, 0)
	add_child(collision)

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return
	if body.is_in_group("enemy"):
		return
	body.take_damage(laser_damage)
