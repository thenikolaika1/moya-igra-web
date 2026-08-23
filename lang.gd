extends Node

var current: String = "ru"

var strings = {
	"pause_title": {"ru": "ПАУЗА", "en": "PAUSE"},
	"resume": {"ru": "ПРОДОЛЖИТЬ", "en": "RESUME"},
	"menu": {"ru": "В МЕНЮ", "en": "MENU"},
	"checkpoint_1": {"ru": "Ты продержался 1 минуту", "en": "You've survived 1 minute"},
	"checkpoint_2": {"ru": "Ты продержался 2 минуты", "en": "You've survived 2 minutes"},
	"checkpoint_3": {"ru": "Ты продержался 3 минуты", "en": "You've survived 3 minutes"},
	"heal_info_1": {"ru": "2 монеты = 12 HP", "en": "2 coins = 12 HP"},
	"heal_info_2": {"ru": "2 монеты = 17 HP", "en": "2 coins = 17 HP"},
	"heal_info_3": {"ru": "1 монета = 9 HP", "en": "1 coin = 9 HP"},
	"heal_info_4": {"ru": "1 монета = 9 HP", "en": "1 coin = 9 HP"},
	"warning": {"ru": "Ты зашёл слишком далеко... время встретиться с ним...", "en": "You've gone too far... time to meet him..."},
	"instruction": {"ru": "Прыгай во время его замаха прямо перед ударом, чтобы увернуться!\nПосле удара есть 1 сек, чтобы ударить его!", "en": "Jump during his windup right before the strike to dodge!\nAfter the hit, you have 1 sec to strike back!"},
	"taunt_1": {"ru": "Слабак...", "en": "Weakling..."},
	"taunt_2": {"ru": "Это всё, на что ты способен?", "en": "Is that all you've got?"},
	"taunt_3": {"ru": "Возвращайся, когда научишься сражаться.", "en": "Come back when you've learned to fight."},
	"play": {"ru": "ИГРАТЬ", "en": "PLAY"},
	"quit": {"ru": "ВЫХОД", "en": "QUIT"},
	"victory": {"ru": "🎉 Ты прошёл игру! 🎉", "en": "🎉 You've completed the game! 🎉"},
	"boss_death_reaction": {"ru": "Как ты это сделал...", "en": "How did you do this..."},
	"tutorial_title": {"ru": "Управление", "en": "Controls"},
	"control_move": {"ru": "A / D — движение", "en": "A / D — move"},
	"control_jump": {"ru": "Space — прыжок", "en": "Space — jump"},
	"control_attack": {"ru": "J — атака", "en": "J — attack"},
	"control_heal": {"ru": "K — лечение (за монеты)", "en": "K — heal (costs coins)"},
	"skip": {"ru": "ПРОПУСТИТЬ", "en": "SKIP"},
	"hide_controls": {"ru": "СКРЫТЬ КНОПКИ УПРАВЛЕНИЯ", "en": "HIDE CONTROL BUTTONS"},
	"show_controls": {"ru": "ПОКАЗАТЬ КНОПКИ УПРАВЛЕНИЯ", "en": "SHOW CONTROL BUTTONS"},
	"customize_controls": {"ru": "НАСТРОИТЬ КНОПКИ УПРАВЛЕНИЯ", "en": "CUSTOMIZE CONTROL BUTTONS"},
	"done_customize": {"ru": "ГОТОВО", "en": "DONE"},
	"reset_controls": {"ru": "ВЕРНУТЬ ИЗНАЧАЛЬНОЕ РАСПОЛОЖЕНИЕ", "en": "RESET TO DEFAULT POSITIONS"},
}

func t(key: String) -> String:
	if strings.has(key):
		return strings[key][current]
	return key

func set_language(lang: String):
	current = lang
	save_language()

func save_language():
	var f = FileAccess.open("user://lang.dat", FileAccess.WRITE)
	f.store_string(current)
	f.close()

func load_language():
	if FileAccess.file_exists("user://lang.dat"):
		var f = FileAccess.open("user://lang.dat", FileAccess.READ)
		var val = f.get_as_text().strip_edges()
		f.close()
		if val == "ru" or val == "en":
			current = val

func _ready():
	load_language()
