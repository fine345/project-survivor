extends Node2D

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
const ENEMY_SCENE := preload("res://scenes/game/enemy.tscn")
const EXPERIENCE_SCENE := preload("res://scenes/game/experience.tscn")

@export var enemy_spawn_interval := 1.5
@export var enemy_spawn_distance := Vector2(900.0, 500.0)
@export var enemy_spawn_min_distance := 200.0

var player: CharacterBody2D
var world_bounds := Rect2(Vector2.ZERO, Vector2(720, 1440))
var spawned_enemies: Array[Node] = []
var spawned_experiences: Array[Node] = []
var experience_cleanup_enabled := true

@onready var enemy_timer: Timer = $EnemyTimer
@onready var hud_info: Label = $HUD/Info
@onready var hud_restart_hint: Label = $HUD/RestartHint
@onready var hud_game_over: Label = $HUD/GameOver

func _ready() -> void:
	spawn_player()
	enemy_timer.wait_time = enemy_spawn_interval
	if not enemy_timer.timeout.is_connected(_spawn_enemy):
		enemy_timer.timeout.connect(_spawn_enemy)
	enemy_timer.start()
	_update_hud()

func get_nearest_enemy(origin: Vector2, max_distance: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := max_distance
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := origin.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(360, 720)
	add_child(player)
	player.set_game(self)

func _spawn_enemy() -> void:
	if player == null or player.is_dead:
		return
	var enemy := ENEMY_SCENE.instantiate()
	var offset := Vector2(randf_range(-enemy_spawn_distance.x, enemy_spawn_distance.x), randf_range(-enemy_spawn_distance.y, enemy_spawn_distance.y))
	if offset.length() < enemy_spawn_min_distance:
		offset = offset.normalized() * enemy_spawn_min_distance
	enemy.position = player.position + offset
	add_child(enemy)
	spawned_enemies.append(enemy)
	if enemy.has_method("set_game"):
		enemy.set_game(self)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if enemy != null:
		_spawn_experience(enemy.global_position, 5)
	_update_hud()

func _spawn_experience(position: Vector2, value: int) -> void:
	if not experience_cleanup_enabled:
		return
	var experience := EXPERIENCE_SCENE.instantiate()
	experience.global_position = position
	experience.pickup_value = value
	add_child(experience)
	spawned_experiences.append(experience)
	experience.tree_exited.connect(_on_experience_tree_exited.bind(experience))

func _on_experience_tree_exited(experience: Node) -> void:
	spawned_experiences.erase(experience)

func _on_enemy_tree_exited(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R) and player != null and player.is_dead:
		_restart_game()
	_update_hud()

func _update_hud() -> void:
	if hud_info != null and player != null:
		hud_info.text = "HP: %d / %d\nEnemies: %d\nExp Orbs: %d" % [player.health, player.max_health, spawned_enemies.size(), spawned_experiences.size()]
	if hud_game_over != null:
		hud_game_over.visible = player != null and player.is_dead
	if hud_restart_hint != null:
		hud_restart_hint.visible = player != null and player.is_dead

func _restart_game() -> void:
	experience_cleanup_enabled = false
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for experience in spawned_experiences:
		if is_instance_valid(experience):
			experience.queue_free()
	spawned_enemies.clear()
	spawned_experiences.clear()
	if is_instance_valid(player):
		player.queue_free()
	player = null
	spawn_player()
	experience_cleanup_enabled = true
	enemy_timer.start()
	_update_hud()

func collect_experience(value: int) -> void:
	if player != null and player.has_method("collect_experience"):
		player.collect_experience(value)
	_update_hud()
