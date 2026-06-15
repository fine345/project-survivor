extends Node2D

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
const ENEMY_TYPE1_SCENE := preload("res://scenes/game/enemy_type1.tscn")
const ENEMY_TYPE2_SCENE := preload("res://scenes/game/enemy_type2.tscn")
const EXPERIENCE_SCENE := preload("res://scenes/game/experience.tscn")
const BOSS1_SCENE := preload("res://scenes/game/boss1.tscn")
const BOSS_REWARD_SCENE := preload("res://scenes/game/boss_reward.tscn")
const BOSS2_SCENE := preload("res://scenes/game/boss2.tscn")
const ENEMY_TYPE3_SCENE := preload("res://scenes/game/enemy_type3.tscn")
const REWARD_POOL_SCRIPT := preload("res://scripts/ui/reward_pool.gd")

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
var total_kills := 0
var total_damage_dealt := 0
var summary_shown := false
var _exiting := false
var _unpause_ramp_time := 0.0
var _is_ramping := false
var boss1_spawned := false
var boss1_node: Node2D = null
var boss2_spawned := false
var boss2_node: Node2D = null
var enemy_three_unlocked := false
var _key2_pressed := false
var boss_boundary_active := false
var boss_boundary_rect := Rect2(Vector2(-440, -600), Vector2(1600, 1600))
var boss_health_bar: Control = null

@onready var enemy_one_timer: Timer = $EnemyTimer
@onready var enemy_two_timer: Timer = Timer.new()
var enemy_three_timer: Timer = null
@onready var hud_info: Label = $HUD/Info
@onready var hud_game_over: Label = $Layer/Panel/GameOver
@onready var hud_retry_button: Button = $Layer/Panel/RetryButton
@onready var level_up_panel: Control = $Layer/Panel/LevelUpPanel
@onready var pause_button: Button = $Layer/Panel/PauseButton
@onready var pause_menu: Control = $Layer/Panel/PauseMenu
@onready var hud_virtual_joystick: Control = $HUD/VirtualJoystick
@onready var summary_panel: Control = $Layer/Panel/SummaryPanel
@onready var exit_confirm_dialog: ConfirmationDialog = $Layer/Panel/ExitConfirmDialog
@onready var settings_overlay: Control = $Layer/Panel/SettingsOverlay
@onready var boss_health_bar_node: Control = $Layer/Panel/BossHealthBar

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
	summary_shown = false
	if summary_panel != null:
		summary_panel.visible = false
		if summary_panel.has_signal("restart_requested") and not summary_panel.restart_requested.is_connected(_on_summary_restart):
			summary_panel.restart_requested.connect(_on_summary_restart)
		if summary_panel.has_signal("exit_to_menu_requested") and not summary_panel.exit_to_menu_requested.is_connected(_do_exit_to_menu):
			summary_panel.exit_to_menu_requested.connect(_do_exit_to_menu)
	if pause_menu != null:
		pause_menu.visible = false
		var resume_btn: Button = pause_menu.get_node_or_null("VBox/ResumeButton")
		var settings_btn: Button = pause_menu.get_node_or_null("VBox/SettingsButton")
		var exit_btn: Button = pause_menu.get_node_or_null("VBox/ExitButton")
		if resume_btn != null:
			resume_btn.pressed.connect(_on_pause_button_pressed)
		if settings_btn != null:
			settings_btn.pressed.connect(_on_open_settings)
		if exit_btn != null:
			exit_btn.pressed.connect(_on_exit_to_menu)
	if exit_confirm_dialog != null:
		exit_confirm_dialog.confirmed.connect(func(): _show_summary(false))
	if settings_overlay != null:
		settings_overlay.visible = false
		settings_overlay.is_overlay = true
	boss_health_bar = boss_health_bar_node
	if boss_health_bar != null:
		boss_health_bar.visible = false
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
	if enemy_three_timer == null:
		enemy_three_timer = Timer.new()
		add_child(enemy_three_timer)
	enemy_three_timer.one_shot = false
	enemy_three_timer.wait_time = 3.0
	if not enemy_three_timer.timeout.is_connected(_spawn_enemy_three):
		enemy_three_timer.timeout.connect(_spawn_enemy_three)
	enemy_three_timer.stop()

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
	if player == null or player.is_dead:
		return
	var enemy := ENEMY_TYPE1_SCENE.instantiate()
	var offset := _get_spawn_offset()
	enemy.position = player.position + offset
	add_child(enemy)
	spawned_enemies.append(enemy)
	if enemy.has_method("set_game"):
		enemy.set_game(self)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func _spawn_enemy_two() -> void:
	if not enemy_two_unlocked:
		return
	if player == null or player.is_dead:
		return
	var enemy := ENEMY_TYPE2_SCENE.instantiate()
	var offset := _get_spawn_offset()
	enemy.position = player.position + offset
	add_child(enemy)
	spawned_enemies.append(enemy)
	if enemy.has_method("set_game"):
		enemy.set_game(self)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func _spawn_enemy_three() -> void:
	if not enemy_three_unlocked:
		return
	if player == null or player.is_dead:
		return
	var enemy := ENEMY_TYPE3_SCENE.instantiate()
	var offset := _get_spawn_offset()
	enemy.position = player.position + offset
	add_child(enemy)
	spawned_enemies.append(enemy)
	if enemy.has_method("set_game"):
		enemy.set_game(self)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy.set_target(player)

func _spawn_boss1() -> void:
	if boss1_spawned or player == null or player.is_dead:
		return
	boss1_spawned = true
	var boss := BOSS1_SCENE.instantiate()
	boss.position = player.position + Vector2(0, -200)
	add_child(boss)
	boss1_node = boss
	if boss.has_method("set_game"):
		boss.set_game(self)
	if boss.has_method("set_target"):
		boss.set_target(player)
	if boss.has_signal("tree_exited"):
		boss.tree_exited.connect(_on_boss1_tree_exited.bind(boss))
	spawned_enemies.append(boss)
	_clear_enemies_in_range(boss.global_position, 200.0)
	_enable_boss_boundary()
	if boss_health_bar != null:
		boss_health_bar.show_boss(boss)

func _clear_enemies_in_range(center: Vector2, radius: float) -> void:
	var to_remove: Array[Node] = []
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and not enemy.is_in_group("boss"):
			if enemy.global_position.distance_to(center) <= radius:
				to_remove.append(enemy)
	for enemy in to_remove:
		spawned_enemies.erase(enemy)
		enemy.queue_free()

func _enable_boss_boundary() -> void:
	boss_boundary_active = true
	if boss1_node != null:
		var center := boss1_node.global_position
		boss_boundary_rect = Rect2(Vector2(center.x - 800, center.y - 800), Vector2(1600, 1600))
	queue_redraw()

func _on_boss1_tree_exited(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	boss1_node = null
	boss_boundary_active = false
	queue_redraw()
	if boss_health_bar != null:
		boss_health_bar.hide_boss()
	var enemy3_timer := Timer.new()
	enemy3_timer.one_shot = true
	enemy3_timer.wait_time = 30.0
	enemy3_timer.timeout.connect(func():
		enemy_three_unlocked = true
		if enemy_three_timer != null:
			enemy_three_timer.start()
	)
	add_child(enemy3_timer)
	enemy3_timer.start()
	var boss2_timer := Timer.new()
	boss2_timer.one_shot = true
	boss2_timer.wait_time = 180.0
	boss2_timer.timeout.connect(func(): _spawn_boss2())
	add_child(boss2_timer)
	boss2_timer.start()
	_update_hud()
	_update_game_state_ui()
	_update_spawn_timers()

func _spawn_boss2() -> void:
	if boss2_spawned or player == null or player.is_dead:
		return
	boss2_spawned = true
	var boss := BOSS2_SCENE.instantiate()
	boss.position = player.position + Vector2(0, -200)
	add_child(boss)
	boss2_node = boss
	if boss.has_method("set_game"):
		boss.set_game(self)
	if boss.has_method("set_target"):
		boss.set_target(player)
	if boss.has_signal("tree_exited"):
		boss.tree_exited.connect(_on_boss2_tree_exited.bind(boss))
	spawned_enemies.append(boss)
	_clear_enemies_in_range(boss.global_position, 200.0)
	_enable_boss_boundary()
	if boss_health_bar != null:
		boss_health_bar.show_boss(boss)

func _on_boss2_tree_exited(enemy: Node) -> void:
	spawned_enemies.erase(enemy)
	boss2_node = null
	boss_boundary_active = false
	queue_redraw()
	if boss_health_bar != null:
		boss_health_bar.hide_boss()
	_update_hud()
	_update_game_state_ui()
	_update_spawn_timers()

func _spawn_boss_reward(position: Vector2, levels: int = 1) -> void:
	var reward := BOSS_REWARD_SCENE.instantiate()
	reward.global_position = position
	if reward.has_method("set_reward_levels"):
		reward.set_reward_levels(levels)
	if reward.has_method("set_attracted_target") and player != null:
		reward.set_attracted_target(player)
	add_child(reward)

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
	total_kills += 1
	if enemy != null:
		if enemy.is_in_group("boss"):
			var levels := 1
			if enemy.is_in_group("boss2"):
				levels = 2
			_spawn_boss_reward(enemy.global_position, levels)
		else:
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
	if _is_ramping:
		_unpause_ramp_time += delta
		var t := clampf(_unpause_ramp_time / 0.5, 0.0, 1.0)
		Engine.time_scale = lerpf(0.3, 1.0, t)
		if t >= 1.0:
			_is_ramping = false
			Engine.time_scale = 1.0
	elapsed_time += delta
	enemy_two_unlocked = elapsed_time >= enemy_time_relief_start
	_update_spawn_timers()
	if not boss1_spawned and elapsed_time >= 180.0:
		_spawn_boss1()
	if boss_boundary_active and player != null and not player.is_dead:
		player.position = player.position.clamp(boss_boundary_rect.position, boss_boundary_rect.end)
	if boss_boundary_active and boss1_node != null and is_instance_valid(boss1_node):
		boss1_node.position = boss1_node.position.clamp(boss_boundary_rect.position, boss_boundary_rect.end)
	if Input.is_key_pressed(KEY_R) and player != null and player.is_dead:
		restart_game()
	if Input.is_key_pressed(KEY_Q):
		_prepare_reward_offers()
		_pause_for_level_up()
	if Input.is_key_pressed(KEY_1):
		_spawn_boss1()
	if Input.is_key_pressed(KEY_2) and not _key2_pressed:
		_key2_pressed = true
		enemy_three_unlocked = true
		_spawn_enemy_three()
	if not Input.is_key_pressed(KEY_2):
		_key2_pressed = false
	if Input.is_key_pressed(KEY_3):
		_spawn_boss2()
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
	if enemy_three_timer != null:
		enemy_three_timer.paused = false
	_is_ramping = true
	_unpause_ramp_time = 0.0
	Engine.time_scale = 0.3
	get_tree().paused = false
	_update_hud()
	_update_game_state_ui()

func _update_hud() -> void:
	if hud_info != null and player != null:
		hud_info.text = "Time: %.1f\nHP: %d / %d\nEnemies: %d\nExp Orbs: %d\nLV: %d  EXP: %d" % [elapsed_time, player.health, player.max_health, spawned_enemies.size(), spawned_experiences.size(), player.level, player.experience]
	_update_game_state_ui()

func _update_game_state_ui() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var in_reward_select := tree.paused and level_up_panel != null and level_up_panel.visible
	var game_over_visible: bool = player != null and player.is_dead
	if game_over_visible and not game_over_paused:
		game_over_paused = true
		if enemy_one_timer != null:
			enemy_one_timer.paused = true
		if enemy_two_timer != null:
			enemy_two_timer.paused = true
		if enemy_three_timer != null:
			enemy_three_timer.paused = true
		if not summary_shown:
			summary_shown = true
			_show_summary(false)
	elif not game_over_visible and game_over_paused:
		game_over_paused = false
	var show_joystick := not game_over_visible and not in_reward_select and not summary_shown
	if hud_game_over != null:
		hud_game_over.visible = false
	if hud_retry_button != null:
		hud_retry_button.visible = false
	if hud_virtual_joystick != null:
		var sm = get_node_or_null("/root/SettingsManager")
		var is_fixed: bool = sm.is_fixed_joystick() if sm != null else false
		if is_fixed:
			hud_virtual_joystick.visible = not game_over_visible and not summary_shown
		else:
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
	_is_ramping = false
	Engine.time_scale = 1.0
	game_over_paused = false
	summary_shown = false
	if summary_panel != null:
		summary_panel.visible = false
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
	boss1_spawned = false
	boss1_node = null
	boss2_spawned = false
	boss2_node = null
	boss_boundary_active = false
	enemy_three_unlocked = false
	queue_redraw()
	if boss_health_bar != null:
		boss_health_bar.hide_boss()
	for child in get_children():
		if child is Node2D and child != player and child != enemy_one_timer and child != level_up_panel and child != hud_virtual_joystick:
			if child.name.begins_with("Bullet") or child.name.begins_with("Ruler") or child.name.begins_with("AILaser"):
				child.queue_free()
	for laser in get_tree().get_nodes_in_group("boss_laser"):
		if is_instance_valid(laser):
			laser.queue_free()
	if is_instance_valid(player):
		if player.has_method("cleanup_rulers"):
			player.cleanup_rulers()
		player.queue_free()
	player = null
	spawn_player()
	experience_cleanup_enabled = true
	elapsed_time = 0.0
	enemy_two_unlocked = false
	total_kills = 0
	total_damage_dealt = 0
	if enemy_one_timer != null:
		enemy_one_timer.paused = false
		enemy_one_timer.stop()
		enemy_one_timer.start()
	if enemy_two_timer != null:
		enemy_two_timer.paused = false
		enemy_two_timer.stop()
		enemy_two_timer.start()
	if enemy_three_timer != null:
		enemy_three_timer.paused = false
		enemy_three_timer.stop()
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
	if enemy_three_timer != null:
		enemy_three_timer.paused = true

func _on_pause_button_pressed() -> void:
	if game_over_paused:
		return
	if get_tree().paused:
		_is_ramping = true
		_unpause_ramp_time = 0.0
		Engine.time_scale = 0.3
		get_tree().paused = false
		if enemy_one_timer != null:
			enemy_one_timer.paused = false
		if enemy_two_timer != null:
			enemy_two_timer.paused = false
		if enemy_three_timer != null:
			enemy_three_timer.paused = false
		pause_button.text = "暂停"
		if pause_menu != null:
			pause_menu.visible = false
	else:
		get_tree().paused = true
		if enemy_one_timer != null:
			enemy_one_timer.paused = true
		if enemy_two_timer != null:
			enemy_two_timer.paused = true
		if enemy_three_timer != null:
			enemy_three_timer.paused = true
		pause_button.text = "继续"
		if pause_menu != null:
			pause_menu.visible = true

func _show_summary(is_victory: bool) -> void:
	if summary_panel == null:
		return
	get_tree().paused = true
	if enemy_one_timer != null:
		enemy_one_timer.paused = true
	if enemy_two_timer != null:
		enemy_two_timer.paused = true
	if enemy_three_timer != null:
		enemy_three_timer.paused = true
	var score: int = _calculate_score()
	var damage_taken: int = 0
	if player != null and player.has_method("get"):
		damage_taken = int(player.get("total_damage_taken"))
	var rewards_display: Dictionary = {}
	for key in reward_counts:
		rewards_display[reward_pool.get_reward_title(key)] = reward_counts[key]
	summary_panel.call("show_summary", {
		"is_victory": is_victory,
		"time": elapsed_time,
		"kills": total_kills,
		"level": player.level if player != null else 1,
		"damage_dealt": total_damage_dealt,
		"rewards": rewards_display,
		"score": score
	})
	_save_record(is_victory, damage_taken, score, rewards_display)

func _save_record(is_victory: bool, damage_taken: int, score: int, rewards_display: Dictionary) -> void:
	var record_manager = get_node_or_null("/root/RecordManager")
	if record_manager == null:
		return
	var rewards_list: Array[String] = []
	for key in rewards_display:
		rewards_list.append("%s×%d" % [str(key), rewards_display[key]])
	record_manager.add_record({
		"result": "victory" if is_victory else "defeat",
		"time": elapsed_time,
		"level": player.level if player != null else 1,
		"kills": total_kills,
		"damage_dealt": total_damage_dealt,
		"damage_taken": damage_taken,
		"score": score,
		"rewards": rewards_list
	})

func _calculate_score() -> int:
	return int(
		elapsed_time * 1
		+ total_kills * 15
		+ (player.level if player != null else 1) * 100
		+ total_damage_dealt * 0.5
	)

func _on_summary_restart() -> void:
	restart_game()

func _on_exit_to_menu() -> void:
	if exit_confirm_dialog != null:
		exit_confirm_dialog.dialog_text = "退出游戏将立即结算"
		exit_confirm_dialog.popup_centered()
	else:
		_show_summary(false)

func _do_exit_to_menu() -> void:
	if _exiting:
		return
	_exiting = true
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu.tscn")

func _on_open_settings() -> void:
	if settings_overlay != null:
		settings_overlay.visible = true
		settings_overlay._update_display()
		get_tree().paused = true

func _draw() -> void:
	if boss_boundary_active:
		draw_rect(boss_boundary_rect, Color.RED, false, 3.0)
