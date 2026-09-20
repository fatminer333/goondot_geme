extends SceneTree
func _init() -> void:
	# День: страха нет, add_fear игнорируется.
	DayNight.time_06_24 = 12.0
	DayNight.is_night = false
	HorrorDirector.fear = 50.0
	HorrorDirector._process(1.0)
	assert(HorrorDirector.fear < 50.0, "днем страх спадает")
	HorrorDirector.fear = 0.0
	HorrorDirector.add_fear(50.0)
	assert(HorrorDirector.fear == 0.0, "днем add_fear игнорируется")
	# Ночь 00-05: страх растет.
	DayNight.time_06_24 = 2.0
	DayNight.is_night = true
	HorrorDirector.fear = 0.0
	HorrorDirector.add_fear(80.0)
	assert(HorrorDirector.fear == 80.0, "ночью страх растет")
	# Вне 00-05 (05:30, ночь по DayNight но не хоррор-час): add_fear игнорируется.
	DayNight.time_06_24 = 5.5
	DayNight.is_night = true
	HorrorDirector.fear = 10.0
	HorrorDirector.add_fear(50.0)
	assert(HorrorDirector.fear == 10.0, "вне 00-05 страха нет")
	# Бюджет: 2 +1/ночь, кап 6.
	HorrorDirector.refresh_budget(1)
	assert(HorrorDirector.budget == 2, "бюджет Д1 = 2")
	HorrorDirector.refresh_budget(5)
	assert(HorrorDirector.budget == 6, "бюджет Д5 кап 6")
	HorrorDirector.refresh_budget(10)
	assert(HorrorDirector.budget == 6, "бюджет кап 6")
	# Контакт днём: урона-похищения нет, −30 статов.
	DayNight.time_06_24 = 12.0
	DayNight.is_night = false
	GameState.failed = false
	Survival.hunger = 100.0
	Survival.fatigue = 100.0
	HorrorDirector.fear = 0.0
	HorrorDirector.on_contact()
	assert(GameState.failed == false, "днем похищения нет")
	assert(Survival.hunger == 70.0, "днем контакт −30 голод")
	assert(Survival.fatigue == 70.0, "днем контакт −30 усталость")
	# Контакт ночью при страхе >70: похищение = fail.
	DayNight.time_06_24 = 2.0
	DayNight.is_night = true
	GameState.failed = false
	HorrorDirector.fear = 80.0
	HorrorDirector.on_contact()
	assert(GameState.failed == true, "ночью при fear>70 похищение")
	GameState.failed = false
	# Сломанный сервер блокирует обработку (spec authority, новое имя).
	Breakdowns.wear["server"] = 100.0
	assert(Breakdowns.server_can_process() == false, "сломанный сервер блокирует")
	Breakdowns.wear["server"] = 0.0
	print("horror OK")
	quit()
