extends Area2D
@export var value: int = 1
func _ready():
	body_entered.connect(_on_body_entered)
	if has_node("AnimatedSprite2D"):
		if $AnimatedSprite2D.sprite_frames.has_animation("default"):
			$AnimatedSprite2D.sprite_frames.set_animation_loop("default", true)
		$AnimatedSprite2D.play()
func _on_body_entered(body):
	if body.is_in_group("player"):
		Coins.add_coins(value)
		Sound.play_coin()
		queue_free()
