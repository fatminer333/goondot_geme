extends Control
var tuned_freq: float = 87.5
func _ready() -> void:
	# Layout кодом (позиции заданы здесь, т.к. размер/позиция — 360x360 радар + панель).
	position = Vector2(20, 60)
	size = Vector2(380, 560)
	custom_minimum_size = Vector2(360, 360)
	var lab0: Label = get_node_or_null("FreqLabel") as Label
	if lab0 != null:
		lab0.position = Vector2(0, 368)
		lab0.size = Vector2(360, 24)
	var sl: HSlider = get_node_or_null("TuneSlider") as HSlider
	if sl != null:
		sl.position = Vector2(0, 396)
		sl.size = Vector2(360, 24)
	var li: ItemList = get_node_or_null("SignalList") as ItemList
	if li != null:
		li.position = Vector2(0, 428)
		li.size = Vector2(360, 88)
	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "Кликни сигнал → крути частоту → «Зафиксировать» справа"
	hint.position = Vector2(0, 520)
	hint.size = Vector2(360, 40)
	hint.autowrap_mode = 2
	add_child(hint)
	var rs: Node = get_node_or_null("/root/RadarService")
	if rs != null and rs.has_signal("blips_updated"):
		rs.blips_updated.connect(_on_blips_updated)
	var slider: HSlider = get_node_or_null("TuneSlider") as HSlider
	if slider != null:
		slider.value_changed.connect(_on_tune_changed)
	RefreshList()
func _on_blips_updated(_blips: Dictionary) -> void:
	RefreshList()
	queue_redraw()
func _on_tune_changed(v: float) -> void:
	tuned_freq = v
	var lab: Label = get_node_or_null("FreqLabel") as Label
	if lab != null:
		lab.text = "Частота: %.1f МГц" % tuned_freq
func RefreshList() -> void:
	var list: ItemList = get_node_or_null("SignalList") as ItemList
	if list == null:
		return
	list.clear()
	var sm: Node = get_node_or_null("/root/SignalManager")
	if sm == null:
		return
	var active: Dictionary = sm.get("active")
	for id in active.keys():
		var s: Resource = active[id]
		var nm: String = str(s.get("name_ru"))
		var f: float = float(s.get("frequency_mhz"))
		var st: int = int(s.get("state"))
		var txt: String = "%s — %.1f МГц%s" % [nm, f, " [расшифрован]" if st == 1 else ""]
		list.add_item(txt)
func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 8.0
	if r <= 0.0:
		return
	draw_circle(c, r, Color(0.02, 0.05, 0.03))
	for k in 3:
		draw_arc(c, r * (float(k + 1) / 3.0), 0.0, TAU, 48, Color(0.2, 0.9, 0.4, 0.6), 1.5)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0.2, 0.9, 0.4, 0.3), 1.0)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0.2, 0.9, 0.4, 0.3), 1.0)
	var rs: Node = get_node_or_null("/root/RadarService")
	var ang: float = 0.0
	var rng: float = 80.0
	if rs != null:
		ang = float(rs.get("sweep_angle"))
		rng = float(rs.get("range_m"))
	var rad: float = deg_to_rad(ang - 90.0)
	draw_line(c, c + Vector2(cos(rad), sin(rad)) * r, Color(0.4, 1.0, 0.5, 0.9), 2.0)
	if rs == null:
		return
	var blips: Dictionary = rs.get("blips")
	for id in blips.keys():
		var b: Dictionary = blips[id]
		var ba: float = deg_to_rad(float(b.get("angle_deg", 0.0)) - 90.0)
		var d: float = clampf(float(b.get("dist_m", 0.0)) / maxf(rng, 1.0), 0.0, 1.0)
		var al: float = clampf(float(b.get("alpha", 0.0)), 0.0, 1.0)
		var pos: Vector2 = c + Vector2(cos(ba), sin(ba)) * (d * r)
		draw_circle(pos, 5.0, Color(1.0, 0.4, 0.3, 0.25 + 0.75 * al))
