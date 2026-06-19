extends Node2D

const BG_TEXTURES_PATHS := [
	"res://assets/sprites/background_normal_1-Sheet.png",
	"res://assets/sprites/background_normal_2-Sheet.png",
	"res://assets/sprites/background_normal_3-Sheet.png",
]
const DECO_TEXTURES_PATHS := [
	"res://assets/sprites/background_kezi_1-Sheet.png",
	"res://assets/sprites/background_kezi_2-Sheet.png",
	"res://assets/sprites/background_kezi_3-Sheet.png",
	"res://assets/sprites/background_kezi_4-Sheet.png",
	"res://assets/sprites/background_kezi_5-Sheet.png",
	"res://assets/sprites/background_kezi_6-Sheet.png",
]
const TILE_SIZE := Vector2(640, 160)
const DRAW_SCALE := 2.0
const ROW_OFFSET := 320.0
const MAP_EXTEND := 2000.0
const DECO_CELL := 1500.0

var _tile_data: Dictionary = {}
var _textures: Array[Texture2D] = []
var _deco_textures: Array[Texture2D] = []
var _deco_data: Dictionary = {}

func _ready() -> void:
	z_index = -100
	for path in BG_TEXTURES_PATHS:
		_textures.append(load(path))
	for path in DECO_TEXTURES_PATHS:
		_deco_textures.append(load(path))
	_generate_tiles(60, 40)

func _generate_tiles(cols: int, rows: int) -> void:
	_tile_data.clear()
	for row in range(-rows / 2, rows / 2):
		for col in range(-cols / 2, cols / 2):
			var key := row * 10000 + col
			_tile_data[key] = {
				"texture": _textures[randi() % _textures.size()],
				"flip_h": randf() < 0.5,
				"flip_v": randf() < 0.5,
			}

func _deco_hash(cx: int, cy: int) -> float:
	var h := cx * 374761393 + cy * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(abs(h) % 10000) / 10000.0

func _get_deco(cx: int, cy: int) -> Dictionary:
	var key := cx * 100000 + cy
	if key not in _deco_data:
		var rand_val := _deco_hash(cx, cy)
		var texture_idx := int(rand_val * 6) % 6
		var neighbors: Array[int] = []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nk := (cx + dx) * 100000 + (cy + dy)
				if nk in _deco_data:
					var neighbor_tex: Texture2D = _deco_data[nk].texture
					for i in range(_deco_textures.size()):
						if _deco_textures[i] == neighbor_tex:
							neighbors.append(i)
							break
		if texture_idx in neighbors:
			for try in range(6):
				if try not in neighbors:
					texture_idx = try
					break
		_deco_data[key] = {
			"texture": _deco_textures[texture_idx],
			"offset": Vector2(_deco_hash(cx + 1, cy) * DECO_CELL, _deco_hash(cx, cy + 1) * DECO_CELL),
		}
	return _deco_data[key]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	var center := Vector2(360, 720) if cam == null else cam.global_position
	var scaled_tile := TILE_SIZE * DRAW_SCALE
	var half := Vector2(720, 1440) * 0.5 + Vector2(MAP_EXTEND, MAP_EXTEND)
	var min_x := center.x - half.x
	var max_x := center.x + half.x
	var min_y := center.y - half.y
	var max_y := center.y + half.y
	var start_col := int(floor(min_x / scaled_tile.x)) - 2
	var end_col := int(ceil(max_x / scaled_tile.x)) + 2
	var start_row := int(floor(min_y / scaled_tile.y)) - 1
	var end_row := int(ceil(max_y / scaled_tile.y)) + 1
	for row in range(start_row, end_row + 1):
		var y := row * scaled_tile.y
		var x_off := ROW_OFFSET * DRAW_SCALE if row % 2 == 0 else 0.0
		for col in range(start_col, end_col + 1):
			var x := col * scaled_tile.x + x_off
			var key := row * 10000 + col
			if key not in _tile_data:
				_tile_data[key] = {
					"texture": _textures[randi() % _textures.size()],
					"flip_h": randf() < 0.5,
					"flip_v": randf() < 0.5,
				}
			var tile: Dictionary = _tile_data[key]
			var sx := DRAW_SCALE * (-1.0 if tile.flip_h else 1.0)
			var sy := DRAW_SCALE * (-1.0 if tile.flip_v else 1.0)
			var ox := scaled_tile.x if tile.flip_h else 0.0
			var oy := scaled_tile.y if tile.flip_v else 0.0
			draw_set_transform(Vector2(x + ox, y + oy), 0.0, Vector2(sx, sy))
			draw_texture(tile.texture, Vector2.ZERO)
	var dc_start_x := int(floor(min_x / DECO_CELL)) - 1
	var dc_end_x := int(ceil(max_x / DECO_CELL)) + 1
	var dc_start_y := int(floor(min_y / DECO_CELL)) - 1
	var dc_end_y := int(ceil(max_y / DECO_CELL)) + 1
	for dy in range(dc_start_y, dc_end_y + 1):
		for dx in range(dc_start_x, dc_end_x + 1):
			var deco := _get_deco(dx, dy)
			var pos: Vector2 = Vector2(dx * DECO_CELL, dy * DECO_CELL) + deco.offset
			var dsx := DRAW_SCALE
			var dsy := DRAW_SCALE
			var dox: float = pos.x
			var doy: float = pos.y
			draw_set_transform(Vector2(dox, doy), 0.0, Vector2(dsx, dsy))
			draw_texture(deco.texture, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
