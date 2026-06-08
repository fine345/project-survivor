extends Area2D

@export var move_speed := 300.0
@export var damage := 10
@export var lifetime := 5.0
@export var turn_speed := 10.0
@export var bounce_search_radius := 150.0

var target: Node2D
var owner_player: Node = null
var game: Node = null
var current_velocity: Vector2 = Vector2.ZERO
var initial_direction: Vector2 = Vector2.RIGHT
var experience_bonus_multiplier := 1.0
var freeze_chance := 0.0
var burn_chance := 0.0
var bounce_count := 0
var damage_multiplier := 1.0
var knockback_enabled := false
var knockback_force := 120.0
var spawned_at := 0.0
var spawn_delay := 0.0
var use_target_homing := true
var bounced_targets: Array[Node2D] = []
var already_bounced := 0
var pending_bounce_target: Node2D = null
var has_knockback_effect := false

const BULLET_SCENE := preload("res://scenes/game/bullet.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	spawned_at = Time.get_ticks_msec() / 1000.0
	if has_meta("spawn_delay"):
		spawn_delay = float(get_meta("spawn_delay"))
	if has_meta("initial_direction"):
		initial_direction = (get_meta("initial_direction") as Vector2).normalized()
		if initial_direction == Vector2.ZERO:
			initial_direction = Vector2.RIGHT
	use_target_homing = spawn_delay <= 0.0
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func set_target(target_node: Node2D) -> void:
	target = target_node
	if target != null and is_instance_valid(target):
		use_target_homing = true
		current_velocity = global_position.direction_to(target.global_position) * move_speed
		if current_velocity == Vector2.ZERO:
			current_velocity = Vector2.RIGHT * move_speed
		rotation = current_velocity.angle()
	else:
		use_target_homing = false
		current_velocity = initial_direction.normalized() * move_speed
		if current_velocity == Vector2.ZERO:
			current_velocity = Vector2.RIGHT * move_speed
		rotation = current_velocity.angle()

func set_owner_player(owner_node: Node) -> void:
	owner_player = owner_node
	if owner_node != null and owner_node.has_method("get"):
		game = owner_node.get("game")

func set_status_modifiers(exp_bonus: float, freeze_prob: float = 0.0, burn_prob: float = 0.0, bounce: int = 0, knockback: bool = false) -> void:
	experience_bonus_multiplier = exp_bonus
	freeze_chance = freeze_prob
	burn_chance = burn_prob
	bounce_count = bounce
	knockback_enabled = knockback
	has_knockback_effect = knockback

func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
	damage = int(round(damage * damage_multiplier))

func _physics_process(delta: float) -> void:
	var age: float = Time.get_ticks_msec() / 1000.0 - spawned_at
	if age >= lifetime:
		queue_free()
		return
	if spawn_delay > 0.0 and age < spawn_delay:
		return
	if use_target_homing and target != null and is_instance_valid(target):
		var desired_direction: Vector2 = global_position.direction_to(target.global_position)
		if desired_direction == Vector2.ZERO:
			desired_direction = current_velocity.normalized() if current_velocity != Vector2.ZERO else Vector2.RIGHT
		var desired_velocity: Vector2 = desired_direction.normalized() * move_speed
		current_velocity = current_velocity.lerp(desired_velocity, clamp(turn_speed * delta, 0.0, 1.0))
	else:
		if use_target_homing:
			use_target_homing = false
			if current_velocity != Vector2.ZERO:
				initial_direction = current_velocity.normalized()
			elif initial_direction == Vector2.ZERO:
				initial_direction = Vector2.RIGHT
		current_velocity = initial_direction.normalized() * move_speed
		if current_velocity == Vector2.ZERO:
			current_velocity = Vector2.RIGHT * move_speed
	global_position += current_velocity * delta
	rotation = current_velocity.angle()

func _on_body_entered(body: Node) -> void:
	if body == owner_player:
		return
	if body == null or not body.has_method("take_damage"):
		return
	if body is Node2D and bounced_targets.has(body):
		return
	var hit_force: float = knockback_force * (0.5 if already_bounced > 0 else 1.0)
	if body.has_method("apply_knockback") and knockback_enabled:
		body.apply_knockback(global_position, hit_force)
	if body.has_method("apply_freeze") and freeze_chance > 0.0 and randf() < freeze_chance:
		body.apply_freeze(2.0)
	if body.has_method("apply_burn") and burn_chance > 0.0 and randf() < burn_chance:
		body.apply_burn(5.0, 1)
	body.take_damage(damage)
	if body is Node2D:
		bounced_targets.append(body)
	if already_bounced >= bounce_count:
		queue_free()
		return
	var next_target: Node2D = _find_bounce_target(body)
	if next_target == null:
		queue_free()
		return
	already_bounced += 1
	pending_bounce_target = next_target
	_spawn_bounce_bullet()

func _find_bounce_target(from_enemy: Node2D) -> Node2D:
	if from_enemy == null or game == null:
		return null
	var nearest: Node2D = null
	var nearest_distance := bounce_search_radius
	for node in game.get_children():
		if node == null or node == from_enemy:
			continue
		if not (node is Node2D):
			continue
		if node == owner_player:
			continue
		if not node.has_method("take_damage"):
			continue
		if bounced_targets.has(node):
			continue
		var candidate := node as Node2D
		var distance := from_enemy.global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest

func _spawn_bounce_bullet() -> void:
	if game == null or pending_bounce_target == null:
		queue_free()
		return
	var bounced_bullet: Area2D = BULLET_SCENE.instantiate()
	bounced_bullet.global_position = global_position
	if bounced_bullet.has_method("set_owner_player"):
		bounced_bullet.set_owner_player(owner_player)
	if bounced_bullet.has_method("set_status_modifiers"):
		var remaining_bounces: int = maxi(bounce_count - already_bounced, 0)
		bounced_bullet.set_status_modifiers(experience_bonus_multiplier, freeze_chance, burn_chance, remaining_bounces, knockback_enabled)
	if bounced_bullet.has_method("set_damage_multiplier"):
		bounced_bullet.set_damage_multiplier(0.5)
	if bounced_bullet.has_method("set_bounce_state"):
		bounced_bullet.set_bounce_state(0, bounced_targets.duplicate())
	if bounced_bullet.has_method("set_knockback_state"):
		bounced_bullet.set_knockback_state(has_knockback_effect, knockback_force * 0.5)
	game.add_child(bounced_bullet)
	if bounced_bullet.has_method("set_target"):
		bounced_bullet.set_target(pending_bounce_target)
	pending_bounce_target = null
	queue_free()

func set_bounce_state(bounce_index: int, previous_targets: Array) -> void:
	already_bounced = bounce_index
	bounced_targets = previous_targets.duplicate()

func set_knockback_state(enabled: bool, force: float) -> void:
	has_knockback_effect = enabled
	knockback_force = force
