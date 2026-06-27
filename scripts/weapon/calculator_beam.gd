extends Area2D

var damage := 5
var beam_width := 12.0
var beam_duration := 0.75
var direction := Vector2.RIGHT
var hit_enemies: Array = []
var owner_player: Node2D = null
var _tick_timer := 0.0
var _tick_interval := 0.75
var _kill_buffer: int = 0
var _kill_buffer_timer := 0.0
const KILL_WINDOW := 0.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_tick_timer = 0.0

func setup(p_damage: int, p_direction: Vector2, p_width: float, p_duration: float, p_player: Node2D) -> void:
	damage = p_damage
	direction = p_direction.normalized()
	beam_width = p_width
	beam_duration = p_duration
	owner_player = p_player
	rotation = direction.angle()
	_tick_interval = 0.75
	_setup_visual()
	_update_collision_width()

func _setup_visual() -> void:
	var existing: Node = get_node_or_null("Visual")
	if existing != null:
		existing.queue_free()
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = load("res://assets/sprites/calcultor_laser-Sheet.png")
	sprite.centered = false
	var scale_x := beam_width / 8.0
	var scale_y := beam_width / 8.0
	sprite.scale = Vector2(scale_x, scale_y)
	sprite.position = Vector2(0, -4.0 * scale_y)
	sprite.z_index = 8
	add_child(sprite)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, beam_duration * 0.5).set_delay(beam_duration * 0.5)
	tween.tween_callback(sprite.queue_free)

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer -= _tick_interval
		_hit_enemies_during_tick()
	_kill_buffer_timer -= delta
	if _kill_buffer_timer <= 0.0:
		_kill_buffer = 0

func _hit_enemies_during_tick() -> void:
	var killed_this_tick: int = 0
	for body in get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if body == owner_player:
			continue
		if not body.has_method("take_damage"):
			continue
		var body_id: int = body.get_instance_id()
		if hit_enemies.has(body_id):
			continue
		hit_enemies.append(body_id)
		var was_dead: bool = body.get("is_dead") == true
		var hp_before_raw = body.get("health")
		var hp_before: int = hp_before_raw if hp_before_raw != null else 999
		body.take_damage(damage, Color(0.373, 0.804, 0.894, 1.0))
		if not was_dead and not body.is_in_group("boss"):
			if hp_before <= damage:
				killed_this_tick += 1
	_add_kills(killed_this_tick)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return
	if body == owner_player:
		return
	var body_id: int = body.get_instance_id()
	if hit_enemies.has(body_id):
		return
	hit_enemies.append(body_id)
	var was_dead: bool = body.get("is_dead") == true
	var hp_before_raw = body.get("health")
	var hp_before: int = hp_before_raw if hp_before_raw != null else 999
	body.take_damage(damage, Color(0.373, 0.804, 0.894, 1.0))
	if not was_dead and not body.is_in_group("boss"):
		if hp_before <= damage:
			_add_kills(1)

func _update_collision_width() -> void:
	var collision: CollisionShape2D = $CollisionShape2D
	if collision != null:
		collision.position = Vector2(720, 0)
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if shape != null:
			shape.size = Vector2(1440, beam_width)

func _add_kills(count: int) -> void:
	if count <= 0:
		return
	_kill_buffer += count
	_kill_buffer_timer = KILL_WINDOW
	if _kill_buffer >= 2:
		var rm = get_node_or_null("/root/RecordManager")
		if rm != null:
			rm.increment_achievement_stat("laser_double_kills")
		_kill_buffer = 0
