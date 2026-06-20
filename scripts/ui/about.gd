extends Control

func _ready() -> void:
	$Panel/VBox/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	_set_font_size(self, 33)

func _set_font_size(node: Node, size: int) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_set_font_size(child, size)
