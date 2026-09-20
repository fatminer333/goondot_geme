extends SceneTree
func _init() -> void:
	assert(GameState.day == 1, "day должен быть 1")
	assert(GameState.money == 120, "старт 120cr")
	assert(DayNight.is_night == false, "старт днем")
	assert(DayNight.t_day == 600.0, "сутки 600с")
	print("boot OK")
	quit()
