extends Node
# Task 5: HorrorDirector — страх активен только 00:00-05:00 ночью.
# budget: 2 +1/ночь, кап 6. fear: 0-100.
var fear: float = 0.0
var budget: int = 2

func is_horror_hour() -> bool:
	var dn: Node = get_node_or_null("/root/DayNight")
	if dn == null:
		return false
	var t: float = float(dn.get("time_06_24"))
	return t >= 0.0 and t < 5.0

func is_active() -> bool:
	var dn: Node = get_node_or_null("/root/DayNight")
	if dn == null:
		return false
	return bool(dn.get("is_night")) and is_horror_hour()

func _process(delta: float) -> void:
	if not is_active():
		# Днём и вне 00-05: страх спадает быстро.
		fear = maxf(0.0, fear - 10.0 * delta)
		return
	# Ночью 00-05: медленный пассивный рост (баланс: ~0.8/с => ~160 за ночь, кап 100).
	fear = clampf(fear + 0.8 * delta, 0.0, 100.0)

func add_fear(a: float) -> void:
	if is_active():
		fear = clampf(fear + a, 0.0, 100.0)

func refresh_budget(day: int) -> void:
	budget = mini(6, 2 + maxi(0, day - 1))

func on_night_started() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: int = 1
	if gs != null:
		day = int(gs.get("day"))
	refresh_budget(day)

func on_contact() -> void:
	var eb: Node = get_node_or_null("/root/EventBus")
	if eb != null:
		eb.emit_signal("anomaly_contact")
	if is_active() and fear > 70.0:
		var gs: Node = get_node_or_null("/root/GameState")
		if gs != null:
			gs.call("fail", "похищение")
	else:
		# Контакт днём или при низком страхе: −30 к статам, без похищения.
		var sv: Node = get_node_or_null("/root/Survival")
		if sv != null:
			sv.set("hunger", maxf(0.0, float(sv.get("hunger")) - 30.0))
			sv.set("fatigue", maxf(0.0, float(sv.get("fatigue")) - 30.0))

func reset() -> void:
	fear = 0.0
	budget = 2
