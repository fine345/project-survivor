extends Node

const BULLET_SCENE := preload("res://scenes/game/player_bullet.tscn")

@export var attack_cooldown := 0.75
@export var bullet_speed := 300.0
@export var bullet_damage := 10

var cooldown_left := 0.0
var owner_player: CharacterBody2D
var current_target: Node2D

func setup(player: CharacterBody2D) -> void:
	owner_player = player

func set_target(target: Node2D) -> void:
	current_target = target

func can_attack() -> bool:
	return cooldown_left <= 0.0 and owner_player != null and is_instance_valid(owner_player) and current_target != null and is_instance_valid(current_target)

func _process(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("attack"):
		try_attack()

func try_attack() -> bool:
	if not can_attack():
		return false
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = owner_player.global_position
	bullet.setup(owner_player.global_position.direction_to(current_target.global_position), bullet_speed, bullet_damage, owner_player)
	owner_player.get_parent().add_child(bullet)
	cooldown_left = attack_cooldown
	return true

func get_state_label() -> String:
	return "READY" if cooldown_left <= 0.0 else "COOLDOWN"
