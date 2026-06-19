extends CharacterBody2D

@export var move_speed := 200.0
@export var touch_damage := 1
@export var touch_range := 24.0
@export var max_health := 30
@export var experience_drop := 5

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
var stored_move_speed := 200.0

var _animated_sprite: AnimatedSprite2D = null
var _hurt_timer := 0.0
var _hurt_flip := false
const HURT_DISPLAY_TIME := 0.05

const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/damage_number.tscn")

func _ready() -> void:
	_apply_visual()
	health = max_health
	stored_move_speed = move_speed

func _apply_visual() -> void:
	pass

func _setup_animations(idle_path: String, walk_path: String, hurt_path: String, walk_fps: float = 5.0, hurt_fps: float = 10.0, extra_anims: Dictionary = {}) -> void:
	_animated_sprite = AnimatedSprite2D.new()
	_animated_sprite.z_index = 5
	_animated_sprite.texture_filter = 0
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 1.0)
	sf.add_frame("idle", load(idle_path))
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", walk_fps)
	var walk_tex = load(walk_path)
	var atlas = AtlasTexture.new()
	atlas.atlas = walk_tex
	for i in range(6):
		atlas.region = Rect2(i * 15, 0, 15, 15)
		sf.add_frame("walk", atlas.duplicate())
	sf.add_animation("hurt")
	sf.set_animation_loop("hurt", false)
	sf.set_animation_speed("hurt", hurt_fps)
	sf.add_frame("hurt", load(hurt_path))
	for anim_name in extra_anims:
		var anim_data: Dictionary = extra_anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, false)
		sf.set_animation_speed(anim_name, anim_data.get("fps", 10.0))
		var tex = load(anim_data["path"])
		var frame_count: int = anim_data.get("frames", 5)
		var frame_atlas = AtlasTexture.new()
		frame_atlas.atlas = tex
		for i in range(frame_count):
			frame_atlas.region = Rect2(i * 15, 0, 15, 15)
			sf.add_frame(anim_name, frame_atlas.duplicate())
	_animated_sprite.sprite_frames = sf
	_animated_sprite.scale = Vector2(2.0, 2.0)
	_animated_sprite.play("idle")
	add_child(_animated_sprite)

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

func apply_burn(_duration: float, _damage_per_tick: int = 1) -> void:
	burn_timer = maxf(burn_timer, 0.8)
	burn_tick_timer = 0.0
	burn_tick_accumulator = 0.0
	burn_ticks_remaining = 4
	burn_damage_per_tick = max(1, int(round(max_health * 0.1)))
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
		burn_effect_instance.set_effect_lifetime(0.8)
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

func set_game(game_ref: Node) -> void:
	game = game_ref

func set_target(target_node: Node2D) -> void:
	target = target_node

func take_damage(amount: int, color: Color = Color.WHITE, source_pos: Vector2 = Vector2.INF) -> void:
	if is_dead:
		return
	health = max(health - amount, 0)
	_spawn_damage_number(amount, color)
	if _animated_sprite != null and health > 0:
		_animated_sprite.play("hurt")
		_hurt_timer = HURT_DISPLAY_TIME
		_hurt_flip = source_pos != Vector2.INF and source_pos.x > global_position.x
		_animated_sprite.flip_h = _hurt_flip
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

	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	elif _animated_sprite != null:
		_animated_sprite.flip_h = false
		_animated_sprite.rotation = 0.0
		if velocity != Vector2.ZERO:
			if _animated_sprite.animation != "walk":
				_animated_sprite.play("walk")
		else:
			if _animated_sprite.animation != "idle":
				_animated_sprite.play("idle")

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
