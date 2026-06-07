extends CharacterBody2D

@export var move_speed := 150.0
@export var max_health := 5

var health := 5
var game: Node = null
var is_dead := false
var invincible_time := 0.0

func _ready() -> void:
	health = max_health
	set_physics_process(true)
	set_process(true)

func set_game(game_ref: Node) -> void:
	game = game_ref

func take_damage(amount: int) -> void:
	if is_dead or invincible_time > 0.0:
		return
	health = max(health - amount, 0)
	invincible_time = 0.4
	modulate = Color(1.0, 0.6, 0.6, 1.0)
	if health <= 0:
		is_dead = true
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	if game != null and game.has_method("_update_hud"):
		game._update_hud()

func _process(delta: float) -> void:
	if is_dead:
		return
	if invincible_time > 0.0:
		invincible_time = maxf(invincible_time - delta, 0.0)
		if invincible_time <= 0.0:
			modulate = Color(1.0, 1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = direction.normalized() * move_speed if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
