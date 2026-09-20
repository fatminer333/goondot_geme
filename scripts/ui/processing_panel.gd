extends Control
const LOCK_TIME: float = 3.0
var selected_id: String = ""
var lock_progress: float = 0.0
func _ready() -> void:
	position = Vector2(420, 60)
	size = Vector2(360, 300)
	var fix: Button = get_node_or_null("FixButton") as Button
	if fix != null:
		fix.pressed.connect(_on_fix)
	var sell: Button = get_node_or_null("SellButton") as Button
	if sell != null:
		sell.pressed.connect(_on_sell)
	# Раскладка детей: до этого все лежали в (0,0) друг на друге.
	var title_lab: Label = get_node_or_null("TitleLabel") as Label
	if title_lab != null:
		title_lab.position = Vector2(0, 0)
		title_lab.size = Vector2(360, 24)
		title_lab.text = "Обработка: выбери сигнал слева"
	var freq_lab: Label = get_node_or_null("FreqValueLabel") as Label
	if freq_lab != null:
		freq_lab.position = Vector2(0, 28)
		freq_lab.size = Vector2(360, 24)
	var lock_bar: ProgressBar = get_node_or_null("LockBar") as ProgressBar
	if lock_bar != null:
		lock_bar.position = Vector2(0, 56)
		lock_bar.size = Vector2(360, 24)
		lock_bar.max_value = LOCK_TIME
		lock_bar.show_percentage = false
	var fix_btn: Button = get_node_or_null("FixButton") as Button
	if fix_btn != null:
		fix_btn.position = Vector2(0, 88)
		fix_btn.size = Vector2(176, 36)
	var sell_btn: Button = get_node_or_null("SellButton") as Button
	if sell_btn != null:
		sell_btn.position = Vector2(184, 88)
		sell_btn.size = Vector2(176, 36)
	var st_lab: Label = get_node_or_null("StatusLabel") as Label
	if st_lab != null:
		st_lab.position = Vector2(0, 132)
		st_lab.size = Vector2(360, 120)
		st_lab.autowrap_mode = 2
	_set_status("Статус: выбери сигнал в списке радара слева")
func _process(delta: float) -> void:
	var sm: Node = get_node_or_null("/root/SignalManager")
	if sm == null:
		return
	var active: Dictionary = sm.get("active")
	if active.is_empty():
		lock_progress = 0.0
		_update_lock_bar()
		_set_status("Статус: нет сигналов")
		return
	_resolve_selection(active)
	if selected_id == "" or not active.has(selected_id):
		lock_progress = 0.0
		_update_lock_bar()
		_set_status("Статус: выберите сигнал в списке радара")
		return
	var s: Resource = active[selected_id]
	if int(s.get("state")) == 1:
		lock_progress = LOCK_TIME
		_update_lock_bar()
		_set_status("Статус: расшифрован — можно продать")
		_update_freq_label(float(s.get("frequency_mhz")))
		return
	var bd: Node = get_node_or_null("/root/Breakdowns")
	if bd != null and not bool(bd.call("server_can_process")):
		lock_progress = 0.0
		_update_lock_bar()
		_set_status("Статус: сервер сломан — обработка запрещена, нужен ремонт")
		return
	var tuned: float = _tuned_freq()
	var freq: float = float(s.get("frequency_mhz"))
	var bw: float = float(s.get("bandwidth_mhz"))
	_update_freq_label(tuned)
	if absf(freq - tuned) <= bw * 0.5:
		lock_progress += delta
		if lock_progress >= LOCK_TIME:
			lock_progress = LOCK_TIME
			var ok: bool = bool(sm.call("process_signal", selected_id, tuned))
			if ok:
				_set_status("Статус: расшифрован — можно продать")
			else:
				_set_status("Статус: ошибка фиксации")
	else:
		lock_progress = maxf(0.0, lock_progress - delta * 2.0)
		_set_status("Статус: настройтесь на %.1f МГц" % freq)
	_update_lock_bar()
func _resolve_selection(active: Dictionary) -> void:
	var list: ItemList = get_node_or_null("/root/Main/HUD/RadarTab/SignalList") as ItemList
	if list == null:
		var hud_list: Node = get_node_or_null("../RadarTab/SignalList")
		list = hud_list as ItemList
	if list != null and not list.get_selected_items().is_empty():
		var idx: int = list.get_selected_items()[0]
		var keys: Array = active.keys()
		if idx >= 0 and idx < keys.size():
			selected_id = str(keys[idx])
			return
	if selected_id == "" or not active.has(selected_id):
		var keys: Array = active.keys()
		if not keys.is_empty():
			selected_id = str(keys[0])
func _tuned_freq() -> float:
	var sl: HSlider = get_node_or_null("/root/Main/HUD/RadarTab/TuneSlider") as HSlider
	if sl == null:
		var hud_sl: Node = get_node_or_null("../RadarTab/TuneSlider")
		sl = hud_sl as HSlider
	if sl != null:
		return float(sl.value)
	return 87.5
func _update_lock_bar() -> void:
	var bar: ProgressBar = get_node_or_null("LockBar") as ProgressBar
	if bar != null:
		bar.max_value = LOCK_TIME
		bar.value = lock_progress
func _update_freq_label(tuned: float) -> void:
	var lab: Label = get_node_or_null("FreqValueLabel") as Label
	if lab != null:
		lab.text = "Частота: %.1f МГц" % tuned
func _set_status(t: String) -> void:
	var lab: Label = get_node_or_null("StatusLabel") as Label
	if lab != null:
		lab.text = t
func _on_fix() -> void:
	var bd: Node = get_node_or_null("/root/Breakdowns")
	if bd != null and not bool(bd.call("server_can_process")):
		_set_status("Статус: сервер сломан — обработка запрещена, нужен ремонт")
		return
	var sm: Node = get_node_or_null("/root/SignalManager")
	if sm == null or selected_id == "":
		return
	var ok: bool = bool(sm.call("process_signal", selected_id, _tuned_freq()))
	_set_status("Статус: расшифрован — можно продать" if ok else "Статус: вне допуска, подстройте частоту")
	if ok:
		lock_progress = LOCK_TIME
		_update_lock_bar()
func _on_sell() -> void:
	var eco: Node = get_node_or_null("/root/Economy")
	if eco == null or selected_id == "":
		return
	var price: int = int(eco.call("sell", selected_id))
	if price > 0:
		_set_status("Статус: продано за %d cr" % price)
		lock_progress = 0.0
		_update_lock_bar()
		selected_id = ""
	else:
		_set_status("Статус: продажа недоступна (нужен расшифрованный сигнал)")
