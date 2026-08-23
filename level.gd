extends Node2D

@export var mob_scene: PackedScene
@export var phase2_mob_scene: PackedScene
@export var final_boss_scene: PackedScene
var second_boss_spawn_time = 200.0  # 3:20 - появляется второй босс
var second_boss_spawned = false
@export var giant_scene: PackedScene
@export var debug_start_time: float = 0.0  # ОТЛАДКА: поставь 115 чтобы сразу начать у 2 минут, потом верни на 0
@export var debug_disable_mobs_and_giant: bool = false  # ОТЛАДКА: включи, чтобы тестировать только босса
var spawn_timer = 0.0
var spawn_interval = 5.0
var min_spawn_interval = 1.5
var game_time = 0.0
var max_mobs = 8

var mob_phase = 1
var phase2_start_time = 120.0  # 2:00 - скелеты пропадают, начинается новый моб
var boss_spawn_time = 180.0    # 3:00 - чекпоинт, зачистка арены, включение стены
var boss_spawned = false

var first_boss_actual_spawn_time = 195.0  # 3:15 - сам первый босс появляется здесь
var first_boss_actually_spawned = false

var warning_message_time = 185.0  # 3:05 - предупреждающая надпись (отдельно от гиганта)
var warning_message_shown = false

var giant_timer = 0.0
var giant_spawn_interval = 12.0

var checkpoint_time = 60.0

var heal_info_1_time = 5.0     # 0:05
var heal_info_1_shown = false
var heal_info_2_time = 95.0    # 1:35
var heal_info_2_shown = false
var heal_info_3_time = 125.0   # 2:05
var heal_info_3_shown = false
var heal_info_4_time = 155.0   # 2:35
var heal_info_4_shown = false
var checkpoint_pause_duration = 5.0
var checkpoint_triggered = false
var spawn_paused_until = 0.0

var checkpoint2_time = 120.0
var checkpoint2_triggered = false

var record_time = 0.0
var last_saved_second = -1

@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var player = $Player
@onready var time_label = $CanvasLayer/TimePanel/TimeLabel
@onready var healthy_texture = preload("res://UI/HB_4.1-Healthy.png")
@onready var hurt_texture = preload("res://UI/HB_4.1-Hurt.png")
@onready var pause_overlay = $CanvasLayer/PauseOverlay
@onready var pause_button = $CanvasLayer/PauseButton
@onready var resume_button = $CanvasLayer/PauseOverlay/ResumeButton
@onready var menu_button = $CanvasLayer/PauseOverlay/MenuButton
@onready var toggle_controls_button = $CanvasLayer/PauseOverlay/ToggleControlsButton
@onready var customize_controls_button = $CanvasLayer/PauseOverlay/CustomizeControlsButton
@onready var done_customize_button = $CanvasLayer/DoneCustomizeButton
@onready var reset_controls_button = $CanvasLayer/ResetControlsButton
@onready var mobile_controls = $CanvasLayer/MobileControls
@onready var coin_label = $CanvasLayer/CoinPanel/CoinLabel
@onready var checkpoint_panel = $CanvasLayer/CheckpointPanel
@onready var checkpoint_label = $CanvasLayer/CheckpointPanel/CheckpointLabel
@onready var warning_panel = $CanvasLayer/WarningPanel
@onready var warning_label = $CanvasLayer/WarningPanel/WarningLabel
@onready var victory_panel = $CanvasLayer/VictoryPanel
@onready var victory_label = $CanvasLayer/VictoryPanel/VictoryLabel
var victory_triggered = false
@onready var instruction_panel = $CanvasLayer/InstructionPanel
@onready var instruction_label = $CanvasLayer/InstructionPanel/InstructionLabel
@onready var arena_wall_right = $ArenaWallRight/CollisionShape2D
@onready var pause_label = $CanvasLayer/PauseOverlay/PauseLabel
@onready var background_music = $CanvasLayer/BackgroundMusic

@export var normal_music: AudioStream
@export var boss_music: AudioStream
@export var victory_music: AudioStream
@export var normal_music_start_offset: float = 2.0  # пропустить интро в начале файла
@export var boss_music_start_offset: float = 0.0    # подстрой если нужно (как с click/jump/coin)
@export var normal_music_volume: float = 8.0
@export var boss_music_volume: float = 8.0
@export var victory_music_volume: float = 16.0

var boss_music_started = false
var boss_roar_timer = 0.0
var boss_was_present = false
var boss_roar_next_interval = 12.0  # случайное значение между 10-15, обновляется после каждого рыка

func _ready():
	await get_tree().process_frame
	pause_label.text = Lang.t("pause_title")
	resume_button.text = Lang.t("resume")
	menu_button.text = Lang.t("menu")
	game_time = debug_start_time
	Coins.game_time = game_time
	if game_time >= checkpoint_time:
		checkpoint_triggered = true
	if game_time >= checkpoint2_time:
		checkpoint2_triggered = true
	if game_time >= phase2_start_time:
		mob_phase = 2
	if game_time >= boss_spawn_time:
		boss_spawned = true
		arena_wall_right.disabled = false
	if game_time >= first_boss_actual_spawn_time:
		first_boss_actually_spawned = true
	hp_bar.max_value = player.health
	hp_bar.value = player.health
	record_time = load_record()
	pause_overlay.visible = false
	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(toggle_pause)
	menu_button.pressed.connect(go_to_menu)
	toggle_controls_button.pressed.connect(toggle_mobile_controls)
	if mobile_controls.visible:
		toggle_controls_button.text = Lang.t("hide_controls")
	else:
		toggle_controls_button.text = Lang.t("show_controls")
	customize_controls_button.pressed.connect(start_customize_controls)
	customize_controls_button.text = Lang.t("customize_controls")
	done_customize_button.pressed.connect(finish_customize_controls)
	done_customize_button.text = Lang.t("done_customize")
	done_customize_button.visible = false
	reset_controls_button.pressed.connect(reset_mobile_controls_positions)
	reset_controls_button.text = Lang.t("reset_controls")
	reset_controls_button.visible = false
	Sound.connect_click_sounds(pause_overlay)
	Sound.connect_click_sounds(pause_button)
	Sound.connect_click_sounds(done_customize_button)
	Sound.connect_click_sounds(reset_controls_button)
	coin_label.text = "🪙 " + str(Coins.coins)
	Coins.coins_changed.connect(_on_coins_changed)
	checkpoint_panel.visible = false
	warning_panel.visible = false
	instruction_panel.visible = false
	victory_panel.visible = false
	if debug_disable_mobs_and_giant:
		for m in get_tree().get_nodes_in_group("mob"):
			m.queue_free()
		for g in get_tree().get_nodes_in_group("giant"):
			g.queue_free()

	background_music.finished.connect(_on_music_finished)
	if game_time >= boss_spawn_time and boss_music:
		boss_music_started = true
		background_music.stream = boss_music
		background_music.volume_db = -80.0
		background_music.play(boss_music_start_offset)
		var fade_in = create_tween()
		fade_in.tween_property(background_music, "volume_db", boss_music_volume, 1.0)
	elif normal_music:
		background_music.stream = normal_music
		background_music.volume_db = -80.0
		background_music.play(normal_music_start_offset)
		var fade_in = create_tween()
		fade_in.tween_property(background_music, "volume_db", normal_music_volume, 1.0)

func _on_music_finished():
	if boss_music_started:
		background_music.play(boss_music_start_offset)
	else:
		background_music.play(normal_music_start_offset)

func _on_coins_changed(new_amount: int):
	coin_label.text = "🪙 " + str(new_amount)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	pause_overlay.visible = get_tree().paused

func toggle_mobile_controls():
	var now_visible = mobile_controls.toggle_visibility()
	if now_visible:
		toggle_controls_button.text = Lang.t("hide_controls")
	else:
		toggle_controls_button.text = Lang.t("show_controls")

func start_customize_controls():
	print("Level: start_customize_controls() вызван")
	pause_overlay.visible = false
	mobile_controls.visible = true
	mobile_controls.enable_customize()
	done_customize_button.visible = true
	reset_controls_button.visible = true

func finish_customize_controls():
	print("Level: finish_customize_controls() вызван")
	mobile_controls.disable_customize()
	done_customize_button.visible = false
	reset_controls_button.visible = false
	pause_overlay.visible = true

func reset_mobile_controls_positions():
	mobile_controls.reset_positions()

func go_to_menu():
	get_tree().paused = false
	MenuMusic.fade_in_and_play(1.0)
	get_tree().change_scene_to_file("res://menu.tscn")

func _process(delta):
	game_time += delta
	Coins.game_time = game_time
	spawn_timer += delta
	var current_interval = max(min_spawn_interval, spawn_interval - (game_time / 15.0))
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		if not debug_disable_mobs_and_giant and game_time < boss_spawn_time:
			spawn_mob()

	giant_timer += delta
	if giant_timer >= giant_spawn_interval:
		giant_timer = 0.0
		if not debug_disable_mobs_and_giant and game_time < boss_spawn_time:
			spawn_giant()

	if not checkpoint_triggered and game_time >= checkpoint_time:
		trigger_checkpoint()

	if not heal_info_1_shown and game_time >= heal_info_1_time:
		heal_info_1_shown = true
		show_checkpoint_message(Lang.t("heal_info_1"))

	if not heal_info_2_shown and game_time >= heal_info_2_time:
		heal_info_2_shown = true
		show_checkpoint_message(Lang.t("heal_info_2"))

	if not heal_info_3_shown and game_time >= heal_info_3_time:
		heal_info_3_shown = true
		show_checkpoint_message(Lang.t("heal_info_3"))

	if not heal_info_4_shown and game_time >= heal_info_4_time:
		heal_info_4_shown = true
		show_checkpoint_message(Lang.t("heal_info_4"))

	if mob_phase == 1 and game_time >= phase2_start_time:
		mob_phase = 2
		for m in get_tree().get_nodes_in_group("skeleton"):
			m.queue_free()

	if not checkpoint2_triggered and game_time >= checkpoint2_time:
		checkpoint2_triggered = true
		if is_instance_valid(player):
			player.health = player.MAX_HEALTH
		show_checkpoint_message(Lang.t("checkpoint_2"))

	if not boss_spawned and game_time >= boss_spawn_time:
		boss_spawned = true
		if is_instance_valid(player):
			player.health = player.MAX_HEALTH
		show_checkpoint_message(Lang.t("checkpoint_3"))
		for m in get_tree().get_nodes_in_group("mob"):
			if not m.is_in_group("boss"):
				m.queue_free()
		for g in get_tree().get_nodes_in_group("giant"):
			g.queue_free()
		arena_wall_right.disabled = false
		if is_instance_valid(player) and player.global_position.x > 1000:
			player.global_position.x = 850
		if boss_music and not boss_music_started:
			boss_music_started = true
			var fade_out = create_tween()
			fade_out.tween_property(background_music, "volume_db", -80.0, 1.0)
			fade_out.tween_callback(func():
				background_music.stream = boss_music
				background_music.play(boss_music_start_offset)
				var fade_in = create_tween()
				fade_in.tween_property(background_music, "volume_db", boss_music_volume, 1.0)
			)

	if not first_boss_actually_spawned and game_time >= first_boss_actual_spawn_time:
		first_boss_actually_spawned = true
		spawn_final_boss()

	if not second_boss_spawned and game_time >= second_boss_spawn_time:
		second_boss_spawned = true
		spawn_second_boss()

	if not victory_triggered and second_boss_spawned and get_tree().get_nodes_in_group("boss").size() == 0:
		victory_triggered = true
		trigger_victory()

	if not warning_message_shown and game_time >= warning_message_time:
		warning_message_shown = true
		show_warning_message(Lang.t("warning"))
		show_boss_instructions()

	if is_instance_valid(player):
		hp_bar.value = player.health
		update_time_label()

	# Случайное рычание босса, пока жив хотя бы один босс
	var boss_present_now = get_tree().get_nodes_in_group("boss").size() > 0
	if boss_present_now and not boss_was_present:
		# Босс только что появился - начинаем отсчёт с нуля именно сейчас
		boss_roar_timer = 0.0
		boss_roar_next_interval = randf_range(5.0, 8.0)
	boss_was_present = boss_present_now

	if boss_present_now:
		boss_roar_timer += delta
		if boss_roar_timer >= boss_roar_next_interval:
			boss_roar_timer = 0.0
			boss_roar_next_interval = randf_range(5.0, 8.0)
			Sound.play_boss_roar()

func trigger_checkpoint():
	checkpoint_triggered = true
	if is_instance_valid(player):
		player.health = player.MAX_HEALTH
	show_checkpoint_message(Lang.t("checkpoint_1"))

func fade_in_panel(panel: Control, duration: float = 0.3):
	panel.visible = true
	panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, duration)
	await t.finished

func fade_out_panel(panel: Control, duration: float = 0.3):
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 0.0, duration)
	await t.finished
	panel.visible = false

func show_checkpoint_message(text: String):
	Sound.play_checkpoint()
	checkpoint_label.text = text
	await fade_in_panel(checkpoint_panel)
	await get_tree().create_timer(3.0).timeout
	await fade_out_panel(checkpoint_panel)

func show_warning_message(text: String):
	warning_label.text = text
	await fade_in_panel(warning_panel)
	await get_tree().create_timer(3.0).timeout
	await fade_out_panel(warning_panel)

func trigger_victory():
	Sound.play_boss_breath()
	# Реакция босса красным цветом сразу после того, как оба побеждены - с плавным fade
	warning_label.text = Lang.t("boss_death_reaction")
	await fade_in_panel(warning_panel, 0.5)
	await get_tree().create_timer(2.0).timeout
	await fade_out_panel(warning_panel, 0.5)

	# Плавно выключаем боевую музыку, включаем весёлую музыку победы
	if victory_music:
		var music_fade_out = create_tween()
		music_fade_out.tween_property(background_music, "volume_db", -80.0, 0.5)
		await music_fade_out.finished
		background_music.stream = victory_music
		background_music.play()
		var music_fade_in = create_tween()
		music_fade_in.tween_property(background_music, "volume_db", victory_music_volume, 0.5)

	Sound.play_victory_sfx()
	victory_label.text = Lang.t("victory")
	victory_panel.visible = true
	victory_panel.scale = Vector2(0.3, 0.3)
	victory_panel.modulate.a = 0.0
	victory_panel.rotation_degrees = -8.0

	# Появление - выпрыгивает с пружинным эффектом и лёгким покачиванием
	var intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(victory_panel, "modulate:a", 1.0, 0.3)
	intro_tween.tween_property(victory_panel, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await intro_tween.finished

	# Живая пульсация, пока надпись висит на экране
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(victory_panel, "scale", Vector2(1.06, 1.06), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Музыка играет ~10 сек всего (0.5 fade-in + держим + 1 сек fade-out в конце)
	await get_tree().create_timer(8.5).timeout
	pulse_tween.kill()

	# Плавное затухание музыки и панели одновременно перед возвратом в меню
	var final_fade = create_tween()
	final_fade.set_parallel(true)
	final_fade.tween_property(background_music, "volume_db", -80.0, 1.0)
	final_fade.tween_property(victory_panel, "modulate:a", 0.0, 1.0)
	await final_fade.finished

	MenuMusic.fade_in_and_play(1.0)
	get_tree().change_scene_to_file("res://menu.tscn")

func show_boss_taunt(text: String):
	warning_label.text = text
	await fade_in_panel(warning_panel, 0.3)
	# без авто-скрытия - сцена перезагрузится через секунду сама

func show_boss_instructions():
	await get_tree().create_timer(2.0).timeout
	instruction_label.text = Lang.t("instruction")
	await fade_in_panel(instruction_panel)
	await get_tree().create_timer(6.0).timeout
	await fade_out_panel(instruction_panel)

func update_hp_bar_style():
	var hp_percent = float(player.health) / float(hp_bar.max_value)
	var fill_style = hp_bar.get_theme_stylebox("fill")
	if hp_percent <= 0.3:
		fill_style.texture = hurt_texture
	else:
		fill_style.texture = healthy_texture

func update_time_label():
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	var rec_min = int(record_time) / 60
	var rec_sec = int(record_time) % 60
	time_label.text = "⏱ %02d:%02d\n🏆 %02d:%02d" % [minutes, seconds, rec_min, rec_sec]

	var current_second = int(game_time)
	if current_second != last_saved_second:
		last_saved_second = current_second
		if game_time > record_time:
			record_time = game_time
			save_record(record_time)

func load_record() -> float:
	if FileAccess.file_exists("user://record.dat"):
		var f = FileAccess.open("user://record.dat", FileAccess.READ)
		var val = f.get_float()
		f.close()
		return val
	return 0.0

func save_record(value: float):
	var f = FileAccess.open("user://record.dat", FileAccess.WRITE)
	f.store_float(value)
	f.close()

func get_current_mob_speed() -> float:
	var base_speed = 50.0
	var steps = int(game_time / 10.0)  # каждые 10 сек +5 к скорости
	return min(base_speed + steps * 5.0, 130.0)

func get_current_mob_damage_range() -> Vector2i:
	var base_min = 1
	var base_max = 3
	var steps = int(game_time / 15.0)  # каждые 15 сек урон растёт
	var new_max = min(base_max + steps, 10)
	var new_min = min(base_min + steps / 2, 5)
	return Vector2i(new_min, new_max)

func get_phase2_mob_speed() -> float:
	var base_speed = 55.0
	var steps = int(game_time / 12.0)
	return min(base_speed + steps * 4.0, 110.0)

func get_phase2_mob_damage_range() -> Vector2i:
	var base_min = 1
	var base_max = 3
	var steps = int(game_time / 18.0)
	var new_max = min(base_max + steps, 9)
	var new_min = min(base_min + steps / 2, 5)
	return Vector2i(new_min, new_max)

func spawn_mob():
	var active_scene = mob_scene if mob_phase == 1 else phase2_mob_scene
	if active_scene == null:
		return
	if get_tree().get_nodes_in_group("mob").size() >= max_mobs:
		return
	var spawn_pos = Vector2(1800, 370)
	for mob in get_tree().get_nodes_in_group("mob"):
		if spawn_pos.distance_to(mob.global_position) < 80:
			return
	var mob = active_scene.instantiate()
	mob.global_position = spawn_pos
	if mob_phase == 1:
		mob.speed = get_current_mob_speed()
		var dmg_range = get_current_mob_damage_range()
		mob.damage_min = dmg_range.x
		mob.damage_max = dmg_range.y
	else:
		mob.speed = get_phase2_mob_speed()
		var dmg_range = get_phase2_mob_damage_range()
		mob.damage_min = dmg_range.x
		mob.damage_max = dmg_range.y
		mob.hits_to_kill = 3
	add_child(mob)

func spawn_final_boss():
	if final_boss_scene == null:
		return  # спрайтов/сцены пока нет - просто ничего не делаем
	var boss_spawn_pos = Vector2(150, 370)
	var boss = final_boss_scene.instantiate()
	boss.global_position = boss_spawn_pos
	if "is_first_attacker" in boss:
		boss.is_first_attacker = true
	add_child(boss)
	Sound.play_boss_roar()
	boss_roar_timer = 0.0
	boss_roar_next_interval = 8.0

func spawn_second_boss():
	if final_boss_scene == null:
		return
	var boss_spawn_pos = Vector2(850, 370)
	var boss = final_boss_scene.instantiate()
	boss.global_position = boss_spawn_pos
	if "is_first_attacker" in boss:
		boss.is_first_attacker = false
	add_child(boss)
	Sound.play_boss_roar()
	boss_roar_timer = 0.0
	boss_roar_next_interval = 8.0

func spawn_giant():
	if giant_scene == null:
		return
	if get_tree().get_nodes_in_group("giant").size() >= 3:
		return
	var giant_spawn_pos = Vector2(150, 370)
	var giant = giant_scene.instantiate()
	giant.global_position = giant_spawn_pos
	add_child(giant)
