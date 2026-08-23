extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	add_child(player)
	player.stream = load("res://audio/background_music.mp3")  # поменяй путь на свой файл
	player.volume_db = -10.0  # громкость (можно подстроить, 0 = обычная, отрицательное - тише)
	player.finished.connect(_on_finished)
	player.play()

func _on_finished():
	player.play()

func set_volume(db: float):
	player.volume_db = db

func set_muted(muted: bool):
	player.volume_db = -80.0 if muted else -10.0
