extends Node3D
# Main: E на терминалах открывает их экраны (T1 захват, T2 настройка, T3 компьютер).
# Esc закрывает, симуляция продолжается. Кровать E → сон + итоги дня.

var _overlays: Array = []
var sold_today: int = 0

func _ready() -> void:
	var inv: Node = get_node_or_null("/root/Inventory")
	if inv != null and int(inv.call("count_total", "mre")) == 0:
		inv.call("add_item", "mre", 2)
		inv.call("add_item", "coffee", 1)
		inv.call("add_item", "jacket", 1)
	_overlays = [
		get_node_or_null("HUD/CaptureUI"),
		get_node_or_null("HUD/TuneUI"),
		get_node_or_null("HUD/ComputerUI"),
	]
	_hide_all_overlays()
	_lock_player(false)
	var eod: Control = get_node_or_null("HUD/EndOfDayPanel") as Control
	if eod != null:
		eod.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var eb: Node = get_node_or_null("/root/EventBus")
	if eb != null:
		if not eb.is_connected("signal_sold", _on_sold):
			eb.connect("signal_sold", _on_sold)
		if not eb.is_connected("day_ended", _on_day_ended):
			eb.connect("day_ended", _on_day_ended)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_ui"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		close_ui()

func _process(_delta: float) -> void:
	_apply_night_calibration()

func _try_interact() -> void:
	var ray: RayCast3D = get_node_or_null("Player/Head/Camera3D/InteractionRay") as RayCast3D
	if ray == null:
		return
	ray.force_raycast_update()
	if not ray.is_colliding():
		return
	var col: Object = ray.get_collider()
	if col == null or not (col is Node):
		return
	var node: Node = col as Node
	if node.is_in_group("term1"):
		_open_ui(0)
	elif node.is_in_group("term2"):
		_open_ui(1)
	elif node.is_in_group("term3"):
		_open_ui(2)
	elif node.is_in_group("bed"):
		_do_sleep()

func _open_ui(idx: int) -> void:
	for i in _overlays.size():
		var c: Control = _overlays[i] as Control
		if c != null:
			c.visible = (i == idx)
	_lock_player(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_ui() -> void:
	_hide_all_overlays()
	_set_inventory_open(false)
	_lock_player(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_inventory() -> void:
	var inv_ui: Control = get_node_or_null("HUD/InventoryUI") as Control
	if inv_ui == null or not inv_ui.has_method("is_open"):
		return
	var open: bool = not bool(inv_ui.call("is_open"))
	_set_inventory_open(open)
	if open:
		_hide_all_overlays()
		_lock_player(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		_lock_player(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_inventory_open(b: bool) -> void:
	var inv_ui: Control = get_node_or_null("HUD/InventoryUI") as Control
	if inv_ui != null and inv_ui.has_method("set_open"):
		inv_ui.call("set_open", b)

func _hide_all_overlays() -> void:
	for o in _overlays:
		var c: Control = o as Control
		if c != null:
			c.visible = false

func _lock_player(locked: bool) -> void:
	var p: Node = get_node_or_null("Player")
	if p != null and p.has_method("set_locked"):
		p.call("set_locked", locked)

func _on_sold(_id: String, price: int) -> void:
	sold_today += price

func _on_day_ended(_day: int) -> void:
	sold_today = 0
	close_ui()

func _do_sleep() -> void:
	# Кровать E: сон + показ итогов дня. Следующий день — кнопкой в EndOfDay.
	var sv: Node = get_node_or_null("/root/Survival")
	var dn: Node = get_node_or_null("/root/DayNight")
	if sv != null:
		sv.call("sleep", 110.0)
	if dn != null:
		# Сон проматывает ночь: ставим утро 07:00.
		dn.set("time_06_24", 7.0)
		dn.set("is_night", false)
	var eod: Control = get_node_or_null("HUD/EndOfDayPanel") as Control
	if eod != null and eod.has_method("show_result"):
		eod.call("show_result", sold_today)
		_lock_player(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Сон: итоги дня, продано на %d кр." % sold_today)

func _apply_night_calibration() -> void:
	# День: солнце 1.0, ambient 1.0. Ночь 00-06: солнце гаснет, ambient пол 0.35 (≥0.15).
	# Фонарь (SpotLight3D) не трогаем — работает всегда.
	var dn: Node = get_node_or_null("/root/DayNight")
	var sun: DirectionalLight3D = get_node_or_null("Sun") as DirectionalLight3D
	var we: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	var night: bool = false
	if dn != null:
		night = bool(dn.get("is_night"))
	if sun != null:
		sun.light_energy = 0.05 if night else 1.0
	if we != null and we.environment != null:
		we.environment.ambient_light_energy = 0.35 if night else 1.0
		if we.environment.sky != null:
			var sky_mat: Material = we.environment.sky.sky_material
			if sky_mat != null:
				if night:
					sky_mat.set("sky_top_color", Color(0.015, 0.02, 0.06))
					sky_mat.set("sky_horizon_color", Color(0.06, 0.08, 0.16))
					sky_mat.set("ground_bottom_color", Color(0.01, 0.01, 0.02))
					sky_mat.set("ground_horizon_color", Color(0.05, 0.06, 0.12))
				else:
					sky_mat.set("sky_top_color", Color(0.38, 0.45, 0.55))
					sky_mat.set("sky_horizon_color", Color(0.65, 0.67, 0.7))
					sky_mat.set("ground_bottom_color", Color(0.2, 0.17, 0.13))
					sky_mat.set("ground_horizon_color", Color(0.65, 0.67, 0.7))
