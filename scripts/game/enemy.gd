extends CharacterBody2D

@export var move_speed := 100.0
@export var touch_damage := 1
@export var touch_range := 18.0

var target: Node2D

func set_target(target_node: Node2D) -> void:
	target = target_node

func _physics_process(delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()
	if target.has_method("take_damage"):
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			if collision != null and collision.get_collider() == target:
				target.take_damage(touch_damage)
				return
	if global_position.distance_to(target.global_position) <= touch_range and target.has_method("take_damage"):
		target.take_damage(touch_damage)
