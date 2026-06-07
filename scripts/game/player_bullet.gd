extends Area2D

var move_direction := Vector2.UP
var move_speed := 300.0
var damage := 10
var owner_player: CharacterBody2D

func setup(direction: Vector2, speed: float, bullet_damage: int, owner: CharacterBody2D) -> void:
	move_direction = direction.normalized()
	move_speed = speed
	damage = bullet_damage
	owner_player = owner
	rotation = move_direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += move_direction * move_speed * delta

func _on_body_entered(body: Node) -> void:
	if body == owner_player:
		return
	if body != null and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area != null and area != owner_player:
		queue_free()
