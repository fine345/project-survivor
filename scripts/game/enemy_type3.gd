extends "res://scripts/game/enemy_base.gd"

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 350.0
const ATTACK_DELAY := 0.8

var shoot_timer := 0.0
var _attack_timer := 0.0
var _pending_shot := false

func _ready() -> void:
	var dm = get_node_or_null("/root/DifficultyManager")
	var mult: float = dm.get_enemy_health_multiplier() if dm != null else 1.0
	max_health = int(50 * mult)
	move_speed = 200.0
	experience_drop = 25
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	_update_hurt_timer(delta)
	if _pending_shot:
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_fire_bullet()
			_pending_shot = false
		_face_target()
		_check_touch()
		return
	if target != null and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= SHOOT_RANGE:
			velocity = Vector2.ZERO
			_face_target()
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				_start_attack()
				shoot_timer = SHOOT_INTERVAL
			_check_touch()
			return
	super._physics_process(delta)
	_face_target()

func _update_hurt_timer(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	elif _animated_sprite != null and _animated_sprite.animation == "hurt":
		_animated_sprite.play("idle" if velocity == Vector2.ZERO else "walk")

func _check_touch() -> void:
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

func _face_target() -> void:
	if _animated_sprite == null or target == null or not is_instance_valid(target):
		return
	_animated_sprite.flip_h = target.global_position.x < global_position.x

func _apply_visual() -> void:
	_setup_animations(
		"res://assets/sprites/enemies/enemy_3_idle-Sheet.png",
		"res://assets/sprites/enemies/enemy_3_walk-Sheet.png",
		"res://assets/sprites/enemies/enemy_3_hurt-Sheet.png",
		5.0, 10.0,
		{"attack": {"path": "res://assets/sprites/enemies/enemy_3_attack_95-Sheet.png", "frames": 5, "fps": 5.0}}
	)

func _start_attack() -> void:
	_pending_shot = true
	_attack_timer = ATTACK_DELAY
	if _animated_sprite != null:
		_animated_sprite.play("attack")
		_face_target()

func take_damage(amount: int, color: Color = Color.WHITE, source_pos: Vector2 = Vector2.INF) -> void:
	var was_attacking: bool = _pending_shot
	super.take_damage(amount, color, source_pos)
	if is_dead and was_attacking:
		var rm = get_node_or_null("/root/RecordManager")
		if rm != null:
			rm.increment_achievement_stat("ranged_interrupts")

func _fire_bullet() -> void:
	if target == null or not is_instance_valid(target):
		return
	var bullet_scene := preload("res://scenes/game/enemy_bullet.tscn")
	var bullet := bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.set_meta("initial_direction", global_position.direction_to(target.global_position))
	bullet.set_meta("use_sprite", true)
	get_tree().current_scene.add_child(bullet)
