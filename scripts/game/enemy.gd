extends CharacterBody2D

@export var move_speed := 100.0
@export var touch_damage := 1
@export var touch_range := 18.0
@export var max_health := 30
@export var experience_drop := 5
@export var enemy_type := 1

var target: Node2D
var game: Node = null
var health := 30
var is_dead := false
var freeze_timer := 0.0
var burn_timer := 0.0
var burn_tick_timer := 0.0
var burn_damage_per_tick := 1
var knockback_velocity := Vector2.ZERO

func _ready() -> void:
	_apply_enemy_type()
	health = max_health
	_apply_enemy_visual()

func _apply_enemy_visual() -> void:
	var visual: ColorRect = $Visual
	if visual == null:
		return
	match enemy_type:
		2:
			visual.color = Color(0.95, 0.55, 0.2, 1.0)
		_:
			visual.color = Color(0.9, 0.2, 0.3, 1.0)

func apply_freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)

func apply_burn(duration: float, damage_per_tick: int = 1) -> void:
	burn_timer = maxf(burn_timer, duration)
	burn_tick_timer = 0.0
	burn_damage_per_tick = damage_per_tick

func apply_knockback(from_position: Vector2, force: float) -> void:
	knockback_velocity = (global_position - from_position).normalized() * force

func _apply_enemy_type() -> void:
	match enemy_type:
		2:
			max_health = 50
			move_speed = 100.0
			experience_drop = 10
		_:
			max_health = 30
			move_speed = 100.0
			experience_drop = 5

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
	if freeze_timer > 0.0:
		freeze_timer = maxf(freeze_timer - delta, 0.0)
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, clamp(delta * 3.0, 0.0, 1.0))
		move_and_slide()
		return
	if burn_timer > 0.0:
		burn_timer = maxf(burn_timer - delta, 0.0)
		burn_tick_timer += delta
		if burn_tick_timer >= 1.0:
			burn_tick_timer -= 1.0
			take_damage(burn_damage_per_tick)
	if knockback_velocity.length() > 0.5:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, clamp(delta * 5.0, 0.0, 1.0))
		move_and_slide()
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
