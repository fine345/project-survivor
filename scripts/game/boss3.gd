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
var visual_node: Panel
var normal_shape: RectangleShape2D
var saved_alpha := 1.0

const CHASE_SPEED := 150.0
const SKILL1_RANGE := 300.0
const SKILL2_RANGE := 300.0
const COOLDOWN_DURATION := 3.0
const PUSH_RADIUS := 50.0
const PUSH_FORCE := 80.0

func _ready() -> void:
	max_health = 10000
	move_speed = 150.0
	experience_drop = 0
	touch_damage = 1
	touch_range = 20.0
	super._ready()
	_setup_collision()

func _setup_collision() -> void:
	collision_node = $CollisionShape2D
	normal_shape = RectangleShape2D.new()
	normal_shape.size = Vector2(38, 38)
	if collision_node != null:
		collision_node.shape = normal_shape

func apply_freeze(_duration: float) -> void:
	pass

func apply_burn(_duration: float, _damage_per_tick: int = 1) -> void:
	pass

func apply_knockback(_from_position: Vector2, _force: float) -> void:
	pass

func _apply_visual() -> void:
	visual_node = $Visual
	if visual_node == null:
		return
	var style: StyleBoxFlat = visual_node.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = Color(0.9, 0.4, 0.1, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		_cleanup_effects()
		return

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
	_push_nearby_enemies()
	_check_touch_damage()

func _process_chase(_delta: float) -> void:
	move_speed = CHASE_SPEED
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

func _process_skill1_warn(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		if target != null and is_instance_valid(target):
			lock_position = target.global_position
		_show_circle_warning(lock_position, 50.0)
		current_state = BossState.SKILL1_UP
		state_timer = 0.6

func _process_skill1_up(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	global_position += Vector2(0, -75.0 / 0.6) * delta
	if state_timer <= 0.0:
		_set_collision_enabled(false)
		_set_visual_alpha(0.5)
		current_state = BossState.SKILL1_DOWN
		state_timer = 0.1

func _process_skill1_down(delta: float) -> void:
	state_timer -= delta
	velocity = Vector2.ZERO
	if state_timer > 0.05:
		global_position = lock_position + Vector2(0, -75)
	else:
		global_position = global_position.move_toward(lock_position, 600.0 * delta)
	if state_timer <= 0.0:
		global_position = lock_position
		_set_collision_enabled(true)
		_set_visual_alpha(1.0)
		_hide_warning()
		_damage_in_range(lock_position, 50.0)
		_push_at_position(lock_position, 50.0)
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
	move_speed = 300.0

func _process_skill2_approach(_delta: float) -> void:
	move_speed = 300.0
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
	_show_circle_warning(global_position, 150.0)

func _process_skill2_warn1(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_hide_warning()
		_spawn_rotating_laser()
		current_state = BossState.SKILL2_LASER1
		state_timer = 0.5

func _process_skill2_laser1(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = BossState.SKILL2_DASH
		state_timer = 0.5
		if target != null and is_instance_valid(target):
			locked_direction = global_position.direction_to(target.global_position)

func _process_skill2_dash(delta: float) -> void:
	state_timer -= delta
	if target != null and is_instance_valid(target):
		velocity = locked_direction * 500.0
	else:
		velocity = Vector2.ZERO
	if state_timer <= 0.0:
		velocity = Vector2.ZERO
		lock_position = global_position
		current_state = BossState.SKILL2_WARN2
		state_timer = 0.5
		_show_rect_warning(300.0, 75.0)

func _process_skill2_warn2(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_hide_warning()
		_spawn_rect_laser()
		current_state = BossState.SKILL2_LASER2
		state_timer = 0.3

func _process_skill2_laser2(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_idle()

func _enter_idle() -> void:
	current_state = BossState.IDLE
	state_timer = 0.2
	velocity = Vector2.ZERO
	move_speed = 0.0

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
	var dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		dir = global_position.direction_to(target.global_position)
	_warning.global_position = global_position
	_warning.rotation = dir.angle()
	_warning_position = global_position
	_warning_rotation = dir.angle()
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
	shape.size = Vector2(150, 12)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(75, 0)
	laser.add_child(collision)
	var vis := ColorRect.new()
	vis.color = Color(1, 0.2, 0.2, 0.8)
	vis.size = Vector2(150, 12)
	vis.position = Vector2(0, -6)
	laser.add_child(vis)
	var angle := 0.0
	if target != null and is_instance_valid(target):
		angle = global_position.direction_to(target.global_position).angle() + PI
	laser.rotation = angle
	laser.set_meta("rotation_speed", TAU / 0.3)
	laser.set_meta("lifetime", 0.3)
	get_parent().add_child(laser)

func _spawn_rect_laser() -> void:
	var laser_scene := preload("res://scenes/game/boss3_laser.tscn")
	var laser := laser_scene.instantiate()
	laser.global_position = _warning_position
	laser.rotation = _warning_rotation
	var shape := RectangleShape2D.new()
	shape.size = Vector2(300, 75)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(150, 0)
	laser.add_child(collision)
	var vis := ColorRect.new()
	vis.color = Color(1, 0.2, 0.2, 0.8)
	vis.size = Vector2(300, 75)
	vis.position = Vector2(0, -37.5)
	laser.add_child(vis)
	get_parent().add_child(laser)

func _set_collision_enabled(enabled: bool) -> void:
	if collision_node != null:
		collision_node.set_deferred("disabled", not enabled)

func _set_visual_alpha(alpha: float) -> void:
	if visual_node != null:
		visual_node.modulate.a = alpha

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
			enemy.global_position += push_dir * 60.0
	if target != null and is_instance_valid(target):
		var dist := pos.distance_to(target.global_position)
		if dist < radius:
			var push_angle := randf() * TAU
			var push_dir := Vector2(cos(push_angle), sin(push_angle))
			target.global_position += push_dir * 40.0

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

func _update_status_effects(_delta: float) -> void:
	pass
