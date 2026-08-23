extends CharacterBody2D
@export var speed = 60.0
@export var damage_min: int = 2
@export var damage_max: int = 4
@export var attack_cooldown = 1.0
@export var hits_to_kill: int = 3
var target = null
var can_attack = true
var is_hurt = false
var is_dead = false
var hits_taken = 0
var retarget_timer = 0.0
@onready var sprite = $AnimatedSprite2D
const GRAVITY = 980.0
func _ready():
	add_to_group("mob")
	find_target()
func _physics_process(delta):
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	retarget_timer += delta
	if target == null or not is_instance_valid(target):
		find_target()
	elif retarget_timer >= 1.0:
		retarget_timer = 0.0
		find_target()
	if target == null or not is_instance_valid(target):
		move_and_slide()
		return
	if is_hurt:
		move_and_slide()
		return
	var dist = global_position.distance_to(target.global_position)
	if dist > 100:
		var direction = sign(target.global_position.x - global_position.x)
		velocity.x = direction * speed
		sprite.flip_h = direction < 0
		sprite.play("walk")
	else:
		velocity.x = 0
		sprite.play("attack")
		if can_attack:
			attack()
	move_and_slide()
func find_target():
	target = get_tree().get_first_node_in_group("player")
func attack():
	if not is_inside_tree() or is_dead:
		return
	can_attack = false
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree() or is_dead:
		return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 100:
		if target.has_method("take_damage"):
			var random_damage = randi_range(damage_min, damage_max)
			target.take_damage(random_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true
func take_damage(amount):
	if is_dead:
		return
	is_hurt = true
	hits_taken += 1
	if hits_taken >= hits_to_kill:
		die()
	else:
		sprite.play("hurt")
		await get_tree().create_timer(0.4).timeout
		is_hurt = false
func die():
	is_dead = true
	Sound.play_skeleton_death()
	sprite.play("die")
	await get_tree().create_timer(0.8).timeout
	queue_free()
