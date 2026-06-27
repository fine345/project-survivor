extends Area2D

var owner_player: Node2D = null
var damage := 16
var orbit_radius := 125.0
var collision_radius := 13.0
var rotation_speed := PI
var angle_offset := 0.0

var _hit_cooldowns: Dictionary = {}
var _sprite: AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite = $AnimatedSprite2D
	_sprite.scale = Vector2(2.0, 2.0)
	var sf := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_loop("spin", true)
	sf.set_animation_speed("spin", 20.0)
	var tex := load("res://assets/sprites/ruler-Sheet.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	for i in range(8):
		atlas.region = Rect2(i * 13, 0, 13, 13)
		sf.add_frame("spin", atlas.duplicate())
	_sprite.sprite_frames = sf
	_sprite.flip_h = true
	_sprite.play("spin")
	_update_collision_shape()

func setup(player: Node2D, idx: int, count: int) -> void:
	owner_player = player
	angle_offset = (TAU / max(count, 1)) * idx

func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
	if owner_player.get_tree().paused:
		return
	angle_offset += rotation_speed * delta
	var target_pos: Vector2 = owner_player.global_position + Vector2(cos(angle_offset), sin(angle_offset)) * orbit_radius
	global_position = target_pos
	rotation = angle_offset

	var now: float = Time.get_ticks_msec() / 1000.0
	var keys_to_remove: Array = []
	for key in _hit_cooldowns:
		if now - _hit_cooldowns[key] >= 0.5:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_hit_cooldowns.erase(key)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return
	if body == owner_player:
		return
	var body_id: int = body.get_instance_id()
	var now: float = Time.get_ticks_msec() / 1000.0
	if _hit_cooldowns.has(body_id):
		return
	_hit_cooldowns[body_id] = now
	body.take_damage(damage, Color(0.984, 0.949, 0.212, 1.0))

func set_params(p_damage: float, p_orbit_radius: float, p_collision_radius: float, p_rotation_speed: float) -> void:
	damage = int(round(p_damage))
	orbit_radius = p_orbit_radius
	collision_radius = p_collision_radius
	rotation_speed = p_rotation_speed
	_update_collision_shape()

func _update_collision_shape() -> void:
	var shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = collision_radius
	if _sprite != null:
		var sprite_scale: float = collision_radius / 13.0
		_sprite.scale = Vector2(sprite_scale, sprite_scale)
