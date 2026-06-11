extends CharacterBody2D

@export var move_speed := 150.0
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
var burn_tick_interval := 0.2
var burn_tick_accumulator := 0.0
var burn_ticks_remaining := 0
var burn_effect_instance: Node2D = null
var freeze_effect_instance: Node2D = null
var knockback_timer := 0.0
var knockback_pause_timer := 0.0
var knockback_return_timer := 0.0
var knockback_direction := Vector2.ZERO
var knockback_distance_left := 0.0
var knockback_return_speed := 0.0
var stored_move_speed := 150.0

const DAMAGE_NUMBER_SCENE := preload("res://scenes/game/damage_number.tscn")

func _ready() -> void:
	_apply_enemy_type()
	health = max_health
	stored_move_speed = move_speed
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
	if freeze_effect_instance == null or not is_instance_valid(freeze_effect_instance):
		var effect_scene := preload("res://scenes/effect/freeze_effect.tscn")
		freeze_effect_instance = effect_scene.instantiate() as Node2D
		get_parent().add_child(freeze_effect_instance)
	if freeze_effect_instance.has_method("set_target"):
		freeze_effect_instance.set_target(self)
	if freeze_effect_instance.has_method("set_effect_color"):
		freeze_effect_instance.set_effect_color(Color(0, 0, 0, 0.35))
	if freeze_effect_instance.has_method("set_effect_size"):
		freeze_effect_instance.set_effect_size(Vector2(30, 30))
	if freeze_effect_instance.has_method("set_effect_lifetime"):
		freeze_effect_instance.set_effect_lifetime(duration)
	freeze_effect_instance.global_position = global_position

func apply_burn(duration: float, damage_per_tick: int = 1) -> void:
	burn_timer = maxf(burn_timer, duration)
	burn_tick_timer = 0.0
	burn_tick_accumulator = 0.0
	burn_ticks_remaining = 5
	burn_damage_per_tick = damage_per_tick
	if burn_effect_instance == null or not is_instance_valid(burn_effect_instance):
		var effect_scene := preload("res://scenes/effect/burn_effect.tscn")
		burn_effect_instance = effect_scene.instantiate() as Node2D
		get_parent().add_child(burn_effect_instance)
	if burn_effect_instance.has_method("set_target"):
		burn_effect_instance.set_target(self)
	if burn_effect_instance.has_method("set_effect_color"):
		burn_effect_instance.set_effect_color(Color(1, 0, 0, 0.45))
	if burn_effect_instance.has_method("set_effect_size"):
		burn_effect_instance.set_effect_size(Vector2(30, 30))
	if burn_effect_instance.has_method("set_effect_lifetime"):
		burn_effect_instance.set_effect_lifetime(duration)
	burn_effect_instance.global_position = global_position

func apply_knockback(from_position: Vector2, force: float) -> void:
	var direction: Vector2 = (global_position - from_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	knockback_direction = direction
	knockback_distance_left = 5.0 * maxf(force, 0.1)
	knockback_timer = 0.05
	knockback_return_timer = 0.1
	knockback_return_speed = stored_move_speed
	velocity = Vector2.ZERO
	move_speed = 0.0

func _apply_enemy_type() -> void:
	match enemy_type:
		2:
			max_health = 50
			move_speed = 150.0
			experience_drop = 10
		_:
			max_health = 30
			move_speed = 150.0
			experience_drop = 5

func set_game(game_ref: Node) -> void:
	game = game_ref

func set_target(target_node: Node2D) -> void:
	target = target_node

func take_damage(amount: int, color: Color = Color.WHITE) -> void:
	if is_dead:
		return
	health = max(health - amount, 0)
	_spawn_damage_number(amount, color)
	if health <= 0:
		_die()

func _spawn_damage_number(amount: int, color: Color) -> void:
	var number: Label = DAMAGE_NUMBER_SCENE.instantiate() as Label
	if number.has_method("setup"):
		number.setup(amount, color, global_position)
	get_parent().add_child(number)

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
		if freeze_effect_instance != null and is_instance_valid(freeze_effect_instance):
			freeze_effect_instance.queue_free()
			freeze_effect_instance = null
		if burn_effect_instance != null and is_instance_valid(burn_effect_instance):
			burn_effect_instance.queue_free()
			burn_effect_instance = null
		return

	if freeze_timer > 0.0:
		freeze_timer = maxf(freeze_timer - delta, 0.0)
	if burn_timer > 0.0:
		burn_timer = maxf(burn_timer - delta, 0.0)
		burn_tick_timer += delta
		while burn_tick_timer >= burn_tick_interval and burn_ticks_remaining > 0:
			burn_tick_timer -= burn_tick_interval
			burn_ticks_remaining -= 1
			take_damage(burn_damage_per_tick, Color(1, 0.3, 0.2))

	if knockback_timer > 0.0:
		knockback_timer = maxf(knockback_timer - delta, 0.0)
		var step_distance: float = minf(knockback_distance_left, 5.0 * delta / 0.05)
		global_position += knockback_direction * step_distance
		knockback_distance_left = maxf(knockback_distance_left - step_distance, 0.0)
		velocity = Vector2.ZERO
	else:
		if knockback_return_timer > 0.0:
			knockback_return_timer = maxf(knockback_return_timer - delta, 0.0)
			move_speed = knockback_return_speed
			velocity = knockback_direction * move_speed
		elif freeze_timer > 0.0:
			velocity = Vector2.ZERO
		else:
			if target == null or not is_instance_valid(target):
				velocity = Vector2.ZERO
				move_and_slide()
				return
			var direction := global_position.direction_to(target.global_position)
			velocity = direction * move_speed

	if freeze_effect_instance != null and is_instance_valid(freeze_effect_instance):
		freeze_effect_instance.global_position = global_position
	if burn_effect_instance != null and is_instance_valid(burn_effect_instance):
		burn_effect_instance.global_position = global_position

	move_and_slide()

	if knockback_timer > 0.0 or knockback_return_timer > 0.0 or freeze_timer > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			if collision != null and collision.get_collider() == target:
				target.take_damage(touch_damage)
				return
	if global_position.distance_to(target.global_position) <= touch_range and target.has_method("take_damage"):
		target.take_damage(touch_damage)
