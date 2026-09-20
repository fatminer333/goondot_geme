extends Node
func quota_for(day: int) -> int:
	match day:
		1:
			return 80
		2:
			return 130
		3:
			return 180
		_:
			return mini(350, 180 + (day - 3) * 50)

func sell(id: String) -> int:
	# Продажа только настроенного (state == 1) сигнала из очереди SignalManager.
	var s: Resource = SignalManager.get_by_id(id)
	if s == null:
		return 0
	if int(s.get("state")) != 1:
		push_warning("Продажа только настроенного")
		return 0
	var price: int = int(s.get("reward"))
	GameState.money += price
	SignalManager.remove_captured(id)
	EventBus.signal_sold.emit(id, price)
	return price

func apply_day_result(sold_today: int, day: int) -> Dictionary:
	var q: int = quota_for(day)
	var debt: int = maxi(0, q - sold_today)
	return {"quota": q, "sold": sold_today, "debt": debt, "failed": debt > 0}
