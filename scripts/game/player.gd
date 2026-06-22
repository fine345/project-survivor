extends CharacterBody2D

@export var move_speed := 220.0
@export var max_health := 5
@export var attack_interval := 0.75
@export var attack_range := 252.0
@export var pickup_range := 100.0
@export var bullet_damage_multiplier := 1.0
@export var bullet_count := 1
@export var experience_bonus_multiplier := 1.0
var bullet_bounce_count := 0
var bullet_knockback_enabled := false
var bullet_freeze_chance := 0.0
var bullet_burn_chance := 0.0
var bullet_speed_multiplier := 1.0
var shield_count := 0
var shield_effect_instance: Node2D = null

var ruler_weapon_unlocked := false
var orbit_ruler_count := 2
var ruler_damage_multiplier := 1.0
var ruler_orbit_radius := 100.0
var ruler_collision_radius := 25.0
var ruler_speed_multiplier := 1.0
var _ruler_instances: Array[Node2D] = []

var calculator_unlocked := false
var laser_width_multiplier := 1.0
var laser_damage_multiplier := 1.0
var laser_count := 1
var _laser_cooldown := 0.0
var _laser_frequency_count := 0
var _calculator: Node2D = null
var _calculator_reward_count := 0

const RULER_SCENE := preload("res://scenes/weapon/ruler.tscn")
const CALCULATOR_BEAM_SCENE := preload("res://scenes/weapon/calculator_beam.tscn")
const CALCULATOR_SCENE := preload("res://scenes/weapon/calculator.tscn")

var health := 5
var game: Node = null
var is_dead := false
var invincible_time := 0.0
var attack_cooldown := 0.0
var active_target: Node2D = null
var experience := 0
var level := 1
var is_leveling := false
var total_damage_taken := 0

var dash_cooldown := 0.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var is_dashing := false
var _dash_cooldown_bar: ColorRect = null
const DASH_DISTANCE := 140.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 1.0

const BULLET_SCENE := preload("res://scenes/game/bullet.tscn")

var _animated_sprite: AnimatedSprite2D
var _facing_right := true
var _pre_dash_visual := "idle"
var _hurt_timer := 0.0
var _darken_timer := 0.0
const HURT_DISPLAY_TIME := 0.2
const DARKEN_DURATION := 0.8

func _ready() -> void:
	health = max_health
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown = 0.0
	var col: CollisionShape2D = $CollisionShape2D
	if col != null:
		col.disabled = false
	_dash_cooldown_bar = get_node_or_null("DashCooldownBar")
	_animated_sprite = $AnimatedSprite2D
	_setup_animations()
	set_physics_process(true)
	set_process(true)
	call_deferred("_activate_camera")
	call_deferred("_connect_joystick")

func _setup_animations() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 1.0)
	var idle_tex = load("res://assets/sprites/player/player_idle-Sheet.png")
	sf.add_frame("idle", idle_tex)
	sf.add_animation("walk")
	sf.set_animation_loop("walk", true)
	sf.set_animation_speed("walk", 10.0)
	var walk_tex = load("res://assets/sprites/player/player_walk-Sheet.png")
	var walk_atlas = AtlasTexture.new()
	walk_atlas.atlas = walk_tex
	for i in range(8):
		walk_atlas.region = Rect2(i * 14, 0, 14, 24)
		sf.add_frame("walk", walk_atlas.duplicate())
	sf.add_animation("hurt")
	sf.set_animation_loop("hurt", false)
	sf.set_animation_speed("hurt", 1.0)
	var hurt_tex = load("res://assets/sprites/player/player_hurt-Sheet.png")
	sf.add_frame("hurt", hurt_tex)
	sf.add_animation("dash_front")
	sf.set_animation_loop("dash_front", false)
	sf.set_animation_speed("dash_front", 1.0)
	sf.add_frame("dash_front", load("res://assets/sprites/player/player_dash_front-Sheet.png"))
	sf.add_animation("dash_up30")
	sf.set_animation_loop("dash_up30", false)
	sf.set_animation_speed("dash_up30", 1.0)
	sf.add_frame("dash_up30", load("res://assets/sprites/player/player_dash_up30-Sheet.png"))
	sf.add_animation("dash_down30")
	sf.set_animation_loop("dash_down30", false)
	sf.set_animation_speed("dash_down30", 1.0)
	sf.add_frame("dash_down30", load("res://assets/sprites/player/player_dash_down30-Sheet.png"))
	sf.add_animation("dash_up60")
	sf.set_animation_loop("dash_up60", false)
	sf.set_animation_speed("dash_up60", 1.0)
	sf.add_frame("dash_up60", load("res://assets/sprites/player/player_dash_up60-Sheet.png"))
	sf.add_animation("dash_down60")
	sf.set_animation_loop("dash_down60", false)
	sf.set_animation_speed("dash_down60", 1.0)
	sf.add_frame("dash_down60", load("res://assets/sprites/player/player_dash_down60-Sheet.png"))
	_animated_sprite.sprite_frames = sf
	_animated_sprite.play("idle")

func _activate_camera() -> void:
	var camera: Camera2D = $Camera2D
	if camera != null:
		camera.enabled = true
		camera.position = Vector2(0, 100)
		camera.make_current()

func _update_visuals() -> void:
	if _animated_sprite == null:
		return
	if is_dashing:
		_update_dash_visual()
		return
	if _hurt_timer > 0.0:
		return
	if velocity != Vector2.ZERO:
		if _animated_sprite.animation != "walk":
			_animated_sprite.play("walk")
		_facing_right = velocity.x >= 0.0
		_animated_sprite.flip_h = not _facing_right
	else:
		if _animated_sprite.animation != "idle":
			_animated_sprite.play("idle")

func _update_dash_visual() -> void:
	var angle_rad: float = dash_direction.angle()
	var deg: float = fmod(rad_to_deg(angle_rad) + 360.0, 360.0)
	var anim_name: String
	var mirror: bool
	if deg < 15.0 or deg >= 345.0:
		anim_name = "dash_front"
		mirror = false
	elif deg < 45.0:
		anim_name = "dash_down30"
		mirror = false
	elif deg < 90.0:
		anim_name = "dash_down60"
		mirror = false
	elif deg < 135.0:
		anim_name = "dash_down60"
		mirror = true
	elif deg < 165.0:
		anim_name = "dash_down30"
		mirror = true
	elif deg < 195.0:
		anim_name = "dash_front"
		mirror = true
	elif deg < 225.0:
		anim_name = "dash_up30"
		mirror = true
	elif deg < 270.0:
		anim_name = "dash_up60"
		mirror = true
	elif deg < 315.0:
		anim_name = "dash_up60"
		mirror = false
	else:
		anim_name = "dash_up30"
		mirror = false
	if _animated_sprite.animation != anim_name:
		_animated_sprite.play(anim_name)
	_animated_sprite.flip_h = mirror

func _connect_joystick() -> void:
	var joy := get_tree().get_first_node_in_group("virtual_joystick")
	if joy == null:
		joy = get_node_or_null("/root/Main/HUD/VirtualJoystick")
	if joy != null and joy.has_signal("joystick_released"):
		joy.joystick_released.connect(_on_joystick_released)

func _on_joystick_released(direction: Vector2) -> void:
	if is_dead or is_dashing or dash_cooldown > 0.0:
		return
	dash_direction = direction
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	is_dashing = true
	var col: CollisionShape2D = $CollisionShape2D
	if col != null:
		col.disabled = true

func set_game(game_ref: Node) -> void:
	game = game_ref

func collect_experience(value: int) -> void:
	var effective_value: int = int(round(float(value) * experience_bonus_multiplier))
	experience += effective_value
	var leveled_up := _try_level_up()
	if leveled_up and game != null and game.has_method("_on_player_level_up"):
		game._on_player_level_up()
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func _try_level_up() -> bool:
	var leveled_up := false
	var required_experience := _get_required_exp()
	while experience >= required_experience:
		experience -= required_experience
		level += 1
		leveled_up = true
		required_experience = _get_required_exp()
	return leveled_up

func _get_required_exp() -> int:
	if level <= 20:
		return 25 * level
	else:
		return 15 * level + 200

func level_up_reward(levels: int = 1) -> void:
	for i in range(levels):
		var required := _get_required_exp()
		var xp_ratio := float(experience) / float(required) if required > 0 else 0.0
		level += 1
		var new_required := mini(25 * level, 500)
		experience = int(xp_ratio * new_required)
	if game != null and game.has_method("_on_player_level_up"):
		game._on_player_level_up()

func apply_reward_effect(reward_id: String) -> void:
	match reward_id:
		"bullet_damage":
			bullet_damage_multiplier += 0.3
		"pickup_range":
			pickup_range *= 1.75
		"attack_speed":
			attack_interval = maxf(attack_interval * 0.5, 0.15)
		"bullet_count":
			bullet_count += 1
		"bounce_count":
			bullet_bounce_count += 1
		"experience_bonus":
			experience_bonus_multiplier += 0.5
		"knockback":
			bullet_knockback_enabled = true
		"ruler_weapon":
			ruler_weapon_unlocked = true
			orbit_ruler_count = 2
			_rebuild_rulers()
		"ruler_count":
			orbit_ruler_count += 2
			_rebuild_rulers()
		"ruler_damage":
			ruler_damage_multiplier += 0.5
			_update_ruler_params()
		"ruler_radius":
			ruler_orbit_radius *= 1.25
			ruler_collision_radius *= 1.25
			_update_ruler_params()
		"ruler_speed":
			ruler_speed_multiplier += 0.5
			_update_ruler_params()
		"calculator_weapon":
			calculator_unlocked = true
			laser_count = 1
			_laser_cooldown = 2.0
			_calculator_reward_count = 1
			laser_width_multiplier = 15.0
			_spawn_calculator()
		"laser_damage":
			laser_damage_multiplier += 0.5
			_calculator_reward_count += 1
			laser_width_multiplier = 15.0 + (_calculator_reward_count - 1) * 3.0
		"laser_count":
			laser_count = mini(laser_count + 1, 5)
			_calculator_reward_count += 1
			laser_width_multiplier = 15.0 + (_calculator_reward_count - 1) * 3.0
		"laser_frequency":
			_laser_frequency_count += 1
			_calculator_reward_count += 1
			laser_width_multiplier = 15.0 + (_calculator_reward_count - 1) * 3.0
		"attack_range":
			attack_range *= 1.5
		"bullet_speed":
			bullet_speed_multiplier += 0.5
		"shield":
			shield_count += 1
			if shield_effect_instance == null or not is_instance_valid(shield_effect_instance):
				var effect_scene: PackedScene = preload("res://scenes/effect/shield_effect.tscn")
				shield_effect_instance = effect_scene.instantiate() as Node2D
				add_child(shield_effect_instance)
			if shield_effect_instance.has_method("set_target"):
				shield_effect_instance.set_target(self)
			if shield_effect_instance.has_method("set_effect_size"):
				shield_effect_instance.set_effect_size(Vector2(36, 36))
			if shield_effect_instance.has_method("set_effect_lifetime"):
				shield_effect_instance.set_effect_lifetime(9999.0)
		"freeze_chance":
			bullet_freeze_chance = minf(bullet_freeze_chance + 0.25, 1.0)
		"burn_chance":
			bullet_burn_chance = minf(bullet_burn_chance + 0.25, 1.0)
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
	if is_dead or invincible_time > 0.0 or is_dashing:
		return
	if has_shield():
		consume_shield()
		invincible_time = 1.0
		modulate = Color(0.7, 0.9, 1.0, 1.0)
		_apply_damage_knockback()
		if shield_count <= 0:
			_apply_shield_break_knockback()
			if shield_effect_instance != null and is_instance_valid(shield_effect_instance):
				shield_effect_instance.queue_free()
				shield_effect_instance = null
		if game != null and game.has_method("_update_hud"):
			game._update_hud()
		return
	health = max(health - amount, 0)
	total_damage_taken += amount
	invincible_time = 1.0
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _animated_sprite != null:
		_animated_sprite.play("hurt")
	_hurt_timer = HURT_DISPLAY_TIME
	_darken_timer = 0.0
	_apply_damage_knockback()
	if health <= 0:
		is_dead = true
		if _animated_sprite != null:
			_animated_sprite.stop()
			_animated_sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func _apply_damage_knockback() -> void:
	_apply_knockback_area(40.0, 3.0)

func _apply_shield_break_knockback() -> void:
	_apply_knockback_area(40.0, 3.0)

func _apply_knockback_area(radius: float, force: float) -> void:
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return
	var shape = CircleShape2D.new()
	shape.radius = radius
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.exclude = [self]
	var hits = space_state.intersect_shape(params, 32)
	for hit in hits:
		var collider = hit.get("collider")
		if collider == null or not is_instance_valid(collider):
			continue
		if collider.has_method("apply_knockback"):
			collider.apply_knockback(global_position, force)

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
		_spawn_bullet_now(0)
		return
	var timer := get_tree().create_timer(delay_seconds)
	await timer.timeout
	_spawn_bullet_now(1)

func _spawn_bullet_now(bullet_index: int) -> void:
	if game == null or not game.has_method("get_nearest_enemy"):
		return
	var candidate: Node2D = game.get_nearest_enemy(global_position, attack_range)
	if candidate == null:
		return
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.damage = int(round(10 * bullet_damage_multiplier * (0.5 if bullet_index > 0 else 1.0)))
	bullet.set_owner_player(self)
	if bullet.has_method("set_status_modifiers"):
		bullet.set_status_modifiers(experience_bonus_multiplier, bullet_freeze_chance, bullet_burn_chance, bullet_bounce_count, bullet_knockback_enabled)
	if bullet.has_method("set_status_effect_multiplier"):
		bullet.set_status_effect_multiplier(1.0)
	if bullet.has_method("set_shot_effect_multiplier"):
		bullet.set_shot_effect_multiplier(0.5 if bullet_index > 0 else 1.0)
	if bullet.has_method("set_speed_multiplier"):
		bullet.set_speed_multiplier(bullet_speed_multiplier)
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
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
		if _hurt_timer <= 0.0:
			_darken_timer = DARKEN_DURATION
	if _darken_timer > 0.0:
		_darken_timer = maxf(_darken_timer - delta, 0.0)
		if not is_dead and _animated_sprite != null:
			_animated_sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
		if _darken_timer <= 0.0:
			if _animated_sprite != null:
				_animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if get_tree() != null and get_tree().paused:
		return
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if attack_cooldown <= 0.0 and not is_leveling and not is_dashing:
		_try_auto_attack()
	if calculator_unlocked and not is_leveling and not is_dashing:
		_laser_cooldown = maxf(_laser_cooldown - delta, 0.0)
		if _laser_cooldown <= 0.0:
			_fire_calculator_beam()
			_laser_cooldown = 3.0 * pow(0.5, _laser_frequency_count)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	if dash_cooldown > 0.0:
		dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	if _dash_cooldown_bar != null:
		_dash_cooldown_bar.visible = dash_cooldown > 0.0
		if dash_cooldown > 0.0:
			var ratio := dash_cooldown / DASH_COOLDOWN
			_dash_cooldown_bar.offset_right = lerpf(-12.0, 12.0, ratio)
	if dash_timer > 0.0:
		dash_timer = maxf(dash_timer - delta, 0.0)
		var dash_speed := DASH_DISTANCE / DASH_DURATION
		velocity = dash_direction * dash_speed
		position += velocity * delta
		if dash_timer <= 0.0:
			is_dashing = false
			collision_layer = 1
			collision_mask = 2
			var col: CollisionShape2D = $CollisionShape2D
			if col != null:
				col.disabled = false
		_update_visuals()
		return
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = direction.normalized() * move_speed if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	_update_visuals()
	var camera: Camera2D = $Camera2D
	if camera != null and not camera.is_current():
		camera.make_current()

func _rebuild_rulers() -> void:
	for r in _ruler_instances:
		if is_instance_valid(r):
			r.queue_free()
	_ruler_instances.clear()
	if not ruler_weapon_unlocked:
		return
	for i in range(orbit_ruler_count):
		var ruler: Area2D = RULER_SCENE.instantiate() as Area2D
		ruler.setup(self, i, orbit_ruler_count)
		ruler.set_params(8 * ruler_damage_multiplier, ruler_orbit_radius, ruler_collision_radius, PI * ruler_speed_multiplier)
		if game != null:
			game.add_child(ruler)
		else:
			add_child(ruler)
		_ruler_instances.append(ruler)

func _update_ruler_params() -> void:
	for i in range(_ruler_instances.size()):
		var ruler: Area2D = _ruler_instances[i]
		if is_instance_valid(ruler):
			ruler.set_params(8 * ruler_damage_multiplier, ruler_orbit_radius, ruler_collision_radius, PI * ruler_speed_multiplier)
			ruler.angle_offset = (TAU / max(orbit_ruler_count, 1)) * i

func cleanup_rulers() -> void:
	for r in _ruler_instances:
		if is_instance_valid(r):
			r.queue_free()
	_ruler_instances.clear()

func _spawn_calculator() -> void:
	if _calculator != null and is_instance_valid(_calculator):
		_calculator.queue_free()
	_calculator = CALCULATOR_SCENE.instantiate()
	_calculator.setup(self)
	if game != null:
		game.add_child(_calculator)
	else:
		add_child(_calculator)

func _fire_calculator_beam() -> void:
	if game == null:
		return
	if _calculator == null or not is_instance_valid(_calculator):
		_spawn_calculator()
	_calculator.start_fire()
	var fire_pos: Vector2 = _calculator.get_fire_position()
	var base_direction := Vector2.RIGHT
	if game.has_method("get_nearest_enemy"):
		var nearest: Node2D = game.get_nearest_enemy(fire_pos, 9999.0)
		if nearest != null:
			base_direction = fire_pos.direction_to(nearest.global_position)
	var laser_damage: int = int(round(5 * laser_damage_multiplier))
	var laser_duration: float = 0.75
	var laser_width: float = laser_width_multiplier
	for i in range(laser_count):
		var angle_offset: float = 0.0
		if i > 0:
			var side: int = (i + 1) / 2
			angle_offset = deg_to_rad(7.0) * side * (-1 if i % 2 == 1 else 1)
		var dir: Vector2 = base_direction.rotated(angle_offset)
		var laser: Area2D = CALCULATOR_BEAM_SCENE.instantiate() as Area2D
		laser.global_position = fire_pos
		laser.setup(laser_damage, dir, laser_width, laser_duration, self)
		if game != null:
			game.add_child(laser)
		else:
			add_child(laser)
		var timer := get_tree().create_timer(laser_duration)
		timer.timeout.connect(func():
			if is_instance_valid(laser): laser.queue_free()
			if is_instance_valid(_calculator): _calculator.end_fire()
		)
