extends AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = load("res://assets/audio/BGM.mp3")
	bus = "Music"
	autoplay = true
	play()
	finished.connect(func(): play())
