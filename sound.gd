extends Node

var jump_sound = preload("res://Sounds/jump.mp3")
var coin_sound = preload("res://Sounds/coin.mp3")
var click_sound = preload("res://Sounds/click.mp3")
var boss_laugh_sound = preload("res://Sounds/boss_laugh.mp3")
var boss_roar1_sound = preload("res://Sounds/boss_roar1.mp3")
var boss_roar2_sound = preload("res://Sounds/boss_roar2.mp3")
var boss_breath_sound = preload("res://Sounds/boss_breath.mp3")
var victory_sfx_sound = preload("res://Sounds/victory_text_sound.mp3")
var checkpoint_sound = preload("res://Sounds/checkpoint.mp3")
var sword_hit_sound = preload("res://Sounds/sword_hit.mp3")
var skeleton_death_sound = preload("res://Sounds/skeleton_death.mp3")
var giant_walk_sound = preload("res://Sounds/giant_walk.mp3")
var giant_death_sound = preload("res://Sounds/giant_death.mp3")

# Если в начале файла есть тишина - подстрой эти значения (в секундах),
# чтобы пропустить её и звук начинался сразу с реального "щелчка"/звука.
# Увеличивай на 0.02-0.05 за раз, пока звук не начнёт играть без задержки,
# но не переборщи - иначе обрежется начало самого звука.
@export var click_start_offset: float = 0.5
@export var jump_start_offset: float = 0.2
@export var coin_start_offset: float = 1.0

@export var jump_volume: float = 2.0  # отрицательное = тише, 0 = обычная громкость
@export var coin_volume: float = 0.0
@export var click_volume: float = -8.0
@export var checkpoint_volume: float = -10.0
@export var skeleton_death_volume: float = -4.0
@export var sword_hit_volume: float = -4.0
@export var boss_laugh_max_duration: float = 1.5  # секунд - подстрой если нужно короче/длиннее
@export var giant_death_max_duration: float = 1.8  # секунд - подстрой если нужно короче/длиннее
@export var giant_death_volume: float = 4.0
var is_laughing: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Прогреваем звуки один раз тихо при старте - убирает задержку декодирования
	# MP3 в момент реального использования (клик/прыжок/монетка)
	warmup(jump_sound)
	warmup(coin_sound)
	warmup(click_sound)

func warmup(stream: AudioStream):
	var p = AudioStreamPlayer.new()
	add_child(p)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.stream = stream
	p.volume_db = -80.0  # практически неслышно
	p.play()
	p.finished.connect(p.queue_free)

func play(stream: AudioStream, volume_db: float = 0.0, start_offset: float = 0.0, max_duration: float = 0.0):
	var p = AudioStreamPlayer.new()
	add_child(p)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.stream = stream
	p.volume_db = volume_db
	p.play(start_offset)
	p.finished.connect(p.queue_free)
	if max_duration > 0.0:
		var cut_timer = get_tree().create_timer(max_duration)
		cut_timer.timeout.connect(func():
			if is_instance_valid(p):
				p.stop()
				p.queue_free()
		)

func play_jump():
	play(jump_sound, jump_volume, jump_start_offset)

func play_coin():
	play(coin_sound, coin_volume, coin_start_offset)

func play_click():
	play(click_sound, click_volume, click_start_offset)

func play_boss_laugh():
	is_laughing = true
	play(boss_laugh_sound, 0.0, 0.0, boss_laugh_max_duration)
	var t = get_tree().create_timer(boss_laugh_max_duration)
	t.timeout.connect(func(): is_laughing = false)

func play_boss_roar():
	if is_laughing:
		return  # босс не рычит пока смеётся
	# Чередуем два разных рыка случайно, чтобы не было однотипно
	if randi() % 2 == 0:
		play(boss_roar1_sound)
	else:
		play(boss_roar2_sound)

func play_boss_breath():
	play(boss_breath_sound)

func play_victory_sfx():
	play(victory_sfx_sound)

func play_checkpoint():
	play(checkpoint_sound, checkpoint_volume)

func play_sword_hit():
	play(sword_hit_sound, sword_hit_volume)

func play_skeleton_death():
	play(skeleton_death_sound, skeleton_death_volume)

func play_giant_walk():
	play(giant_walk_sound)

func play_giant_death():
	play(giant_death_sound, giant_death_volume, 0.0, giant_death_max_duration)

func connect_click_sounds(root: Node):
	if root is Button:
		root.button_down.connect(play_click)
	for child in root.get_children():
		if child is Button:
			child.button_down.connect(play_click)
		if child.get_child_count() > 0:
			connect_click_sounds(child)
