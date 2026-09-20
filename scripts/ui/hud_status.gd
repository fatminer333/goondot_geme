extends CanvasLayer
# HUD Task 4: деньги/день/время/голод/усталость/квота (+страх-заглушка до Task 5). Всё на русском.
func _ready() -> void:
	# Верхняя плашка через контейнер — лейблы не налезают на любом окне.
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 8
	bar.offset_right = -8
	bar.offset_top = 4
	bar.offset_bottom = 32
	bar.add_theme_constant_override("separation", 18)
	add_child(bar)
	move_child(bar, 0)
	for n in ["StatusLabel", "QuotaLabel", "HungerLabel", "FatigueLabel", "FearLabel"]:
		var lab: Label = get_node_or_null(n) as Label
		if lab != null:
			remove_child(lab)
			bar.add_child(lab)
	for n in ["QuotaLabel", "FearLabel"]:
		var hid: Label = bar.get_node_or_null(n) as Label
		if hid != null:
			hid.visible = false
func _process(_delta: float) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var dn: Node = get_node_or_null("/root/DayNight")
	var eco: Node = get_node_or_null("/root/Economy")
	var sv: Node = get_node_or_null("/root/Survival")
	var hd: Node = get_node_or_null("/root/HorrorDirector")
	if gs == null:
		return
	var day: int = int(gs.get("day"))
	var money: int = int(gs.get("money"))
	var tstr: String = "--:--"
	if dn != null:
		tstr = _fmt_time(float(dn.get("time_06_24")))
	var quota: int = 0
	if eco != null:
		quota = int(eco.call("quota_for", day))
	_set_text("StatusLabel", "Кредиты: %d кр." % money)
	_set_text("QuotaLabel", "Квота дня: %d кр." % quota)
	if sv != null:
		_set_text("HungerLabel", "Голод: %d%%" % int(float(sv.get("hunger"))))
		_set_text("FatigueLabel", "Усталость: %d%%" % int(float(sv.get("fatigue"))))
	if hd != null:
		_set_text("FearLabel", "Страх: %d%%" % int(float(hd.get("fear"))))
	else:
		_set_text("FearLabel", "Страх: --")
func _fmt_time(t: float) -> String:
	var h: int = int(t) % 24
	var m: int = int((t - floorf(t)) * 60.0)
	return "%02d:%02d" % [h, m]
func _set_text(n: String, t: String) -> void:
	# Лейблы живут в TopBar после _ready — ищем сначала там.
	var lab: Label = get_node_or_null("TopBar/" + n) as Label
	if lab == null:
		lab = get_node_or_null(n) as Label
	if lab != null:
		lab.text = t
