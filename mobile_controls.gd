extends Control

@onready var left_button = $LeftButton
@onready var right_button = $RightButton
@onready var jump_button = $JumpButton
@onready var attack_button = $AttackButton
@onready var heal_button = $HealButton
@onready var size_up_button = $SizeUpButton
@onready var size_down_button = $SizeDownButton

var buttons = []
var default_positions = {}
var default_sizes = {}
var customize_mode = false
var dragging_button = null
var drag_offset = Vector2.ZERO
var selected_button = null

const SIZE_STEP = 10.0
const MIN_SIZE = 40.0
const MAX_SIZE = 160.0
const SAVE_PATH = "user://mobile_controls_positions.json"
const HIDDEN_SAVE_PATH = "user://mobile_controls_hidden.json"
const SIZE_SAVE_PATH = "user://mobile_controls_sizes.json"

func _ready():
	print("MobileControls: _ready() запущен")
	buttons = [left_button, right_button, jump_button, attack_button, heal_button]

	# Запоминаем изначальные позиции и размеры, расставленные в редакторе, ДО загрузки сохранённых
	for b in buttons:
		default_positions[b.name] = b.position
		default_sizes[b.name] = b.size.x

	load_positions()
	load_sizes()
	visible = not load_hidden_state()

	size_up_button.pressed.connect(_on_size_up_pressed)
	size_down_button.pressed.connect(_on_size_down_pressed)
	size_up_button.visible = false
	size_down_button.visible = false

	left_button.button_down.connect(_on_left_down)
	left_button.button_up.connect(_on_left_up)
	right_button.button_down.connect(_on_right_down)
	right_button.button_up.connect(_on_right_up)
	jump_button.button_down.connect(_on_jump_down)
	jump_button.button_up.connect(_on_jump_up)
	attack_button.button_down.connect(_on_attack_down)
	attack_button.button_up.connect(_on_attack_up)
	heal_button.pressed.connect(_on_heal_pressed)

func _on_left_down():
	if not customize_mode:
		Input.action_press("ui_left")
func _on_left_up():
	Input.action_release("ui_left")
func _on_right_down():
	if not customize_mode:
		Input.action_press("ui_right")
func _on_right_up():
	Input.action_release("ui_right")
func _on_jump_down():
	if not customize_mode:
		Input.action_press("ui_accept")
func _on_jump_up():
	Input.action_release("ui_accept")
func _on_attack_down():
	if not customize_mode:
		Input.action_press("Attack")
func _on_attack_up():
	Input.action_release("Attack")

func _on_heal_pressed():
	if customize_mode:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("try_heal"):
		player.try_heal()

func _input(event):
	if not customize_mode:
		return
	if event is InputEventMouseButton:
		print("MobileControls: клик мышью, pressed=", event.pressed, " pos=", event.position)
		if event.pressed:
			for b in buttons:
				if b.get_global_rect().has_point(event.position):
					dragging_button = b
					drag_offset = b.global_position - event.position
					select_button(b)
					print("MobileControls: начали тащить ", b.name)
					get_viewport().set_input_as_handled()
					break
		else:
			dragging_button = null
	elif event is InputEventMouseMotion:
		if dragging_button:
			dragging_button.global_position = event.position + drag_offset
			position_size_controls(dragging_button)
			get_viewport().set_input_as_handled()

func select_button(b):
	selected_button = b
	size_up_button.visible = true
	size_down_button.visible = true
	position_size_controls(b)

func position_size_controls(b):
	# Ставим "+" и "-" прямо над выбранной кнопкой, по бокам
	var top_center = b.position + Vector2(b.size.x / 2.0, -50)
	size_up_button.position = top_center + Vector2(10, 0)
	size_down_button.position = top_center + Vector2(-50, 0)

func _on_size_up_pressed():
	if selected_button:
		change_button_size(selected_button, SIZE_STEP)

func _on_size_down_pressed():
	if selected_button:
		change_button_size(selected_button, -SIZE_STEP)

func change_button_size(b, delta):
	var new_size = max(10.0, b.size.x + delta)  # защита от нулевого/отрицательного размера, не дизайн-ограничение
	b.size = Vector2(new_size, new_size)
	b.custom_minimum_size = Vector2(new_size, new_size)
	var radius = int(new_size / 2.0)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var stylebox = b.get_theme_stylebox(style_name)
		if stylebox is StyleBoxFlat:
			stylebox.corner_radius_top_left = radius
			stylebox.corner_radius_top_right = radius
			stylebox.corner_radius_bottom_right = radius
			stylebox.corner_radius_bottom_left = radius
	position_size_controls(b)
	save_sizes()

func toggle_visibility() -> bool:
	visible = !visible
	save_hidden_state(!visible)
	return visible

func save_hidden_state(hidden: bool):
	var f = FileAccess.open(HIDDEN_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hidden": hidden}))
	f.close()

func load_hidden_state() -> bool:
	if not FileAccess.file_exists(HIDDEN_SAVE_PATH):
		return false
	var f = FileAccess.open(HIDDEN_SAVE_PATH, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null or not data.has("hidden"):
		return false
	return data["hidden"]

func reset_positions():
	for b in buttons:
		if default_positions.has(b.name):
			b.position = default_positions[b.name]
		if default_sizes.has(b.name):
			change_button_size(b, default_sizes[b.name] - b.size.x)
	save_positions()
	print("MobileControls: позиции и размеры сброшены к изначальным")

func enable_customize():
	print("MobileControls: enable_customize() вызван, customize_mode=true")
	customize_mode = true

func disable_customize():
	print("MobileControls: disable_customize() вызван")
	customize_mode = false
	dragging_button = null
	selected_button = null
	size_up_button.visible = false
	size_down_button.visible = false
	save_positions()
	save_sizes()

func save_positions():
	var data = {}
	for b in buttons:
		data[b.name] = {"x": b.position.x, "y": b.position.y}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	print("MobileControls: позиции сохранены")

func load_positions():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null:
		return
	for b in buttons:
		if data.has(b.name):
			b.position = Vector2(data[b.name]["x"], data[b.name]["y"])

func save_sizes():
	var data = {}
	for b in buttons:
		data[b.name] = b.size.x
	var f = FileAccess.open(SIZE_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	print("MobileControls: размеры сохранены")

func load_sizes():
	if not FileAccess.file_exists(SIZE_SAVE_PATH):
		return
	var f = FileAccess.open(SIZE_SAVE_PATH, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null:
		return
	for b in buttons:
		if data.has(b.name):
			change_button_size(b, data[b.name] - b.size.x)
