extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

@export var start_offset: float = 0.0  # подстрой если в начале файла есть тишина/интро
@export var volume_db: float = -8.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = load("res://Sounds/menu_music.mp3")
	player.volume_db = volume_db
	player.finished.connect(_on_finished)
	player.play(start_offset)

func _on_finished():
	player.play(start_offset)

func stop_music():
	player.stop()

func fade_out_and_stop(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(func():
		player.stop()
		player.volume_db = volume_db  # возвращаем громкость на будущее (для повторного запуска)
	)

func fade_in_and_play(duration: float = 1.0):
	player.volume_db = -80.0
	player.play(start_offset)
	var tween = create_tween()
	tween.tween_property(player, "volume_db", volume_db, duration)
