extends Node2D

@onready var title_label = $TutorialTitleLabel
@onready var move_label = $ControlMoveLabel
@onready var jump_label = $ControlJumpLabel
@onready var attack_label = $ControlAttackLabel
@onready var heal_label = $ControlHealLabel
@onready var skip_button = $SkipButton

func _ready():
	title_label.text = Lang.t("tutorial_title")
	move_label.text = Lang.t("control_move")
	jump_label.text = Lang.t("control_jump")
	attack_label.text = Lang.t("control_attack")
	heal_label.text = Lang.t("control_heal")
	skip_button.text = Lang.t("skip")
	Sound.connect_click_sounds(self)

func _on_skip_button_pressed():
	MenuMusic.fade_out_and_stop(1.0)
	get_tree().change_scene_to_file("res://level.tscn")
