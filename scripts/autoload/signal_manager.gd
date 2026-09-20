extends Node
# Очередь захваченных сигналов (линейка Терминалов 1-3).
# T1 кладёт через capture_new, T2 настраивает через mark_tuned, T3 продаёт через Economy.sell.
var captured: Array = []
var _counter: int = 0

func capture_new(freq: float, pol_deg: float, pol_sign: int) -> Resource:
	var s := CapturedSignal.new()
	_counter += 1
	s.id = "cap_%d" % _counter
	s.name_ru = "Сигнал %d" % _counter
	s.freq_mhz = clampf(freq, 1.0, 100.0)
	s.polarity_deg = clampf(pol_deg, 0.0, 360.0)
	s.polarity_sign = 1 if pol_sign >= 0 else -1
	s.state = 0
	s.reward = 50
	captured.append(s)
	EventBus.signal_detected.emit(s.id)
	return s

func first_untuned() -> Resource:
	for s in captured:
		if int((s as Resource).get("state")) == 0:
			return s
	return null

func tuned_for_sale() -> Array:
	var out: Array = []
	for s in captured:
		if int((s as Resource).get("state")) == 1:
			out.append(s)
	return out

func get_by_id(id: String) -> Resource:
	for s in captured:
		if str((s as Resource).get("id")) == id:
			return s
	return null

func mark_tuned(id: String) -> bool:
	var s := get_by_id(id)
	if s == null:
		return false
	s.set("state", 1)
	EventBus.signal_processed.emit(id, 1.0)
	return true

func remove_captured(id: String) -> bool:
	for i in captured.size():
		if str((captured[i] as Resource).get("id")) == id:
			captured.remove_at(i)
			return true
	return false
