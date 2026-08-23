extends CharacterBody2D
# --- Настройки (можно крутить в инспекторе) ---
@export var speed: float = 40.0
@export var damage_min: int = 5
@export var damage_max: int = 10
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 2.0
@export var attack_hit_delay: float = 0.4
@export var gravity: float = 900.0
@export var hits_to_kill: int = 5
@export var coin_scene: PackedScene
@export var walk_sound_interval: float = 0.5  # как часто звучит шаг, пока гигант идёт
var hits_taken: int = 0
var target: Node2D = null
var can_attack: bool = true
var is_dead: bool = false
var walk_sound_timer: float = 0.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
func _ready():
	add_to_group("giant")
	add_to_group("mob")  # чтобы атака игрока (которая ищет группу mob) видела и гиганта
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)
	# attack/hit не должны зацикливаться сами - иначе играют по кругу, пока идёт cooldown
	if sprite.sprite_frames.has_animation("attack"):
		sprite.sprite_frames.set_animation_loop("attack", false)
	if sprite.sprite_frames.has_animation("hit"):
		sprite.sprite_frames.set_animation_loop("hit", false)
func _physics_process(delta):
	if is_dead:
		return
	# Гравитация - держит гиганта на земле, не даёт "парить"
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0  # пока падает - не едет по горизонтали, чтобы не проскочить мимо цели в воздухе
		move_and_slide()
		return
	else:
		velocity.y = 0
	find_target()
	if target == null or not is_instance_valid(target):
		velocity.x = 0
		walk_sound_timer = 0.0
		if sprite.animation != "idle":
			sprite.play("idle")
		move_and_slide()
		return
	# Двигаемся только по горизонтали к цели, вертикаль решает гравитация
	var distance_x = abs(global_position.x - target.global_position.x)
	var should_be_still = false
	if distance_x <= attack_range:
		velocity.x = 0
		walk_sound_timer = 0.0
		should_be_still = true
		if can_attack:
			attack()
	else:
		var dir_x = sign(target.global_position.x - global_position.x)
		velocity.x = dir_x * speed
		sprite.flip_h = dir_x < 0
		if sprite.animation != "move":
			sprite.play("move")
	var pos_before_move = global_position
	move_and_slide()
	if should_be_still:
		# Пока гигант стоит на месте/атакует - полностью блокируем позицию (X и Y),
		# чтобы давление игрока не "подбрасывало" его на стыке состояний
		global_position = pos_before_move
func find_target():
	# Гигант теперь идёт за игроком, дом больше не трогает
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	else:
		target = null
func attack():
	if not can_attack or is_dead or not is_inside_tree():
		return
	can_attack = false
	sprite.play("attack")
	await get_tree().create_timer(attack_hit_delay).timeout
	if is_dead or not is_inside_tree():
		return
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		var dmg = randi_range(damage_min, damage_max)
		target.take_damage(dmg)
	await get_tree().create_timer(max(0.0, attack_cooldown - attack_hit_delay)).timeout
	if is_instance_valid(self) and is_inside_tree() and not is_dead:
		can_attack = true
func take_damage(amount: int):
	if is_dead:
		return
	hits_taken += 1
	sprite.play("hit")
	if hits_taken >= hits_to_kill:
		die()
func die():
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	Sound.play_giant_death()
	# Каждый второй убитый гигант гарантированно роняет монету,
	# в окне 1:30-1:55 монету роняет КАЖДЫЙ убитый гигант, и она стоит 2,
	# а после 2:00 монету тоже роняет КАЖДЫЙ, но обычным номиналом 1
	var in_bonus_window = Coins.game_time >= 90.0 and Coins.game_time < 115.0
	var after_2min = Coins.game_time >= 120.0
	var should_drop_coin = Coins.register_giant_kill()
	if in_bonus_window or after_2min:
		should_drop_coin = true
	if should_drop_coin and coin_scene != null:
		var coin = coin_scene.instantiate()
		var drop_y = target.global_position.y if target and is_instance_valid(target) else global_position.y
		coin.global_position = Vector2(global_position.x, drop_y)
		coin.value = 2 if in_bonus_window else 1
		get_parent().add_child(coin)
	# Нет спрайта смерти -> плавно исчезаем
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
func _on_animation_finished():
	# После attack/hit возвращаемся в idle, дальше _physics_process сам решит idle/move
	if sprite.animation == "attack" or sprite.animation == "hit":
		if not is_dead:
			sprite.play("idle")
