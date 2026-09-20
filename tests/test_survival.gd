extends SceneTree
func _init() -> void:
	Survival.hunger = 100.0
	Survival._process(480.0)
	assert(Survival.hunger <= 1.0, "голод должен упасть за 480с")
	Survival.eat(45.0)
	assert(Survival.hunger > 40.0, "еда +45")
	GameState.money = 10
	var ok: bool = Shop.buy("mre")
	assert(ok == false, "без денег отказ")
	assert(GameState.money == 10, "деньги не в минус")
	Breakdowns.wear["server"] = 100.0
	assert(Breakdowns.server_can_process() == false, "сломанный сервер блокирует")
	print("survival/shop/break OK")
	quit()
