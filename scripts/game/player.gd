extends CharacterBody2D

@export var move_speed := 150.0
@export var max_health := 5
@export var attack_interval := 0.75
@export var attack_range := 420.0
@export var pickup_range := 100.0

var health := 5
var game: Node = null
var is_dead := false
var invincible_time := 0.0
var attack_cooldown := 0.0
var active_target: Node2D = null
var experience := 0
var level := 1

const BULLET_SCENE := preload("res://scenes/game/bullet.tscn")

func _ready() -> void:
	health = max_health
	set_physics_process(true)
	set_process(true)

func set_game(game_ref: Node) -> void:
	game = game_ref

func collect_experience(value: int) -> void:
	experience += value
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func take_damage(amount: int) -> void:
	if is_dead or invincible_time > 0.0:
		return
	health = max(health - amount, 0)
	invincible_time = 0.4
	modulate = Color(1.0, 0.6, 0.6, 1.0)
	if health <= 0:
		is_dead = true
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func _try_auto_attack() -> void:
	if game == null or not game.has_method("get_nearest_enemy"):
		return
	var candidate: Node2D = game.get_nearest_enemy(global_position, attack_range)
	if candidate == null:
		return
	active_target = candidate
	_fire_bullet(active_target)
	attack_cooldown = attack_interval

func _fire_bullet(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.set_target(target)
	bullet.set_owner_player(self)
	if game != null:
		game.add_child(bullet)
	else:
		add_child(bullet)

func _process(delta: float) -> void:
	if is_dead:
		return
	if invincible_time > 0.0:
		invincible_time = maxf(invincible_time - delta, 0.0)
		if invincible_time <= 0.0:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if attack_cooldown <= 0.0:
		_try_auto_attack()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = direction.normalized() * move_speed if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
