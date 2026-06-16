extends Area2D

@export var attract_range := 180.0
@export var attract_speed := 520.0

var attracted_target: Node2D = null
var reward_levels := 1

func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)

func set_attracted_target(target: Node2D) -> void:
	attracted_target = target

func set_reward_levels(levels: int) -> void:
	reward_levels = levels

func _physics_process(delta: float) -> void:
	if attracted_target == null or not is_instance_valid(attracted_target):
		return
	var current_pickup_range := 100.0
	if attracted_target.has_method("get"):
		current_pickup_range = float(attracted_target.get("pickup_range"))
	var distance: float = global_position.distance_to(attracted_target.global_position)
	if distance > current_pickup_range:
		return
	var direction: Vector2 = global_position.direction_to(attracted_target.global_position)
	global_position += direction * attract_speed * delta

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("level_up_reward"):
		return
	body.level_up_reward(reward_levels)
	queue_free()
