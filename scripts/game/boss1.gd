extends "res://scripts/game/enemy_base.gd"

enum BossState { CHASE, CHARGE, DASH, IDLE, COOLDOWN }

var current_state := BossState.CHASE
var state_timer := 0.0
var dash_direction := Vector2.ZERO
var locked_direction := Vector2.ZERO
var charge_indicator: ColorRect = null
var normal_shape: Shape2D
var dash_shape: Shape2D
var collision_node: CollisionShape2D
var _anim_timer := 0.0

const CHASE_SPEED := 400.0
const CHARGE_RANGE := 200.0
const CHARGE_DURATION := 0.75
const DASH_SPEED := 800.0
const DASH_DURATION := 0.5
const IDLE_DURATION := 0.2
const COOLDOWN_DURATION := 2.0
const PUSH_RADIUS := 50.0
const PUSH_FORCE := 80.0
const READY_DURATION := 0.6
const DONE_DURATION := 0.6

func _ready() -> void:
	max_health = 2000
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
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 1.0)
	sf.add_frame("idle", load("res://assets/sprites/bosses/stapler_32x32_idle-Sheet.png"))
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 5.0)
	var walk_tex = load("res://assets/sprites/bosses/stapler_32x32_walk-Sheet.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = walk_tex
	for i in range(4):
		atlas.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("walk", atlas.duplicate())
	sf.add_animation("ready")
	sf.set_animation_loop("ready", false)
	sf.set_animation_speed("ready", 5.0)
	var ready_tex = load("res://assets/sprites/bosses/stapler_32x32_ready-Sheet.png")
	var ready_atlas := AtlasTexture.new()
	ready_atlas.atlas = ready_tex
	for i in range(3):
		ready_atlas.region = Rect2(i * 32, 0, 32, 48)
		sf.add_frame("ready", ready_atlas.duplicate())
	sf.add_animation("dash")
	sf.set_animation_loop("dash", false)
	sf.set_animation_speed("dash", 1.0)
	sf.add_frame("dash", load("res://assets/sprites/bosses/stapler_32x32_dash-Sheet.png"))
	sf.add_animation("done")
	sf.set_animation_loop("done", false)
	sf.set_animation_speed("done", 5.0)
	var done_tex = load("res://assets/sprites/bosses/stapler_32x32_done-Sheet.png")
	var done_atlas := AtlasTexture.new()
	done_atlas.atlas = done_tex
	for i in range(3):
		done_atlas.region = Rect2(i * 32, 0, 32, 48)
		sf.add_frame("done", done_atlas.duplicate())
	_animated_sprite.sprite_frames = sf
	_animated_sprite.play("idle")
	add_child(_animated_sprite)

func _setup_collision_shapes() -> void:
	collision_node = $CollisionShape2D
	normal_shape = CircleShape2D.new()
	normal_shape.radius = 32.0
	dash_shape = CapsuleShape2D.new()
	dash_shape.radius = 32.0
	dash_shape.height = 96.0
	if collision_node != null:
		collision_node.shape = normal_shape

func _setup_charge_indicator() -> void:
	charge_indicator = ColorRect.new()
	charge_indicator.color = Color(1, 0, 0, 0.3)
	charge_indicator.size = Vector2(64, 400)
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
		BossState.DASH:
			_process_dash(delta)
		BossState.IDLE:
			_process_idle(delta)
		BossState.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	_push_nearby_enemies()
	_check_touch_damage()

func _process_chase(delta: float) -> void:
	move_speed = CHASE_SPEED
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		_play_move_anim()
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	_play_move_anim()
	if global_position.distance_to(target.global_position) <= CHARGE_RANGE:
		_enter_charge_state()

func _enter_charge_state() -> void:
	current_state = BossState.CHARGE
	state_timer = CHARGE_DURATION
	_anim_timer = READY_DURATION
	velocity = Vector2.ZERO
	move_speed = 0.0
	if target != null and is_instance_valid(target):
		locked_direction = global_position.direction_to(target.global_position)
	_switch_to_skill_shape()
	_show_charge_indicator()
	if _animated_sprite != null:
		_animated_sprite.play("ready")

func _process_charge(delta: float) -> void:
	state_timer -= delta
	_anim_timer -= delta
	if charge_indicator != null:
		_update_charge_indicator()
	_apply_skill_visual()
	if _anim_timer <= 0.0 and current_state == BossState.CHARGE:
		if _animated_sprite != null:
			_animated_sprite.play("dash")
	if state_timer <= 0.0:
		_enter_dash_state()

func _enter_dash_state() -> void:
	current_state = BossState.DASH
	state_timer = DASH_DURATION
	dash_direction = locked_direction
	velocity = dash_direction * DASH_SPEED
	move_speed = DASH_SPEED
	_hide_charge_indicator()
	if _animated_sprite != null:
		_animated_sprite.play("dash")

func _process_dash(delta: float) -> void:
	state_timer -= delta
	_apply_skill_visual()
	if state_timer <= 0.0:
		_enter_idle_state()

func _enter_idle_state() -> void:
	current_state = BossState.IDLE
	state_timer = IDLE_DURATION
	_anim_timer = DONE_DURATION
	velocity = Vector2.ZERO
	move_speed = 0.0
	if _animated_sprite != null:
		_animated_sprite.play("done")

func _process_idle(delta: float) -> void:
	state_timer -= delta
	_anim_timer -= delta
	if state_timer <= 0.0:
		_enter_cooldown_state()

func _enter_cooldown_state() -> void:
	current_state = BossState.COOLDOWN
	state_timer = COOLDOWN_DURATION
	_switch_to_normal_shape()
	_switch_to_normal_shape()

func _process_cooldown(delta: float) -> void:
	state_timer -= delta
	move_speed = 200.0
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		_play_move_anim()
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	_play_move_anim()
	if state_timer <= 0.0:
		current_state = BossState.CHASE

func _play_move_anim() -> void:
	if _animated_sprite == null:
		return
	if velocity != Vector2.ZERO:
		if _animated_sprite.animation != "walk":
			_animated_sprite.play("walk")
		_animated_sprite.flip_h = velocity.x < 0.0
		_animated_sprite.rotation = 0.0
	else:
		if _animated_sprite.animation != "idle":
			_animated_sprite.play("idle")
		if target != null and is_instance_valid(target):
			_animated_sprite.flip_h = target.global_position.x < global_position.x
		_animated_sprite.rotation = 0.0

func _apply_skill_visual() -> void:
	var angle: float = locked_direction.angle()
	if locked_direction.x < 0.0:
		angle += PI
	if collision_node != null:
		collision_node.rotation = angle
	if _animated_sprite != null:
		_animated_sprite.rotation = angle
		_animated_sprite.flip_h = locked_direction.x < 0.0

func _switch_to_skill_shape() -> void:
	var angle: float = locked_direction.angle()
	if locked_direction.x < 0.0:
		angle += PI
	if collision_node != null:
		collision_node.shape = dash_shape
		collision_node.rotation = angle
	if _animated_sprite != null:
		_animated_sprite.rotation = angle
		_animated_sprite.flip_h = locked_direction.x < 0.0

func _switch_to_normal_shape() -> void:
	if collision_node != null:
		collision_node.shape = normal_shape
		collision_node.rotation = 0.0
	if _animated_sprite != null:
		_animated_sprite.rotation = 0.0

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
	var indicator_length := 400.0
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

func _update_status_effects(_delta: float) -> void:
	pass
