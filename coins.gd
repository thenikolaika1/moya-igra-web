extends Node

# Глобальный счётчик монет - доступен из любого скрипта как Coins.xxx

signal coins_changed(new_amount: int)

var coins: int = 0
var giants_killed: int = 0
var game_time: float = 0.0  # обновляется из level.gd, нужен другим скриптам (например giant.gd)

func add_coins(amount: int = 1):
	coins += amount
	coins_changed.emit(coins)

func spend(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func register_giant_kill() -> bool:
	# Возвращает true каждый второй раз - гарантированный дроп монеты
	giants_killed += 1
	return giants_killed % 2 == 0
