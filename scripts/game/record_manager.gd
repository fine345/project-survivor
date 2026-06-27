extends Node

const SAVE_PATH := "user://records.json"
var records: Array = []
var next_id := 1
var achievement_stats: Dictionary = {
	"difficulty_normal_victory": false,
	"difficulty_hard_victory": false,
	"difficulty_challenge_victory": false,
	"no_damage_normal": false,
	"no_damage_hard": false,
	"no_damage_challenge": false,
	"boss1_kills": 0,
	"boss2_kills": 0,
	"boss3_kills": 0,
	"ranged_interrupts": 0,
	"laser_double_kills": 0,
	"low_hp_boss_kills": 0,
	"difficulty_clear": 0,
	"no_damage_clear": 0,
}

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data: Dictionary = json.data
	if data.has("records"):
		records = data["records"]
	if data.has("next_id"):
		next_id = int(data["next_id"])
	if data.has("achievement_stats"):
		var loaded: Dictionary = data["achievement_stats"]
		for key in loaded:
			achievement_stats[key] = loaded[key]

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {"records": records, "next_id": next_id, "achievement_stats": achievement_stats}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func add_record(stats: Dictionary) -> void:
	var record := {
		"id": next_id,
		"date": Time.get_datetime_string_from_system(false, true),
		"result": stats.get("result", "defeat"),
		"time": stats.get("time", 0),
		"level": stats.get("level", 1),
		"kills": stats.get("kills", 0),
		"damage_dealt": stats.get("damage_dealt", 0),
		"damage_taken": stats.get("damage_taken", 0),
		"score": stats.get("score", 0),
		"rewards": stats.get("rewards", [])
	}
	records.append(record)
	next_id += 1
	_save()

func get_records() -> Array:
	return records

func has_records() -> bool:
	return records.size() > 0

func increment_achievement_stat(key: String, amount: int = 1) -> void:
	if achievement_stats[key] is bool:
		achievement_stats[key] = true
	else:
		achievement_stats[key] = int(achievement_stats.get(key, 0)) + amount
	_save()

func set_achievement_flag(key: String) -> void:
	achievement_stats[key] = true
	_save()

func get_achievement_stat(key: String):
	return achievement_stats.get(key, 0)

func get_achievements() -> Dictionary:
	var total_kills := 0
	var total_time := 0.0
	var total_games := records.size()
	for r in records:
		total_kills += int(r.get("kills", 0))
		total_time += float(r.get("time", 0))
	return {
		"kills": total_kills,
		"total_time": int(total_time),
		"total_games": total_games,
		"boss1_kills": int(achievement_stats.get("boss1_kills", 0)),
		"boss2_kills": int(achievement_stats.get("boss2_kills", 0)),
		"boss3_kills": int(achievement_stats.get("boss3_kills", 0)),
		"ranged_interrupts": int(achievement_stats.get("ranged_interrupts", 0)),
		"laser_double_kills": int(achievement_stats.get("laser_double_kills", 0)),
		"low_hp_boss_kills": int(achievement_stats.get("low_hp_boss_kills", 0)),
		"difficulty_clear": int(achievement_stats.get("difficulty_clear", 0)),
		"no_damage_clear": int(achievement_stats.get("no_damage_clear", 0)),
	}
