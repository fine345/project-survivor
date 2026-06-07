extends Area2D

@export var pickup_value := 5
@export var attract_range := 140.0
@export var attract_speed := 260.0

var attracted_target: Node2D = null

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func set_attracted_target(target: Node2D) -> void:
	attracted_target = target

func _physics_process(delta: float) -> void:
	if attracted_target == null or not is_instance_valid(attracted_target):
		return
	var distance := global_position.distance_to(attracted_target.global_position)
	if distance > attract_range:
		return
	var direction := global_position.direction_to(attracted_target.global_position)
	global_position += direction * attract_speed * delta

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("collect_experience"):
		return
	body.collect_experience(pickup_value)
	queue_free()
