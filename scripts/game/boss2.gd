extends "res://scripts/game/enemy_base.gd"

enum BossState { CHASE, CHARGE, LASER, IDLE, COOLDOWN }

var current_state := BossState.CHASE
var state_timer := 0.0
var locked_direction := Vector2.ZERO
var laser_lock_position := Vector2.ZERO
var charge_indicator: ColorRect = null
var normal_shape: Shape2D
var collision_node: CollisionShape2D
var lasers: Array[Node2D] = []

const CHASE_SPEED := 333.33
const CHARGE_RANGE := 250.0
const CHARGE_DURATION := 0.5
const LASER_DURATION := 15.0
const IDLE_DURATION := 0.5
const COOLDOWN_DURATION := 5.0
const PUSH_RADIUS := 50.0
const PUSH_FORCE := 80.0

const LASER_SLOW_SPEED := TAU / 15.0
const LASER_MID_SPEED := TAU / 10.0
const LASER_FAST_SPEED := TAU / 5.0

func _ready() -> void:
	max_health = 5000
	move_speed = 200.0
	experience_drop = 0
	touch_damage = 1
	touch_range = 26.67
	_setup_boss_animations()
	_setup_collision_shapes()
	_setup_charge_indicator()
	super._ready()

func _setup_boss_animations() -> void:
	_animated_sprite = AnimatedSprite2D.new()
	_animated_sprite.z_index = 5
	_animated_sprite.texture_filter = 0
	_animated_sprite.scale = Vector2(2.0, 2.0)
	var sf := SpriteFrames.new()
	sf.add_animation("idle_walk")
	sf.set_animation_loop("idle_walk", true)
	sf.set_animation_speed("idle_walk", 10.0)
	var iw_tex := load("res://assets/sprites/bosses/alarm_idle_walk-Sheet.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = iw_tex
	for i in range(15):
		atlas.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("idle_walk", atlas.duplicate())
	sf.add_animation("skill")
	sf.set_animation_loop("skill", true)
	sf.set_animation_speed("skill", 10.0)
	var sk_tex := load("res://assets/sprites/bosses/alarm_skill-Sheet.png")
	var sk_atlas := AtlasTexture.new()
	sk_atlas.atlas = sk_tex
	for i in range(4):
		sk_atlas.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("skill", sk_atlas.duplicate())
	_animated_sprite.sprite_frames = sf
	_animated_sprite.play("idle_walk")
	add_child(_animated_sprite)

func _setup_collision_shapes() -> void:
	collision_node = $CollisionShape2D
	normal_shape = CircleShape2D.new()
	normal_shape.radius = 32.0
	if collision_node != null:
		collision_node.shape = normal_shape

func _setup_charge_indicator() -> void:
	charge_indicator = ColorRect.new()
	charge_indicator.color = Color(1, 0, 0, 0.3)
	charge_indicator.size = Vector2(64, 250)
	charge_indicator.visible = false
	add_child(charge_indicator)

func apply_freeze(_duration: float) -> void:
	pass

func apply_burn(_duration: float, _damage_per_tick: int = 1) -> void:
	pass

func apply_knockback(_from_position: Vector2, _force: float) -> void:
	pass

func _apply_visual() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		_cleanup_effects()
		return

	_update_status_effects(delta)
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)

	match current_state:
		BossState.CHASE:
			_process_chase(delta)
		BossState.CHARGE:
			_process_charge(delta)
		BossState.LASER:
			_process_laser(delta)
		BossState.IDLE:
			_process_idle(delta)
		BossState.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	_push_nearby_enemies()
	_check_touch_damage()

func _play_idle_walk() -> void:
	if _animated_sprite != null and _animated_sprite.animation != "idle_walk":
		_animated_sprite.play("idle_walk")

func _play_skill() -> void:
	if _animated_sprite != null and _animated_sprite.animation != "skill":
		_animated_sprite.play("skill")

func _process_chase(delta: float) -> void:
	move_speed = CHASE_SPEED
	_play_idle_walk()
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	if global_position.distance_to(target.global_position) <= CHARGE_RANGE:
		_enter_charge_state()

func _enter_charge_state() -> void:
	current_state = BossState.CHARGE
	state_timer = CHARGE_DURATION
	velocity = Vector2.ZERO
	move_speed = 0.0
	if target != null and is_instance_valid(target):
		locked_direction = global_position.direction_to(target.global_position)
	_play_skill()

func _process_charge(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_laser_state()

func _enter_laser_state() -> void:
	current_state = BossState.LASER
	state_timer = LASER_DURATION
	velocity = Vector2.ZERO
	move_speed = 0.0
	laser_lock_position = global_position
	_play_skill()
	_spawn_lasers()

func _process_laser(delta: float) -> void:
	state_timer -= delta
	global_position = laser_lock_position
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		_enter_idle_state()

func _enter_idle_state() -> void:
	current_state = BossState.IDLE
	state_timer = IDLE_DURATION
	velocity = Vector2.ZERO
	move_speed = 0.0
	_play_idle_walk()
	_destroy_lasers()

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_cooldown_state()

func _enter_cooldown_state() -> void:
	current_state = BossState.COOLDOWN
	state_timer = COOLDOWN_DURATION

func _process_cooldown(delta: float) -> void:
	state_timer -= delta
	move_speed = 200.0
	_play_idle_walk()
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	if state_timer <= 0.0:
		current_state = BossState.CHASE

func _spawn_lasers() -> void:
	var laser_scene := preload("res://scenes/game/boss_laser.tscn")
	var speeds := [LASER_SLOW_SPEED, LASER_MID_SPEED, LASER_FAST_SPEED]
	var base_angle := 0.0
	if target != null and is_instance_valid(target):
		base_angle = global_position.direction_to(target.global_position).angle() - PI / 2
	for i in range(3):
		var laser := laser_scene.instantiate()
		laser.rotation_speed = speeds[i]
		laser.global_position = global_position
		laser.rotation = base_angle
		get_parent().add_child(laser)
		lasers.append(laser)

func _destroy_lasers() -> void:
	for laser in lasers:
		if is_instance_valid(laser):
			laser.queue_free()
	lasers.clear()

func _push_nearby_enemies() -> void:
	var game_node := get_tree().current_scene
	if game_node == null:
		return
	var move_dir := velocity.normalized()
	if move_dir == Vector2.ZERO:
		return
	var perp_dir := Vector2(-move_dir.y, move_dir.x)
	for enemy in game_node.spawned_enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue
		if enemy.is_in_group("boss"):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < PUSH_RADIUS and dist > 0.01:
			var to_enemy := global_position.direction_to(enemy.global_position)
			var cross := move_dir.cross(to_enemy)
			var side := perp_dir if cross >= 0.0 else -perp_dir
			var push_strength := PUSH_FORCE * (1.0 - dist / PUSH_RADIUS)
			enemy.global_position += side * push_strength

func _show_charge_indicator() -> void:
	if charge_indicator == null:
		return
	charge_indicator.visible = true
	_update_charge_indicator()

func _update_charge_indicator() -> void:
	if charge_indicator == null:
		return
	var indicator_length := 250.0
	var indicator_width := 64.0
	charge_indicator.size = Vector2(indicator_width, indicator_length)
	charge_indicator.pivot_offset = Vector2(indicator_width / 2, indicator_length)
	charge_indicator.rotation = locked_direction.angle() + PI / 2
	charge_indicator.position = Vector2(-indicator_width / 2, -indicator_length)

func _hide_charge_indicator() -> void:
	if charge_indicator != null:
		charge_indicator.visible = false

func _check_touch_damage() -> void:
	if target == null or not is_instance_valid(target):
		return
	var target_dashing: bool = target.is_dashing if target.has_method("get") and "is_dashing" in target else false
	if target_dashing:
		return
	if target.has_method("take_damage"):
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			if collision != null and collision.get_collider() == target:
				target.take_damage(touch_damage)
				return
	if global_position.distance_to(target.global_position) <= touch_range and target.has_method("take_damage"):
		target.take_damage(touch_damage)

func _cleanup_effects() -> void:
	if freeze_effect_instance != null and is_instance_valid(freeze_effect_instance):
		freeze_effect_instance.queue_free()
		freeze_effect_instance = null
	if burn_effect_instance != null and is_instance_valid(burn_effect_instance):
		burn_effect_instance.queue_free()
		burn_effect_instance = null
	_hide_charge_indicator()
	_destroy_lasers()

func _update_status_effects(_delta: float) -> void:
	pass
