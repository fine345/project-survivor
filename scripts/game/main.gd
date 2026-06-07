extends Node2D

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
const ENEMY_SCENE := preload("res://scenes/game/enemy.tscn")

@export var enemy_spawn_interval := 2.0
@export var enemy_spawn_distance := Vector2(900.0, 500.0)
@export var enemy_spawn_min_distance := 200.0

var player: CharacterBody2D
var world_bounds := Rect2(Vector2.ZERO, Vector2(720, 1440))
var spawned_enemies: Array[Node] = []

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
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func _on_enemy_tree_exited(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R) and player != null and player.is_dead:
		_restart_game()
	_update_hud()

func _update_hud() -> void:
	if hud_info != null and player != null:
		hud_info.text = "HP: %d / %d\nEnemies: %d" % [player.health, player.max_health, spawned_enemies.size()]
	if hud_game_over != null:
		hud_game_over.visible = player != null and player.is_dead
	if hud_restart_hint != null:
		hud_restart_hint.visible = player != null and player.is_dead

func _restart_game() -> void:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
	if is_instance_valid(player):
		player.queue_free()
	player = null
	spawn_player()
	enemy_timer.start()
	_update_hud()
