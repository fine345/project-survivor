extends Control

func _ready() -> void:
	$Panel/VBox/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
