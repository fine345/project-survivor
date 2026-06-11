extends Area2D

var damage := 5
var beam_width := 12.0
var beam_duration := 0.75
var direction := Vector2.RIGHT
var hit_enemies: Array = []
var owner_player: Node2D = null
var _tick_timer := 0.0
var _tick_interval := 0.75

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
	_update_collision_width()

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer -= _tick_interval
		_hit_enemies_during_tick()

func _hit_enemies_during_tick() -> void:
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
		body.take_damage(damage)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return
	if body == owner_player:
		return
	var body_id: int = body.get_instance_id()
	if hit_enemies.has(body_id):
		return
	hit_enemies.append(body_id)
	body.take_damage(damage)

func _update_collision_width() -> void:
	var collision: CollisionShape2D = $CollisionShape2D
	if collision != null:
		collision.position = Vector2(720, 0)
		var shape: RectangleShape2D = collision.shape as RectangleShape2D
		if shape != null:
			shape.size = Vector2(1440, beam_width)
	var visual: Label = $Visual
	if visual != null:
		var font_size: int = maxi(int(beam_width), 12)
		var char_width: float = font_size * 0.6
		var repeat_count: int = ceili(1440.0 / (char_width * 4.0))
		visual.text = ""
		for i in range(repeat_count):
			visual.text += "0101"
		visual.size = Vector2(1440, font_size)
		visual.position = Vector2(0, -font_size / 2.0)
		visual.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		visual.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		visual.add_theme_font_size_override("font_size", font_size)
		var tween: Tween = create_tween()
		tween.tween_property(visual, "modulate:a", 0.0, 0.5)
		tween.tween_callback(visual.queue_free)
