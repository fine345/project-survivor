extends Area2D

@export var pickup_value := 5
@export var attract_range := 180.0
@export var attract_speed := 520.0

var attracted_target: Node2D = null

func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)

func set_attracted_target(target: Node2D) -> void:
	attracted_target = target

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
	if body == null or not body.has_method("collect_experience"):
		return
	body.collect_experience(pickup_value)
	var sfx = get_node_or_null("/root/SFX")
	if sfx != null:
		sfx.play_pickup()
	queue_free()
