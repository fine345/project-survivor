extends Node2D

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
const ENEMY_SCENE := preload("res://scenes/game/enemy.tscn")
const EXPERIENCE_SCENE := preload("res://scenes/game/experience.tscn")
const REWARD_POOL_SCRIPT := preload("res://scripts/game/reward_pool.gd")

@export var enemy_one_spawn_interval := 1.5
@export var enemy_two_spawn_interval := 3.0
@export var enemy_spawn_distance := Vector2(800.0, 1600.0)
@export var enemy_spawn_min_distance := 200.0
@export var enemy_density_slowdown := 0.03
@export var enemy_time_relief_start := 60.0
@export var enemy_time_relief_full := 300.0

var player: CharacterBody2D
var world_bounds := Rect2(Vector2.ZERO, Vector2(720, 1440))
var spawned_enemies: Array[Node] = []
var spawned_experiences: Array[Node] = []
var experience_cleanup_enabled := true
var elapsed_time := 0.0
var enemy_two_unlocked := false
var reward_pool: Node = null
var reward_counts: Dictionary = {}
var pending_reward_options: Array[String] = []
var game_over_paused := false

@onready var enemy_one_timer: Timer = $EnemyTimer
@onready var enemy_two_timer: Timer = Timer.new()
@onready var hud_info: Label = $HUD/Info
@onready var hud_game_over: Label = $Layer/Panel/GameOver
@onready var hud_retry_button: Button = $Layer/Panel/RetryButton
@onready var level_up_panel: Control = $Layer/Panel/LevelUpPanel
@onready var pause_button: Button = $Layer/Panel/PauseButton
@onready var hud_virtual_joystick: Control = $HUD/VirtualJoystick

func _ready() -> void:
	reward_pool = REWARD_POOL_SCRIPT.new()
	spawn_player()
	_setup_timers()
	if level_up_panel != null and level_up_panel.has_signal("reward_selected") and not level_up_panel.reward_selected.is_connected(_on_reward_selected):
		level_up_panel.reward_selected.connect(_on_reward_selected)
	if level_up_panel != null:
		level_up_panel.visible = false
	if hud_game_over != null:
		hud_game_over.visible = false
	if hud_retry_button != null:
		hud_retry_button.visible = false
	elapsed_time = 0.0
	enemy_two_unlocked = false
	_update_hud()
	_update_game_state_ui()

func _setup_timers() -> void:
	enemy_one_timer.wait_time = enemy_one_spawn_interval
	if not enemy_one_timer.timeout.is_connected(_spawn_enemy_one):
		enemy_one_timer.timeout.connect(_spawn_enemy_one)
	if not enemy_one_timer.is_stopped():
		enemy_one_timer.stop()
	enemy_one_timer.start()
	if enemy_two_timer.get_parent() == null:
		add_child(enemy_two_timer)
	enemy_two_timer.one_shot = false
	enemy_two_timer.wait_time = enemy_two_spawn_interval
	if not enemy_two_timer.timeout.is_connected(_spawn_enemy_two):
		enemy_two_timer.timeout.connect(_spawn_enemy_two)
	if not enemy_two_timer.is_stopped():
		enemy_two_timer.stop()
	enemy_two_timer.start()

func get_nearest_enemy(origin: Vector2, max_distance: float, exclude_enemy: Node = null) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance: float = max_distance
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		if exclude_enemy != null and enemy == exclude_enemy:
			continue
		var distance: float = origin.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	var viewport_size: Vector2 = get_viewport_rect().size
	player.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5 - viewport_size.y / 16.0)
	add_child(player)
	player.set_game(self)

func _spawn_enemy_one() -> void:
	_spawn_enemy(1)

func _spawn_enemy_two() -> void:
	if not enemy_two_unlocked:
		return
	_spawn_enemy(2)

func _spawn_enemy(enemy_type: int) -> void:
	if player == null or player.is_dead:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.enemy_type = enemy_type
	var offset := _get_spawn_offset()
	enemy.position = player.position + offset
	add_child(enemy)
	spawned_enemies.append(enemy)
	if enemy.has_method("set_game"):
		enemy.set_game(self)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func _get_spawn_offset() -> Vector2:
	var half_width := enemy_spawn_distance.x * 0.5
	var half_height := enemy_spawn_distance.y * 0.5
	var side := randi_range(0, 3)
	var offset := Vector2.ZERO
	match side:
		0:
			offset = Vector2(randf_range(-half_width, half_width), -half_height)
		1:
			offset = Vector2(randf_range(-half_width, half_width), half_height)
		2:
			offset = Vector2(-half_width, randf_range(-half_height, half_height))
		_:
			offset = Vector2(half_width, randf_range(-half_height, half_height))
	if offset.length() < enemy_spawn_min_distance:
		offset = offset.normalized() * enemy_spawn_min_distance
	return offset

func _update_spawn_timers() -> void:
	var pressure_factor: float = 1.0 + float(spawned_enemies.size()) * enemy_density_slowdown
	var time_factor: float = _get_time_relief_factor()
	var effective_enemy_one_interval := enemy_one_spawn_interval * pressure_factor * time_factor
	var effective_enemy_two_interval := enemy_two_spawn_interval * pressure_factor * time_factor
	if enemy_one_timer != null:
		enemy_one_timer.wait_time = maxf(effective_enemy_one_interval, 0.2)
	if enemy_two_timer != null:
		enemy_two_timer.wait_time = maxf(effective_enemy_two_interval, 0.4)

func _get_time_relief_factor() -> float:
	if elapsed_time <= enemy_time_relief_start:
		return 1.0
	var clamped_time := clampf(elapsed_time, enemy_time_relief_start, enemy_time_relief_full)
	var progress: float = inverse_lerp(enemy_time_relief_start, enemy_time_relief_full, clamped_time)
	return lerpf(1.0, 0.55, progress)

func on_enemy_died(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	if enemy != null:
		var drop_value := 5
		if enemy.has_method("get"):
			drop_value = int(enemy.get("experience_drop"))
		_spawn_experience(enemy.global_position, drop_value)
	_update_hud()
	_update_game_state_ui()
	_update_spawn_timers()

func _spawn_experience(position: Vector2, value: int) -> void:
	if not experience_cleanup_enabled:
		return
	var experience := EXPERIENCE_SCENE.instantiate()
	experience.global_position = position
	experience.pickup_value = value
	if experience.has_method("set_attracted_target") and player != null:
		experience.set_attracted_target(player)
	add_child(experience)
	spawned_experiences.append(experience)
	experience.tree_exited.connect(_on_experience_tree_exited.bind(experience))

func _on_experience_tree_exited(experience: Node) -> void:
	spawned_experiences.erase(experience)

func _on_enemy_tree_exited(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	_update_hud()
	_update_game_state_ui()
	_update_spawn_timers()

func _process(delta: float) -> void:
	elapsed_time += delta
	enemy_two_unlocked = elapsed_time >= enemy_time_relief_start
	_update_spawn_timers()
	if Input.is_key_pressed(KEY_R) and player != null and player.is_dead:
		restart_game()
	if Input.is_key_pressed(KEY_Q):
		_prepare_reward_offers()
		_pause_for_level_up()
	_update_hud()
	_update_game_state_ui()

func restart_game() -> void:
	_restart_game()


func _on_player_level_up() -> void:
	if player == null:
		return
	_prepare_reward_offers()
	_pause_for_level_up()

func _on_reward_selected(reward_id: String) -> void:
	if player == null:
		return
	_apply_reward(reward_id)
	reward_counts[reward_id] = int(reward_counts.get(reward_id, 0)) + 1
	if level_up_panel != null:
		level_up_panel.visible = false
		level_up_panel.process_mode = Node.PROCESS_MODE_INHERIT
		level_up_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var reward_panel := level_up_panel.get_parent() as Control
		if reward_panel != null:
			reward_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if enemy_one_timer != null:
		enemy_one_timer.paused = false
	if enemy_two_timer != null:
		enemy_two_timer.paused = false
	get_tree().paused = false
	_update_hud()
	_update_game_state_ui()

func _update_hud() -> void:
	if hud_info != null and player != null:
		hud_info.text = "Time: %.1f\nHP: %d / %d\nEnemies: %d\nExp Orbs: %d\nLV: %d  EXP: %d" % [elapsed_time, player.health, player.max_health, spawned_enemies.size(), spawned_experiences.size(), player.level, player.experience]
	_update_game_state_ui()

func _update_game_state_ui() -> void:
	var in_reward_select := get_tree().paused and level_up_panel != null and level_up_panel.visible
	var game_over_visible: bool = player != null and player.is_dead
	if game_over_visible and not game_over_paused:
		game_over_paused = true
		get_tree().paused = true
		if enemy_one_timer != null:
			enemy_one_timer.paused = true
		if enemy_two_timer != null:
			enemy_two_timer.paused = true
	elif not game_over_visible and game_over_paused:
		game_over_paused = false
	var show_joystick := not game_over_visible and not in_reward_select
	if hud_game_over != null:
		hud_game_over.visible = game_over_visible
	if hud_retry_button != null:
		hud_retry_button.visible = game_over_visible
		hud_retry_button.process_mode = Node.PROCESS_MODE_ALWAYS
		hud_retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if hud_virtual_joystick != null:
		hud_virtual_joystick.visible = show_joystick
		hud_virtual_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE if not show_joystick else Control.MOUSE_FILTER_STOP
		if hud_virtual_joystick.has_method("set_enabled"):
			hud_virtual_joystick.call("set_enabled", show_joystick)
	if level_up_panel != null:
		level_up_panel.mouse_filter = Control.MOUSE_FILTER_STOP if in_reward_select else Control.MOUSE_FILTER_IGNORE

func _restart_game() -> void:
	if get_tree().paused:
		get_tree().paused = false
		await get_tree().process_frame
	game_over_paused = false
	if level_up_panel != null:
		level_up_panel.visible = false
		level_up_panel.process_mode = Node.PROCESS_MODE_INHERIT
	experience_cleanup_enabled = false
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for experience in spawned_experiences:
		if is_instance_valid(experience):
			experience.queue_free()
	spawned_enemies.clear()
	spawned_experiences.clear()
	for child in get_children():
		if child is Node2D and child != player and child != enemy_one_timer and child != level_up_panel and child != hud_virtual_joystick:
			if child.name.begins_with("Bullet") or child.name.begins_with("Ruler") or child.name.begins_with("AILaser"):
				child.queue_free()
	if is_instance_valid(player):
		if player.has_method("cleanup_rulers"):
			player.cleanup_rulers()
		player.queue_free()
	player = null
	spawn_player()
	experience_cleanup_enabled = true
	elapsed_time = 0.0
	enemy_two_unlocked = false
	if enemy_one_timer != null:
		enemy_one_timer.stop()
		enemy_one_timer.start()
	if enemy_two_timer != null:
		enemy_two_timer.stop()
		enemy_two_timer.start()
	_update_hud()
	_update_game_state_ui()

func collect_experience(value: int) -> void:
	if player != null and player.has_method("collect_experience"):
		player.collect_experience(value)
	_update_hud()
	_update_game_state_ui()

func _prepare_reward_offers() -> void:
	if reward_pool == null:
		return
	var choices: Array[Dictionary] = reward_pool.get_offer_choices(
		reward_counts, 3,
		player.shield_count if player != null else 0,
		{
			"ruler": player.ruler_weapon_unlocked if player != null else false,
			"ai_laser": player.ai_laser_unlocked if player != null else false
		}
	)
	pending_reward_options.clear()
	var display_titles: Array[String] = []
	for choice in choices:
		var reward_id := str(choice["id"])
		pending_reward_options.append(reward_id)
		display_titles.append(reward_pool.get_reward_title(reward_id))
	if level_up_panel != null:
		level_up_panel.call("set_rewards", pending_reward_options, display_titles)

func _apply_reward(reward_id: String) -> void:
	if player == null:
		return
	if player.has_method("apply_reward_effect"):
		player.apply_reward_effect(reward_id)

func _pause_for_level_up() -> void:
	get_tree().paused = true
	if level_up_panel != null:
		level_up_panel.visible = true
		level_up_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		level_up_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if enemy_one_timer != null:
		enemy_one_timer.paused = true
	if enemy_two_timer != null:
		enemy_two_timer.paused = true

func _on_pause_button_pressed() -> void:
	if game_over_paused:
		return
	if get_tree().paused:
		get_tree().paused = false
		if enemy_one_timer != null:
			enemy_one_timer.paused = false
		if enemy_two_timer != null:
			enemy_two_timer.paused = false
		pause_button.text = "暂停"
	else:
		get_tree().paused = true
		if enemy_one_timer != null:
			enemy_one_timer.paused = true
		if enemy_two_timer != null:
			enemy_two_timer.paused = true
		pause_button.text = "继续"
