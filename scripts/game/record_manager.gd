extends Node

const SAVE_PATH := "user://records.json"
var records: Array = []
var next_id := 1

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

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {"records": records, "next_id": next_id}
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
