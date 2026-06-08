extends CharacterBody2D

@export var move_speed := 150.0
@export var max_health := 5
@export var attack_interval := 0.75
@export var attack_range := 420.0
@export var pickup_range := 100.0
@export var bullet_damage_multiplier := 1.0
@export var bullet_count := 1
@export var experience_bonus_multiplier := 1.0
var shield_count := 0

var health := 5
var game: Node = null
var is_dead := false
var invincible_time := 0.0
var attack_cooldown := 0.0
var active_target: Node2D = null
var experience := 0
var level := 1
var is_leveling := false

const BULLET_SCENE := preload("res://scenes/game/bullet.tscn")

func _ready() -> void:
	health = max_health
	set_physics_process(true)
	set_process(true)
	call_deferred("_activate_camera")

func _activate_camera() -> void:
	var camera: Camera2D = $Camera2D
	if camera != null:
		camera.enabled = true
		camera.position = Vector2.ZERO
		camera.make_current()

func set_game(game_ref: Node) -> void:
	game = game_ref

func collect_experience(value: int) -> void:
	experience += value
	var leveled_up := _try_level_up()
	if leveled_up and game != null and game.has_method("_on_player_level_up"):
		game._on_player_level_up()
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func _try_level_up() -> bool:
	var leveled_up := false
	var required_experience := 25 * level
	while experience >= required_experience:
		experience -= required_experience
		level += 1
		leveled_up = true
		required_experience = 25 * level
	return leveled_up

func apply_reward_effect(reward_id: String) -> void:
	match reward_id:
		"bullet_damage":
			bullet_damage_multiplier += 0.5
		"pickup_range":
			pickup_range += 25.0
		"attack_speed":
			attack_interval = maxf(attack_interval * 0.5, 0.15)
		"bullet_count":
			bullet_count += 1
		"experience_bonus":
			experience_bonus_multiplier += 0.25
		"shield":
			shield_count += 1
		"freeze_chance":
			pass
		"burn_chance":
			pass
		"bounce_count":
			pass
		"knockback":
			pass

func has_shield() -> bool:
	return shield_count > 0

func consume_shield() -> bool:
	if shield_count <= 0:
		return false
	shield_count -= 1
	return true

func take_damage(amount: int) -> void:
	if is_dead or invincible_time > 0.0:
		return
	if has_shield():
		consume_shield()
		invincible_time = 0.4
		modulate = Color(0.7, 0.9, 1.0, 1.0)
		if game != null and game.has_method("_update_hud"):
			game._update_hud()
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
	if game.get_nearest_enemy(global_position, attack_range) == null:
		return
	_fire_bullet_sequence()
	attack_cooldown = attack_interval

func _fire_bullet_sequence() -> void:
	var shots: int = max(1, bullet_count)
	var attack_gap := attack_interval / 5.0
	for i in range(shots):
		_fire_bullet_after_delay(float(i) * attack_gap)

func _fire_bullet_after_delay(delay_seconds: float) -> void:
	if delay_seconds <= 0.0:
		_spawn_bullet_now()
		return
	var timer := get_tree().create_timer(delay_seconds)
	await timer.timeout
	_spawn_bullet_now()

func _spawn_bullet_now() -> void:
	if game == null or not game.has_method("get_nearest_enemy"):
		return
	var candidate: Node2D = game.get_nearest_enemy(global_position, attack_range)
	if candidate == null:
		return
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.damage = int(10 * bullet_damage_multiplier)
	bullet.set_owner_player(self)
	if bullet.has_method("set_status_modifiers"):
		bullet.set_status_modifiers(experience_bonus_multiplier, 0.0, 0.0, 0, false)
	if game != null:
		game.add_child(bullet)
	else:
		add_child(bullet)
	bullet.set_target(candidate)


func _process(delta: float) -> void:
	if is_dead:
		return
	if invincible_time > 0.0:
		invincible_time = maxf(invincible_time - delta, 0.0)
		if invincible_time <= 0.0:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
	if get_tree() != null and get_tree().paused:
		return
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if attack_cooldown <= 0.0 and not is_leveling:
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
	var camera: Camera2D = $Camera2D
	if camera != null and not camera.is_current():
		camera.make_current()
