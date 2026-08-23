extends Sprite2D

@export var max_health = 100
var health = max_health

func take_damage(amount):
	health -= amount
	print("Дом получил урон, осталось HP: ", health)
	if health <= 0:
		die()

func die():
	print("Дом разрушен!")
	get_tree().change_scene_to_file("res://menu.tscn")
