extends Area2D

@export var move_speed := 300.0
@export var damage := 1
@export var max_distance := 1000.0

var initial_direction := Vector2.RIGHT
var current_velocity := Vector2.ZERO
var travel_distance := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if has_meta("initial_direction"):
		initial_direction = (get_meta("initial_direction") as Vector2).normalized()
		if initial_direction == Vector2.ZERO:
			initial_direction = Vector2.RIGHT
	current_velocity = initial_direction * move_speed
	rotation = current_velocity.angle()

func _physics_process(delta: float) -> void:
	travel_distance += current_velocity.length() * delta
	if travel_distance >= max_distance:
		queue_free()
		return
	global_position += current_velocity * delta

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return
	if body.is_in_group("enemy"):
		return
	body.take_damage(damage)
	queue_free()
