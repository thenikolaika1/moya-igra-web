extends Node2D

@onready var ru_button = $RuButton
@onready var en_button = $EnButton
@onready var play_button = $PLAY
@onready var quit_button = $QUIT

func _ready():
	update_texts()
	update_language_buttons()
	Sound.connect_click_sounds(self)

func _on_quit_pressed():
	get_tree().quit()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _on_ru_button_pressed():
	Lang.set_language("ru")
	update_texts()
	update_language_buttons()

func _on_en_button_pressed():
	Lang.set_language("en")
	update_texts()
	update_language_buttons()

func update_texts():
	play_button.text = Lang.t("play")
	quit_button.text = Lang.t("quit")

func update_language_buttons():
	# Активный язык - белый цвет текста, неактивный - жёлтый
	var yellow = Color("FFD700")
	var white = Color(1, 1, 1)
	if Lang.current == "ru":
		ru_button.add_theme_color_override("font_color", white)
		en_button.add_theme_color_override("font_color", yellow)
	else:
		en_button.add_theme_color_override("font_color", white)
		ru_button.add_theme_color_override("font_color", yellow)
