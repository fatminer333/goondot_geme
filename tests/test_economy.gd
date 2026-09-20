extends SceneTree
# Квоты и продажа настроенного сигнала (+50 кр).
func _init() -> void:
	assert(Economy.quota_for(1) == 80, "квота Д1 80")
	assert(Economy.quota_for(2) == 130, "квота Д2 130")
	assert(Economy.quota_for(10) == 350, "кап 350")
	GameState.money = 120
	SignalManager.captured.clear()
	var s: Resource = SignalManager.capture_new(50.0, 0.0, 1)
	SignalManager.mark_tuned(str(s.get("id")))
	assert(Economy.sell("нет_такого") == 0, "чужой id = 0")
	var price: int = Economy.sell(str(s.get("id")))
	assert(price == 50, "цена 50")
	assert(GameState.money == 170, "120+50=170")
	print("economy OK")
	quit()
