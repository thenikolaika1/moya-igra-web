extends CharacterBody2D
const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const MAX_HEALTH = 100
const HEAL_AMOUNT = 12
const HEAL_COST = 2
var is_attacking = false
var health = 100
var is_hurt = false
var floor_grace_timer: float = 0.0
const FLOOR_GRACE_TIME: float = 0.12  # буфер против ложного мигания is_on_floor()
func _ready():
	add_to_group("player")
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		print("K нажата, монет сейчас: ", Coins.coins, " здоровье: ", health)
		try_heal()
func try_heal():
	if health >= MAX_HEALTH:
		print("Лечение не нужно, здоровье полное")
		return
	var cost = HEAL_COST
	if Coins.game_time >= 120.0 and Coins.game_time < 180.0:
		cost = 1  # с 2:00 до 3:00 лечение дешевле - 1 монета
	if Coins.spend(cost):
		var heal_amount = HEAL_AMOUNT
		if Coins.game_time >= 90.0 and Coins.game_time < 115.0:
			heal_amount = 17  # бонусное окно 1:30-1:55
		elif Coins.game_time >= 120.0 and Coins.game_time < 150.0:
			heal_amount = 9  # с 2:00 до 2:30 - 1 монета лечит 9 HP
		elif Coins.game_time >= 150.0 and Coins.game_time < 180.0:
			heal_amount = 9  # с 2:30 до 3:00 - 1 монета лечит 9 HP
		health = min(MAX_HEALTH, health + heal_amount)
		print("Вылечено, новое здоровье: ", health, " монет осталось: ", Coins.coins)
	else:
		print("Не хватает монет для лечения")
func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		floor_grace_timer = FLOOR_GRACE_TIME
	else:
		floor_grace_timer = max(0.0, floor_grace_timer - delta)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		Sound.play_jump()
	if Input.is_action_just_pressed("Attack") and not is_attacking:
		is_attacking = true
		is_hurt = false
		$AnimatedSprite2D.animation = "Attack"
		$AnimatedSprite2D.play()
		Sound.play_sword_hit()
		attack_mobs()
	if is_attacking and not $AnimatedSprite2D.is_playing():
		is_attacking = false
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if not is_attacking and not is_hurt:
			$AnimatedSprite2D.animation = "Run"
			$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_attacking and not is_hurt:
			$AnimatedSprite2D.animation = "Idle"
			$AnimatedSprite2D.play()
	move_and_slide()
func attack_mobs():
	var mobs = get_tree().get_nodes_in_group("mob")
	for mob in mobs:
		# Считаем дистанцию только по горизонтали (X) - разница по высоте
		# не должна мешать попаданию, это 2D-платформер, а не top-down
		var dist = abs(global_position.x - mob.global_position.x)
		print("Атака: дистанция до ", mob.name, " = ", dist, " (нужно < 160)")
		if dist < 160:
			mob.take_damage(1)
func take_damage(amount):
	if is_hurt:
		return
	is_hurt = true
	is_attacking = false
	health -= amount
	if health <= 0:
		Coins.coins = 0
		$AnimatedSprite2D.play("die")
		Sound.play_boss_laugh()
		var level = get_parent()
		if level and level.has_method("show_boss_taunt"):
			var taunt_keys = ["taunt_1", "taunt_2", "taunt_3"]
			level.show_boss_taunt(Lang.t(taunt_keys[randi() % taunt_keys.size()]))
			await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()
	else:
		$AnimatedSprite2D.play("hurt")
		await get_tree().create_timer(0.3).timeout
		is_hurt = false

func was_recently_on_floor() -> bool:
	return floor_grace_timer > 0.0
