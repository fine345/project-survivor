extends Area2D

@export var move_speed := 300.0
@export var damage := 10
@export var lifetime := 2.0
@export var turn_speed := 10.0

var target: Node2D
var owner_player: Node = null
var current_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func set_target(target_node: Node2D) -> void:
	target = target_node
	if target != null and is_instance_valid(target):
		current_velocity = global_position.direction_to(target.global_position) * move_speed
		if current_velocity == Vector2.ZERO:
			current_velocity = Vector2.RIGHT * move_speed
		rotation = current_velocity.angle()

func set_owner_player(owner_node: Node) -> void:
	owner_player = owner_node

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var desired_direction := global_position.direction_to(target.global_position)
	if desired_direction == Vector2.ZERO:
		desired_direction = current_velocity.normalized() if current_velocity != Vector2.ZERO else Vector2.RIGHT
	var desired_velocity := desired_direction.normalized() * move_speed
	current_velocity = current_velocity.lerp(desired_velocity, clamp(turn_speed * delta, 0.0, 1.0))
	global_position += current_velocity * delta
	rotation = current_velocity.angle()

func _on_body_entered(body: Node) -> void:
	if body == owner_player:
		return
	if body != null and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
