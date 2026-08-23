extends CharacterBody2D

# Анимации есть только: idle, walk, attack (нет отдельной windup/hurt/die)
# windup визуально показываем через "attack" (сама анимация замаха и есть предупреждение)

@export var is_first_attacker: bool = true  # true = бьёт первым (Босс А, слева), false = Босс Б (справа)
@export var base_cycle_length: float = 4.0
@export var cycle_length_min: float = 2.6  # половина цикла (1.3 сек) - минимум, всё ещё вмещает замах с небольшим запасом
@export var cycle_length_step: float = 0.3  # насколько уменьшается каждые 15 сек (усилили эффект ещё больше)
@export var windup_time: float = 0.8  # будет автоматически подстроено под реальную длину анимации attack
@export var impact_frame_fraction: float = 0.7  # на какой доле анимации attack реально происходит удар (0.0-1.0) - подстрой если удар срабатывает позже/раньше видимого момента контакта
@export var vulnerable_time: float = 1.3
@export var sync_attack_interval: float = 15.0
@export var hits_to_kill: int = 15
@export var approach_speed: float = 60.0
@export var stand_distance: float = 300.0

enum State { IDLE, WINDUP, VULNERABLE }
var state = State.IDLE
var state_timer: float = 0.0
var is_sync_strike: bool = false

var is_dead: bool = false
var hits_taken: int = 0
var target: Node2D = null
var last_cycle_index: int = -1
var last_sync_index: int = -1
var has_struck_this_cycle: bool = false
var is_vulnerable: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBar
const GRAVITY = 980.0

func _ready():
	add_to_group("mob")
	add_to_group("boss")
	find_target()

	health_bar.max_value = hits_to_kill
	health_bar.value = hits_to_kill - hits_taken

	Sound.play_boss_roar()

	# ВАЖНО: синхронизируем индексы цикла с текущим игровым временем при спавне.
	# Без этого last_cycle_index/last_sync_index оставались -1, а Coins.game_time
	# в момент спавна босса (180 сек / 210 сек) уже большое число — из-за чего
	# в первом же _physics_process индекс "менялся" (X != -1) и босс мгновенно
	# уходил в WINDUP/атаку, ещё не подойдя к игроку.
	last_sync_index = int(Coins.game_time / sync_attack_interval)
	last_cycle_index = int(Coins.game_time / get_current_cycle_length())

	# Подстраиваем windup_time под реальную длину анимации attack,
	# чтобы удар не обрывал её раньше времени (учитываем и Speed Scale спрайта)
	if sprite.sprite_frames.has_animation("attack"):
		var fc = sprite.sprite_frames.get_frame_count("attack")
		var fps = sprite.sprite_frames.get_animation_speed("attack")
		var speed_scale = sprite.speed_scale if sprite.speed_scale > 0 else 1.0
		if fps > 0:
			windup_time = ((float(fc) / fps) / speed_scale) * impact_frame_fraction  # удар срабатывает не в конце анимации, а на указанной доле
			print("Длина анимации attack: ", windup_time, " сек (кадров=", fc, " fps=", fps, " speed_scale=", speed_scale, ")")

func find_target():
	target = get_tree().get_first_node_in_group("player")

func get_current_cycle_length() -> float:
	var steps = int(Coins.game_time / 15.0)  # каждые 15 сек цикл короче (сложнее)
	return max(cycle_length_min, base_cycle_length - steps * cycle_length_step)

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	if target == null or not is_instance_valid(target):
		find_target()

	# --- Смотрим на игрока и подходим, пока ждём (IDLE) ---
	var is_walking = false
	if target and is_instance_valid(target):
		var dx = target.global_position.x - global_position.x
		sprite.flip_h = dx < 0
		if state == State.IDLE and abs(dx) > stand_distance:
			velocity.x = sign(dx) * approach_speed
			is_walking = true
		else:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()

	# --- Синхронная одновременная атака раз в N секунд ---
	var sync_index = int(Coins.game_time / sync_attack_interval)
	if sync_index != last_sync_index:
		last_sync_index = sync_index
		state = State.WINDUP
		state_timer = 0.0
		is_sync_strike = true
		sprite.play("attack")

	# --- Обычная очередь (кто сейчас бьёт по расписанию) ---
	var cycle_length = get_current_cycle_length()
	var cycle_index = int(Coins.game_time / cycle_length)
	var cycle_time = fmod(Coins.game_time, cycle_length)
	var half = cycle_length / 2.0
	var my_turn_to_attack: bool
	if is_first_attacker:
		my_turn_to_attack = cycle_time < half
	else:
		my_turn_to_attack = cycle_time >= half

	if cycle_index != last_cycle_index:
		last_cycle_index = cycle_index
		has_struck_this_cycle = false

	state_timer += delta

	match state:
		State.IDLE:
			is_vulnerable = false
			if is_walking:
				if sprite.animation != "walk":
					sprite.play("walk")
			else:
				if sprite.animation != "idle":
					sprite.play("idle")
			if my_turn_to_attack and not has_struck_this_cycle:
				state = State.WINDUP
				state_timer = 0.0
				is_sync_strike = false
				sprite.play("attack")

		State.WINDUP:
			is_vulnerable = false
			if state_timer >= windup_time:
				strike()
				has_struck_this_cycle = true
				if is_sync_strike:
					state = State.IDLE
					state_timer = 0.0
				else:
					state = State.VULNERABLE
					state_timer = 0.0

		State.VULNERABLE:
			is_vulnerable = true
			if sprite.animation != "idle":
				sprite.play("idle")
			if state_timer >= vulnerable_time:
				is_vulnerable = false
				state = State.IDLE
				state_timer = 0.0

func strike():
	if target and is_instance_valid(target):
		var player_grounded = false
		if target.has_method("was_recently_on_floor"):
			player_grounded = target.was_recently_on_floor()
		else:
			player_grounded = target.is_on_floor()
		if not player_grounded:
			print("Игрок увернулся - был в воздухе в момент удара")
			return  # игрок был в воздухе именно в момент удара - увернулся
		if target.has_method("take_damage"):
			print("Удар попал - игрок стоял на земле в момент удара")
			target.take_damage(target.MAX_HEALTH)  # мгновенная смерть

func take_damage(amount):
	print("Игрок пытается ударить босса: is_dead=", is_dead, " is_vulnerable=", is_vulnerable, " state=", state, " hits_taken=", hits_taken)
	if is_dead or not is_vulnerable:
		print("Удар НЕ засчитан - босс не уязвим")
		return
	hits_taken += 1
	health_bar.value = hits_to_kill - hits_taken
	print("Удар засчитан! hits_taken теперь = ", hits_taken, " / ", hits_to_kill)
	if hits_taken >= hits_to_kill:
		die()

func die():
	is_dead = true
	set_physics_process(false)
	health_bar.visible = false
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
