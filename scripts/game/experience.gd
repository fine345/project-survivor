extends Area2D

@export var pickup_value := 5

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("collect_experience"):
		return
	body.collect_experience(pickup_value)
	queue_free()
