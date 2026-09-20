extends Control
# Терминал 2 — настройка захваченного сигнала.
# Слева полярность (градусы 0-360 + знак), справа частота (1-100 МГц).
# Обе шкалы >= 40% → прогресс растёт, 100% → кнопка отправки на Терминал 3.
var work_id := ""
var progress := 0.0
var sign_sel := 1
var pol_meter := 0.0
var frq_meter := 0.0

var sig_lab: Label
var pol_slider: HSlider
var frq_slider: HSlider
var pol_bar: ProgressBar
var frq_bar: ProgressBar
var prog_bar: ProgressBar
var send_btn: Button
var status_lab: Label
var plus_btn: Button
var minus_btn: Button
var sfx: AudioStreamPlayer

func _ready() -> void:
	position = Vector2(520, 60)
	size = Vector2(600, 460)
	_add_label("TitleLab", "НАСТРОЙКА СИГНАЛА", Rect2(0, 0, 600, 28))
	sig_lab = _add_label("SigLab", "Нет сигнала", Rect2(0, 32, 600, 24))
	_add_label("PolHead", "Полярность, градусы", Rect2(0, 60, 280, 24))
	pol_slider = _add_slider("PolSlider", Rect2(0, 88, 280, 24), 0.0, 360.0, 1.0, 0.0)
	plus_btn = _add_button("PlusBtn", "+", Rect2(0, 118, 134, 32))
	minus_btn = _add_button("MinusBtn", "-", Rect2(146, 118, 134, 32))
	plus_btn.pressed.connect(_on_sign.bind(1))
	minus_btn.pressed.connect(_on_sign.bind(-1))
	pol_bar = _add_bar("PolBar", Rect2(0, 156, 280, 24))
	_add_label("FrqHead", "Частота, МГц", Rect2(300, 60, 280, 24))
	frq_slider = _add_slider("FrqSlider", Rect2(300, 88, 280, 24), 1.0, 100.0, 0.1, 50.0)
	frq_bar = _add_bar("FrqBar", Rect2(300, 156, 280, 24))
	_add_label("ProgHead", "Прогресс", Rect2(0, 196, 580, 24))
	prog_bar = _add_bar("ProgBar", Rect2(0, 224, 580, 28))
	send_btn = _add_button("SendBtn", "Отправить на Терминал 3", Rect2(0, 260, 580, 40))
	send_btn.pressed.connect(_on_send)
	send_btn.disabled = true
	status_lab = _add_label("StatusLab", "", Rect2(0, 308, 580, 120))
	status_lab.autowrap_mode = 2
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	_mark_sign()
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	var sig: Resource = SignalManager.first_untuned()
	if sig == null:
		work_id = ""
		progress = 0.0
		prog_bar.value = 0.0
		send_btn.disabled = true
		sig_lab.text = "Нет сигнала — захвати на Терминале 1 (ЗАХВАТ)"
		status_lab.text = ""
		return
	work_id = str(sig.get("id"))
	sig_lab.text = "%s: полярность %s%.0f°, частота %.1f МГц" % [
		str(sig.get("name_ru")),
		"+" if int(sig.get("polarity_sign")) >= 0 else "-",
		float(sig.get("polarity_deg")), float(sig.get("freq_mhz"))]
	var deg := float(pol_slider.value)
	var fr := float(frq_slider.value)
	pol_meter = _pol_scale(float(sig.get("polarity_deg")), int(sig.get("polarity_sign")), deg, sign_sel)
	frq_meter = _frq_scale(float(sig.get("freq_mhz")), fr)
	pol_bar.value = pol_meter
	frq_bar.value = frq_meter
	if pol_meter >= 40.0 and frq_meter >= 40.0:
		progress = minf(100.0, progress + (pol_meter + frq_meter) / 200.0 * 30.0 * delta)
		if progress >= 100.0:
			status_lab.text = "Готов! Жми «Отправить на Терминал 3»."
			send_btn.disabled = false
		else:
			status_lab.text = "Настройка идёт... %.0f%%" % progress
			send_btn.disabled = true
	else:
		var low := []
		if pol_meter < 40.0:
			low.append("полярность %.0f%%" % pol_meter)
		if frq_meter < 40.0:
			low.append("частота %.0f%%" % frq_meter)
		status_lab.text = "Дотяни до 40%%: %s." % ", ".join(low)
		send_btn.disabled = true
	prog_bar.value = progress

func _on_sign(s: int) -> void:
	sign_sel = s
	_mark_sign()

func _mark_sign() -> void:
	if plus_btn != null:
		plus_btn.modulate = Color(0.5, 1.0, 0.5) if sign_sel >= 0 else Color(1, 1, 1)
	if minus_btn != null:
		minus_btn.modulate = Color(0.5, 1.0, 0.5) if sign_sel < 0 else Color(1, 1, 1)

func _on_send() -> void:
	if work_id == "" or progress < 100.0:
		return
	if SignalManager.mark_tuned(work_id):
		sfx.stream = _make_tone(660.0, 0.2)
		sfx.play()
		status_lab.text = "Отправлено! Сигнал ждёт на Терминале 3 (КОМПЬЮТЕР)."
		progress = 0.0
		work_id = ""
		send_btn.disabled = true

func _pol_scale(pol_deg: float, s: int, deg: float, sp: int) -> float:
	if s != sp:
		return 0.0
	var d := absf(wrapf(pol_deg - deg, -180.0, 180.0))
	return clampf(100.0 * (1.0 - d / 180.0), 0.0, 100.0)

func _frq_scale(f0: float, f: float) -> float:
	var e := absf(f - f0)
	return clampf(100.0 * (1.0 - sqrt(e / 99.0)), 0.0, 100.0)

func _make_tone(freq: float, dur: float, rate: int = 22050) -> AudioStreamWAV:
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		data[i] = int(clampf(128.0 + 127.0 * sin(TAU * freq * float(i) / float(rate)), 0.0, 255.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _add_label(n: String, t: String, r: Rect2) -> Label:
	var lab := Label.new()
	lab.name = n
	lab.text = t
	lab.position = r.position
	lab.size = r.size
	add_child(lab)
	return lab

func _add_slider(n: String, r: Rect2, mn: float, mx: float, st: float, v: float) -> HSlider:
	var sl := HSlider.new()
	sl.name = n
	sl.position = r.position
	sl.size = r.size
	sl.min_value = mn
	sl.max_value = mx
	sl.step = st
	sl.value = v
	add_child(sl)
	return sl

func _add_bar(n: String, r: Rect2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = n
	bar.position = r.position
	bar.size = r.size
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = true
	add_child(bar)
	return bar

func _add_button(n: String, t: String, r: Rect2) -> Button:
	var btn := Button.new()
	btn.name = n
	btn.text = t
	btn.position = r.position
	btn.size = r.size
	add_child(btn)
	return btn
