extends SceneTree
# Сквозной флоу: захват (T1) -> настройка (T2) -> продажа (T3) -> квота.
func _init() -> void:
	GameState.day = 1
	GameState.money = 120
	SignalManager.captured.clear()
	var s: Resource = SignalManager.capture_new(42.0, 180.0, 1)
	var sid := str(s.get("id"))
	assert(SignalManager.first_untuned() != null, "есть что настраивать")
	assert(SignalManager.mark_tuned(sid), "настроен")
	assert(Economy.sell(sid) == 50, "продан за 50")
	assert(GameState.money == 170, "баланс 170")
	assert(Economy.quota_for(1) == 80, "квота Д1 80")
	print("full flow OK money=", GameState.money)
	quit()
