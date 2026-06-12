extends Label

func setup(amount: int, color: Color, pos: Vector2) -> void:
	text = str(amount)
	add_theme_font_size_override("font_size", 28)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	var offset_x := randf_range(-10.0, 10.0)
	var offset_y := randf_range(-5.0, 5.0)
	global_position = pos - Vector2(size.x * 0.5, size.y) + Vector2(offset_x, offset_y)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
