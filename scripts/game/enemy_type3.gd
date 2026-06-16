extends "res://scripts/game/enemy_base.gd"

const SHOOT_INTERVAL := 2.0
const SHOOT_RANGE := 350.0

var shoot_timer := 0.0

func _ready() -> void:
	max_health = 50
	move_speed = 200.0
	experience_drop = 25
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if target != null and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= SHOOT_RANGE:
			velocity = Vector2.ZERO
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				_shoot()
				shoot_timer = SHOOT_INTERVAL
			return
	super._physics_process(delta)

func _apply_visual() -> void:
	var visual: Panel = $Visual
	if visual == null:
		return
	var style: StyleBoxFlat = visual.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = Color(0.2, 0.5, 0.9, 1.0)

func _shoot() -> void:
	var bullet_scene := preload("res://scenes/game/enemy_bullet.tscn")
	var bullet := bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.set_meta("initial_direction", global_position.direction_to(target.global_position))
	get_tree().current_scene.add_child(bullet)
