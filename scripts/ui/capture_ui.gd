extends Control
# Терминал 1 — карта захвата сигнала.
# WASD двигает активный квадрат, R переключает квадрат, SHIFT показывает
# 5 точек на 10с (4 красные + 1 коричневая), ENTER фиксирует треугольник.
const MAP_POS := Vector2(20, 60)
const MAP_SIZE := Vector2(480, 360)
const SQ := 14.0
const SPEED := 220.0
const DOTS_TIME := 10.0
const COOLDOWN := 5.0
const SQ_COLORS := [Color(1.0, 0.25, 0.2), Color(0.25, 1.0, 0.4), Color(0.3, 0.5, 1.0)]

var squares := [Vector2(120, 120), Vector2(360, 120), Vector2(240, 280)]
var active := 0
var dot_pos: Array = []
var dot_brown := -1
var dots_left := 0.0
var cooldown_left := 0.0
var stars: Array = []
var status_lab: Label
var sfx: AudioStreamPlayer
var sfx_ok: AudioStreamWAV
var sfx_fail: AudioStreamWAV
var _prev_r := false
var _prev_shift := false
var _prev_enter := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 90:
		stars.append(Vector2(rng.randf() * MAP_SIZE.x, rng.randf() * MAP_SIZE.y))
	var title := Label.new()
	title.text = "ЗАХВАТ: WASD — квадрат, R — смена, SHIFT — точки, ENTER — фиксация"
	title.position = Vector2(20, 32)
	title.size = Vector2(700, 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	status_lab = Label.new()
	status_lab.position = Vector2(20, 428)
	status_lab.size = Vector2(480, 80)
	status_lab.autowrap_mode = 2
	status_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_lab.text = "Нажми SHIFT — появятся 5 точек на 10 секунд."
	add_child(status_lab)
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	sfx_ok = _make_tone(880.0, 0.25)
	sfx_fail = _make_tone(160.0, 0.4)
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	var r_now := Input.is_key_pressed(KEY_R)
	if r_now and not _prev_r:
		active = (active + 1) % 3
		queue_redraw()
	_prev_r = r_now
	var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if mv.length() > 0.01:
		var lo := Vector2(SQ * 0.5 + 2.0, SQ * 0.5 + 2.0)
		var hi := MAP_SIZE - Vector2(SQ * 0.5 + 2.0, SQ * 0.5 + 2.0)
		squares[active] = (squares[active] + mv.normalized() * SPEED * delta).clamp(lo, hi)
		queue_redraw()
	var sh := Input.is_key_pressed(KEY_SHIFT)
	if sh and not _prev_shift:
		_try_reveal()
	_prev_shift = sh
	var en := Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	if en and not _prev_enter:
		_try_capture()
	_prev_enter = en
	if dots_left > 0.0:
		dots_left -= delta
		if dots_left <= 0.0:
			dot_pos.clear()
			dot_brown = -1
			_status("Точки погасли. Нажми SHIFT.")
			queue_redraw()
	if cooldown_left > 0.0:
		cooldown_left -= delta

func _try_reveal() -> void:
	if cooldown_left > 0.0:
		_status("Жди %dс..." % int(ceilf(cooldown_left)))
		return
	if not dot_pos.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 5:
		dot_pos.append(Vector2(rng.randf_range(24.0, MAP_SIZE.x - 24.0), rng.randf_range(24.0, MAP_SIZE.y - 24.0)))
	dot_brown = rng.randi_range(0, 4)
	dots_left = DOTS_TIME
	_status("Точки на 10с! Обведи КОРИЧНЕВУЮ треугольником и жми ENTER.")
	queue_redraw()

func _try_capture() -> void:
	if dot_pos.is_empty():
		_status("Сначала нажми SHIFT.")
		return
	var a: Vector2 = squares[0]
	var b: Vector2 = squares[1]
	var c: Vector2 = squares[2]
	var brown_pos: Vector2 = dot_pos[dot_brown]
	if _inside(a, b, c, brown_pos):
		var freq := randf_range(1.0, 100.0)
		var pol := randf_range(0.0, 360.0)
		var sgn := 1 if randf() < 0.5 else -1
		var s: Resource = SignalManager.capture_new(freq, pol, sgn)
		_play(sfx_ok)
		_status("Захвачено: %s! Частота %.1f МГц. Неси на Терминал 2." % [str(s.get("name_ru")), freq])
		_clear_dots()
		return
	for i in dot_pos.size():
		if i == dot_brown:
			continue
		if _inside(a, b, c, dot_pos[i]):
			_play(sfx_fail)
			_status("Красная точка! Сброс. Повтор через 5с.")
			_clear_dots()
			cooldown_left = COOLDOWN
			return
	_clear_dots()
	cooldown_left = COOLDOWN
	_status("Пусто! Повтор через 5с.")

func _clear_dots() -> void:
	dot_pos.clear()
	dot_brown = -1
	dots_left = 0.0
	queue_redraw()

func _status(t: String) -> void:
	if status_lab != null:
		status_lab.text = t

func _play(stream: AudioStreamWAV) -> void:
	if sfx != null:
		sfx.stream = stream
		sfx.play()

func _cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

func _inside(a: Vector2, b: Vector2, c: Vector2, p: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d02 := v0.dot(v2)
	var d11 := v1.dot(v1)
	var d12 := v1.dot(v2)
	var den := d00 * d11 - d01 * d01
	if absf(den) < 0.0001:
		return false
	var inv := 1.0 / den
	var u := (d11 * d02 - d01 * d12) * inv
	var v := (d00 * d12 - d01 * d02) * inv
	return u >= 0.0 and v >= 0.0 and (u + v) <= 1.0

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

func _draw() -> void:
	var o := MAP_POS
	draw_rect(Rect2(o, MAP_SIZE), Color(0.02, 0.03, 0.08))
	for st in stars:
		draw_circle(o + st, 1.0, Color(0.7, 0.8, 1.0, 0.7))
	for i in dot_pos.size():
		var col := Color(1.0, 0.2, 0.15) if i != dot_brown else Color(0.65, 0.4, 0.15)
		draw_circle(o + dot_pos[i], 5.0, col)
	var pts := PackedVector2Array([o + squares[0], o + squares[1], o + squares[2], o + squares[0]])
	draw_polyline(pts, Color(0.4, 1.0, 0.6, 0.8), 2.0)
	for i in 3:
		var r := Rect2(o + squares[i] - Vector2(SQ * 0.5, SQ * 0.5), Vector2(SQ, SQ))
		draw_rect(r, SQ_COLORS[i])
		if i == active:
			draw_rect(r, Color.WHITE, false, 2.0)
