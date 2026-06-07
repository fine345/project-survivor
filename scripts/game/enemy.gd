extends CharacterBody2D

@export var move_speed := 100.0
@export var touch_damage := 1
@export var touch_range := 18.0
@export var max_health := 30
@export var experience_drop := 5

var target: Node2D
var game: Node = null
var health := 30
var is_dead := false

func _ready() -> void:
	health = max_health

func set_game(game_ref: Node) -> void:
	game = game_ref

func set_target(target_node: Node2D) -> void:
	target = target_node

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = max(health - amount, 0)
	if health <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	if game != null and game.has_method("on_enemy_died"):
		game.on_enemy_died(self)
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	if target == null or not is_instance_valid(target):
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
