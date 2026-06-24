extends "res://scripts/game/enemy_base.gd"

enum BossState {
	CHASE,
	SKILL1_WARN, SKILL1_UP, SKILL1_DOWN,
	SKILL2_APPROACH, SKILL2_WARN1, SKILL2_LASER1, SKILL2_DASH, SKILL2_WARN2, SKILL2_LASER2,
	IDLE, COOLDOWN
}

var current_state := BossState.CHASE
var state_timer := 0.0
var locked_direction := Vector2.ZERO
var lock_position := Vector2.ZERO
var collision_node: CollisionShape2D
var normal_shape: Shape2D
var _cap_sprite: AnimatedSprite2D
var _tassel_sprite: AnimatedSprite2D
var _tassel_pivot: Node2D
var _active_laser: Node2D = null

const CHASE_SPEED := 200.0
const SKILL1_RANGE := 400.0
const SKILL2_RANGE := 400.0
const COOLDOWN_DURATION := 3.0
const PUSH_RADIUS := 50.0
const PUSH_FORCE := 80.0

func _ready() -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	var mult: float = dm.get_boss_health_multiplier() if dm != null else 1.0
	max_health = int(10000 * mult)
	move_speed = 200.0
	experience_drop = 0
	touch_damage = 1
	touch_range = 26.67
	_setup_boss_animations()
	_setup_collision()
	super._ready()

func _setup_boss_animations() -> void:
	_cap_sprite = $Cap
	_cap_sprite.scale = Vector2(2.0, 2.0)
	var cap_sf := SpriteFrames.new()
	cap_sf.add_animation("default")
	cap_sf.set_animation_loop("default", true)
	cap_sf.set_animation_speed("default", 1.0)
	cap_sf.add_frame("default", load("res://assets/sprites/bosses/cap-Sheet.png"))
	_cap_sprite.sprite_frames = cap_sf
	_cap_sprite.play("default")
	_tassel_pivot = Node2D.new()
	_tassel_pivot.name = "TasselPivot"
	add_child(_tassel_pivot)
	_tassel_sprite = AnimatedSprite2D.new()
	_tassel_sprite.name = "Tassel"
	_tassel_sprite.z_index = 10
	_tassel_sprite.texture_filter = 0
	_tassel_sprite.scale = Vector2(2.0, 2.0)
	_tassel_pivot.add_child(_tassel_sprite)
	var tsf := SpriteFrames.new()
	tsf.add_animation("idle")
	tsf.set_animation_loop("idle", true)
	tsf.set_animation_speed("idle", 1.0)
	tsf.add_frame("idle", load("res://assets/sprites/bosses/tassel_idle-Sheet.png"))
	tsf.add_animation("walk_right")
	tsf.set_animation_loop("walk_right", true)
	tsf.set_animation_speed("walk_right", 5.0)
	var wr_tex := load("res://assets/sprites/bosses/tassel_walk_right-Sheet.png")
	var wr_atlas := AtlasTexture.new()
	wr_atlas.atlas = wr_tex
	for i in range(6):
		wr_atlas.region = Rect2(i * 36, 0, 36, 26)
		tsf.add_frame("walk_right", wr_atlas.duplicate())
	tsf.add_animation("walk_left")
	tsf.set_animation_loop("walk_left", true)
	tsf.set_animation_speed("walk_left", 5.0)
	var wl_tex := load("res://assets/sprites/bosses/tassel_walk_left-Sheet.png")
	var wl_atlas := AtlasTexture.new()
	wl_atlas.atlas = wl_tex
	for i in range(6):
		wl_atlas.region = Rect2(i * 36, 0, 36, 26)
		tsf.add_frame("walk_left", wl_atlas.duplicate())
	tsf.add_animation("skill1_up")
	tsf.set_animation_loop("skill1_up", false)
	tsf.set_animation_speed("skill1_up", 1.0)
	tsf.add_frame("skill1_up", load("res://assets/sprites/bosses/tassel_skill1_up-Sheet.png"))
	tsf.add_animation("skill1_down")
	tsf.set_animation_loop("skill1_down", false)
	tsf.set_animation_speed("skill1_down", 1.0)
	tsf.add_frame("skill1_down", load("res://assets/sprites/bosses/tassel_skill1_down-Sheet.png"))
	tsf.add_animation("skill2_warn1")
	tsf.set_animation_loop("skill2_warn1", false)
	tsf.set_animation_speed("skill2_warn1", 10.0)
	var sw1_tex := load("res://assets/sprites/bosses/tassel_skill2_warn1-Sheet.png")
	var sw1_atlas := AtlasTexture.new()
	sw1_atlas.atlas = sw1_tex
	for i in range(5):
		sw1_atlas.region = Rect2(i * 40, 0, 40, 40)
		tsf.add_frame("skill2_warn1", sw1_atlas.duplicate())
	tsf.add_animation("skill2_laser1")
	tsf.set_animation_loop("skill2_laser1", false)
	tsf.set_animation_speed("skill2_laser1", 1.0)
	tsf.add_frame("skill2_laser1", load("res://assets/sprites/bosses/tassel_skill2_laser1-Sheet.png"))
	tsf.add_animation("skill2_warn2")
	tsf.set_animation_loop("skill2_warn2", false)
	tsf.set_animation_speed("skill2_warn2", 10.0)
	var sw2_tex := load("res://assets/sprites/bosses/tassel_skill2_warn2-Sheet.png")
	var sw2_atlas := AtlasTexture.new()
	sw2_atlas.atlas = sw2_tex
	for i in range(5):
		sw2_atlas.region = Rect2(i * 68, 0, 68, 36)
		tsf.add_frame("skill2_warn2", sw2_atlas.duplicate())
	tsf.add_animation("skill2_laser2")
	tsf.set_animation_loop("skill2_laser2", false)
	tsf.set_animation_speed("skill2_laser2", 1.0)
	tsf.add_frame("skill2_laser2", load("res://assets/sprites/bosses/tassel_skill2_laser2-Sheet.png"))
	_tassel_sprite.sprite_frames = tsf
	_tassel_sprite.play("idle")

func _setup_collision() -> void:
	collision_node = $CollisionShape2D
	normal_shape = CapsuleShape2D.new()
	normal_shape.radius = 13.0
	normal_shape.height = 36.0
	if collision_node != null:
		collision_node.shape = normal_shape

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

	match current_state:
		BossState.CHASE:
			_process_chase(delta)
		BossState.SKILL1_WARN:
			_process_skill1_warn(delta)
		BossState.SKILL1_UP:
			_process_skill1_up(delta)
		BossState.SKILL1_DOWN:
			_process_skill1_down(delta)
		BossState.SKILL2_APPROACH:
			_process_skill2_approach(delta)
		BossState.SKILL2_WARN1:
			_process_skill2_warn1(delta)
		BossState.SKILL2_LASER1:
			_process_skill2_laser1(delta)
		BossState.SKILL2_DASH:
			_process_skill2_dash(delta)
		BossState.SKILL2_WARN2:
			_process_skill2_warn2(delta)
		BossState.SKILL2_LASER2:
			_process_skill2_laser2(delta)
		BossState.IDLE:
			_process_idle(delta)
		BossState.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	if current_state in [BossState.SKILL1_WARN, BossState.SKILL2_WARN1, BossState.SKILL2_WARN2, BossState.SKILL2_LASER1, BossState.SKILL2_LASER2, BossState.IDLE]:
		global_position = lock_position
		velocity = Vector2.ZERO
		_tassel_pivot.global_position = global_position
	if current_state == BossState.SKILL2_LASER1 and _active_laser != null and is_instance_valid(_active_laser):
		_tassel_pivot.rotation = _active_laser.rotation
	_push_nearby_enemies()
	_check_touch_damage()

func _play_walk() -> void:
	if _tassel_sprite == null:
		return
	_tassel_pivot.position = Vector2.ZERO
	_tassel_pivot.rotation = 0.0
	_tassel_sprite.centered = true
	_tassel_sprite.position = Vector2.ZERO
	if velocity.x >= 0.0:
		if _tassel_sprite.animation != "walk_right":
			_tassel_sprite.play("walk_right")
	else:
		if _tassel_sprite.animation != "walk_left":
			_tassel_sprite.play("walk_left")

func _play_idle() -> void:
	if _tassel_sprite != null and _tassel_sprite.animation != "idle":
		_tassel_sprite.play("idle")
	if _tassel_pivot != null:
		_tassel_pivot.position = Vector2.ZERO
		_tassel_pivot.rotation = 0.0
	if _tassel_sprite != null:
		_tassel_sprite.centered = true
		_tassel_sprite.position = Vector2.ZERO

func _play_tassel_anim(anim_name: String) -> void:
	if _tassel_sprite != null and _tassel_sprite.animation != anim_name:
		_tassel_sprite.play(anim_name)
		if anim_name not in ["skill2_laser1", "skill2_laser2"]:
			_tassel_sprite.centered = true
			_tassel_sprite.position = Vector2.ZERO

func _set_tassel_pivot(pos: Vector2, angle: float, sprite_offset: Vector2 = Vector2.INF) -> void:
	_tassel_pivot.global_position = pos
	_tassel_pivot.rotation = angle
	if sprite_offset == Vector2.INF:
		_tassel_sprite.centered = true
		_tassel_sprite.position = Vector2.ZERO
	else:
		_tassel_sprite.centered = false
		_tassel_sprite.position = sprite_offset

func _process_chase(_delta: float) -> void:
	move_speed = CHASE_SPEED
	_play_walk()
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= SKILL2_RANGE:
		_enter_skill2()
	else:
		_enter_skill1()

func _enter_skill1() -> void:
	current_state = BossState.SKILL1_WARN
	state_timer = 0.1
	velocity = Vector2.ZERO
	move_speed = 0.0
	lock_position = global_position
	_play_idle()

func _process_skill1_warn(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		if target != null and is_instance_valid(target):
			lock_position = target.global_position
		_show_circle_warning(lock_position, 66.67)
		current_state = BossState.SKILL1_UP
		state_timer = 0.6
		_play_tassel_anim("skill1_up")

func _process_skill1_up(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	global_position += Vector2(0, -100.0 / 0.6) * delta
	if state_timer <= 0.0:
		_set_collision_enabled(false)
		_set_visual_alpha(0.5)
		current_state = BossState.SKILL1_DOWN
		state_timer = 0.1
		_play_tassel_anim("skill1_down")

func _process_skill1_down(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer > 0.05:
		global_position = lock_position + Vector2(0, -100)
	else:
		global_position = global_position.move_toward(lock_position, 800.0 * delta)
	if state_timer <= 0.0:
		global_position = lock_position
		_set_collision_enabled(true)
		_set_visual_alpha(1.0)
		_hide_warning()
		_damage_in_range(lock_position, 66.67)
		_push_at_position(lock_position, 66.67)
		_enter_idle()

func _damage_in_range(pos: Vector2, radius: float) -> void:
	var game_node := get_tree().current_scene
	if game_node == null:
		return
	if game_node.player != null and is_instance_valid(game_node.player):
		if pos.distance_to(game_node.player.global_position) <= radius:
			game_node.player.take_damage(touch_damage)

func _enter_skill2() -> void:
	current_state = BossState.SKILL2_APPROACH
	move_speed = 400.0

func _process_skill2_approach(_delta: float) -> void:
	move_speed = 400.0
	_play_walk()
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= 100.0:
		_enter_skill2_warn1()
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed

func _enter_skill2_warn1() -> void:
	current_state = BossState.SKILL2_WARN1
	state_timer = 0.5
	velocity = Vector2.ZERO
	move_speed = 0.0
	lock_position = global_position
	if target != null and is_instance_valid(target):
		locked_direction = global_position.direction_to(target.global_position)
	_play_tassel_anim("skill2_warn1")
	_tassel_sprite.centered = true
	_tassel_sprite.offset = Vector2.ZERO
	_set_tassel_pivot(lock_position, locked_direction.angle() - PI / 2)
	_show_circle_warning(global_position, 200.0)

func _process_skill2_warn1(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_hide_warning()
		_spawn_rotating_laser()
		current_state = BossState.SKILL2_LASER1
		state_timer = 0.5
		_play_tassel_anim("skill2_laser1")
		_set_tassel_pivot(lock_position, locked_direction.angle(), Vector2(0, -3))

func _process_skill2_laser1(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = BossState.SKILL2_DASH
		state_timer = 0.5
		if target != null and is_instance_valid(target):
			locked_direction = global_position.direction_to(target.global_position)

func _process_skill2_dash(delta: float) -> void:
	state_timer -= delta
	_play_walk()
	if target != null and is_instance_valid(target):
		velocity = locked_direction * 666.67
	else:
		velocity = Vector2.ZERO
	if state_timer <= 0.0:
		velocity = Vector2.ZERO
		lock_position = global_position
		current_state = BossState.SKILL2_WARN2
		state_timer = 0.5
		_play_tassel_anim("skill2_warn2")
		_set_tassel_pivot(lock_position, locked_direction.angle())
		_show_rect_warning(400.0, 100.0)

func _process_skill2_warn2(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_hide_warning()
		_spawn_rect_laser()
		current_state = BossState.SKILL2_LASER2
		state_timer = 0.3
		_play_tassel_anim("skill2_laser2")
		_set_tassel_pivot(lock_position, locked_direction.angle(), Vector2(0, -50))

func _process_skill2_laser2(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_idle()

func _enter_idle() -> void:
	current_state = BossState.IDLE
	state_timer = 0.2
	velocity = Vector2.ZERO
	move_speed = 0.0
	_play_idle()

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_cooldown()

func _enter_cooldown() -> void:
	current_state = BossState.COOLDOWN
	state_timer = COOLDOWN_DURATION

func _process_cooldown(delta: float) -> void:
	state_timer -= delta
	move_speed = CHASE_SPEED
	_play_walk()
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	if state_timer <= 0.0:
		current_state = BossState.CHASE

var _warning: Node2D = null
var _warning_position := Vector2.ZERO
var _warning_rotation := 0.0

func _show_circle_warning(pos: Vector2, radius: float) -> void:
	_hide_warning()
	_warning = Node2D.new()
	_warning.name = "WarningCircle"
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 32
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon.polygon = points
	polygon.color = Color(1, 0, 0, 0.3)
	_warning.add_child(polygon)
	_warning.global_position = pos
	get_parent().add_child(_warning)

func _show_rect_warning(width: float, height: float) -> void:
	_hide_warning()
	_warning = Node2D.new()
	_warning.name = "WarningRect"
	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.3)
	rect.size = Vector2(width, height)
	rect.position = Vector2(0, -height / 2)
	_warning.add_child(rect)
	_warning.global_position = global_position
	_warning.rotation = locked_direction.angle()
	_warning_position = global_position
	_warning_rotation = locked_direction.angle()
	get_parent().add_child(_warning)

func _hide_warning() -> void:
	if _warning != null and is_instance_valid(_warning):
		_warning.queue_free()
		_warning = null

func _spawn_rotating_laser() -> void:
	var laser_scene := preload("res://scenes/game/boss3_laser.tscn")
	var laser := laser_scene.instantiate()
	laser.global_position = global_position
	var shape := RectangleShape2D.new()
	shape.size = Vector2(200, 16)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(100, 0)
	laser.add_child(collision)
	var vis := ColorRect.new()
	vis.color = Color(1, 0.2, 0.2, 0.8)
	vis.size = Vector2(200, 16)
	vis.position = Vector2(0, -8)
	laser.add_child(vis)
	laser.rotation = locked_direction.angle() + PI
	laser.set_meta("rotation_speed", -TAU / 0.3)
	laser.set_meta("lifetime", 0.3)
	_active_laser = laser
	get_parent().add_child(laser)

func _spawn_rect_laser() -> void:
	var laser_scene := preload("res://scenes/game/boss3_laser.tscn")
	var laser := laser_scene.instantiate()
	laser.global_position = _warning_position
	laser.rotation = _warning_rotation
	var shape := RectangleShape2D.new()
	shape.size = Vector2(400, 100)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(200, 0)
	laser.add_child(collision)
	var vis := ColorRect.new()
	vis.color = Color(1, 0.2, 0.2, 0.8)
	vis.size = Vector2(400, 100)
	vis.position = Vector2(0, -50)
	laser.add_child(vis)
	get_parent().add_child(laser)

func _set_collision_enabled(enabled: bool) -> void:
	if collision_node != null:
		collision_node.set_deferred("disabled", not enabled)

func _set_visual_alpha(alpha: float) -> void:
	_cap_sprite.modulate.a = alpha
	_tassel_sprite.modulate.a = alpha

func _push_at_position(pos: Vector2, radius: float) -> void:
	var game_node := get_tree().current_scene
	if game_node == null:
		return
	for enemy in game_node.spawned_enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue
		var dist := pos.distance_to(enemy.global_position)
		if dist < radius and dist > 0.01:
			var push_dir := pos.direction_to(enemy.global_position)
			enemy.global_position += push_dir * 80.0
	if target != null and is_instance_valid(target):
		var dist := pos.distance_to(target.global_position)
		if dist < radius:
			var push_angle := randf() * TAU
			var push_dir := Vector2(cos(push_angle), sin(push_angle))
			target.global_position += push_dir * 53.33

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
	_hide_warning()
	_set_collision_enabled(true)
	_set_visual_alpha(1.0)
	_active_laser = null

func _update_status_effects(_delta: float) -> void:
	pass
