extends Control
# Инвентарь (TAB): силуэт + здоровье, одежда/аксессуары, сумка 20, хотбар 9.
# ЛКМ — инфо, SHIFT+ЛКМ — всё в хотбар/сумку, SHIFT+ПКМ — 1 шт., ПКМ — меню, drag&drop.
const PANEL_POS := Vector2(196, 70)
const PANEL_SIZE := Vector2(760, 500)
const WEAR_HINT := ["Гол", "Тел", "Ног"]
const ACC_HINT := ["А1", "А2"]

var bag: Panel
var info_lab: Label
var health_lab: Label
var menu: PopupMenu
var _menu_area := ""
var _menu_idx := -1
var slot_btns := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hotbar()
	_build_bag()
	menu = PopupMenu.new()
	menu.id_pressed.connect(_on_menu)
	add_child(menu)
	Inventory.changed.connect(refresh)
	bag.visible = false

func is_open() -> bool:
	return bag.visible

func set_open(b: bool) -> void:
	bag.visible = b
	if b:
		refresh()
	queue_redraw()

func _build_hotbar() -> void:
	for i in 9:
		var b := SlotButton.new()
		b.area = "hot"
		b.idx = i
		b.ui = self
		b.position = Vector2(306 + i * 60, 584)
		b.size = Vector2(56, 56)
		b.gui_input.connect(_on_slot_input.bind("hot", i))
		add_child(b)
		slot_btns["hot:%d" % i] = b

func _build_bag() -> void:
	bag = Panel.new()
	bag.position = PANEL_POS
	bag.size = PANEL_SIZE
	add_child(bag)
	_bag_label("ИНВЕНТАРЬ — TAB закрыть", Rect2(10, 8, 740, 24))
	_bag_label("Одежда:", Rect2(190, 40, 120, 20))
	for i in 3:
		_mk_slot("wear", i, Vector2(190, 64 + i * 68), Vector2(56, 56))
	_bag_label("Аксессуары:", Rect2(190, 272, 120, 20))
	for i in 2:
		_mk_slot("acc", i, Vector2(190 + i * 64, 296), Vector2(56, 56))
	_bag_label("Рука:", Rect2(190, 364, 120, 20))
	_mk_slot("hand", 0, Vector2(190, 388), Vector2(56, 56))
	_bag_label("Сумка (20):", Rect2(330, 40, 200, 20))
	for r in 4:
		for c in 5:
			_mk_slot("bag", r * 5 + c, Vector2(330 + c * 64, 64 + r * 64), Vector2(60, 60))
	info_lab = _bag_label("", Rect2(560, 64, 190, 220))
	info_lab.autowrap_mode = 2
	health_lab = _bag_label("", Rect2(10, 380, 170, 100))
	health_lab.autowrap_mode = 2
	_bag_label("ЛКМ — инфо. SHIFT+ЛКМ — всё. SHIFT+ПКМ — 1 шт. ПКМ — меню. Вещи тянутся мышью.", Rect2(10, 452, 740, 40)).autowrap_mode = 2

func _bag_label(t: String, r: Rect2) -> Label:
	var lab := Label.new()
	lab.text = t
	lab.position = r.position
	lab.size = r.size
	bag.add_child(lab)
	return lab

func _mk_slot(area: String, i: int, pos: Vector2, sz: Vector2) -> void:
	var b := SlotButton.new()
	b.area = area
	b.idx = i
	b.ui = self
	b.position = pos
	b.size = sz
	b.gui_input.connect(_on_slot_input.bind(area, i))
	bag.add_child(b)
	slot_btns["%s:%d" % [area, i]] = b

func _on_slot_input(event: InputEvent, area: String, idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.shift_pressed:
			_quick_move(area, idx, false)
		else:
			_show_info(area, idx)
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.shift_pressed:
			_quick_move(area, idx, true)
		else:
			_open_menu(area, idx)

func _show_info(area: String, idx: int) -> void:
	var st := Inventory.get_slot(area, idx)
	if st.is_empty():
		info_lab.text = "Пустой слот."
		return
	var d := Inventory.def(str(st["id"]))
	info_lab.text = "%s ×%d\n%s" % [str(d["name"]), int(st["n"]), str(d["desc"])]

func _quick_move(area: String, idx: int, one: bool) -> void:
	var src := Inventory.get_slot(area, idx)
	if src.is_empty():
		return
	var dest := "hot" if area == "bag" else "bag"
	var id := str(src["id"])
	if one:
		var ti := _find_target(id, dest)
		if ti < 0:
			info_lab.text = "Нет места."
			return
		Inventory.move(area, idx, dest, ti, 1)
		return
	var guard := 0
	while not Inventory.get_slot(area, idx).is_empty() and guard < 12:
		guard += 1
		var ti := _find_target(id, dest)
		if ti < 0:
			info_lab.text = "Нет места."
			break
		if not Inventory.move(area, idx, dest, ti):
			break

func _find_target(id: String, dest: String) -> int:
	var n := int(Inventory.SIZES[dest])
	for i in n:
		var st := Inventory.get_slot(dest, i)
		if not st.is_empty() and str(st["id"]) == id and int(st["n"]) < Inventory.MAX_STACK:
			return i
	for i in n:
		if Inventory.get_slot(dest, i).is_empty():
			return i
	return -1

func can_accept(data: Dictionary, area: String, idx: int) -> bool:
	var src := Inventory.get_slot(str(data.get("farea", "")), int(data.get("fi", -1)))
	if src.is_empty():
		return false
	if str(data.get("farea")) == area and int(data.get("fi")) == idx:
		return false
	var id := str(src["id"])
	var dst := Inventory.get_slot(area, idx)
	if dst.is_empty():
		return Inventory.can_place(area, idx, id)
	if str(dst["id"]) == id:
		return true
	return Inventory.can_place(area, idx, id) and Inventory.can_place(str(data.get("farea")), int(data.get("fi")), str(dst["id"]))

func accept_drop(data: Dictionary, area: String, idx: int) -> void:
	Inventory.move(str(data.get("farea", "")), int(data.get("fi", -1)), area, idx)

func _open_menu(area: String, idx: int) -> void:
	var st := Inventory.get_slot(area, idx)
	if st.is_empty():
		return
	_menu_area = area
	_menu_idx = idx
	menu.clear()
	var d := Inventory.def(str(st["id"]))
	var t := str(d.get("type", "misc"))
	menu.add_item("Инфо", 0)
	if Inventory.can_place("hand", 0, str(st["id"])):
		menu.add_item("Взять в руку", 1)
	if t == "food" or str(st["id"]) == "repair" or t == "clothes" or t == "acc":
		menu.add_item("Применить", 2)
	menu.add_item("Выбросить", 3)
	menu.popup(Rect2i(Vector2i(get_global_mouse_position()), Vector2i.ZERO))

func _on_menu(id: int) -> void:
	match id:
		0:
			_show_info(_menu_area, _menu_idx)
		1:
			info_lab.text = Inventory.to_hand(_menu_area, _menu_idx)
		2:
			info_lab.text = Inventory.apply(_menu_area, _menu_idx)
		3:
			if Inventory.drop(_menu_area, _menu_idx):
				info_lab.text = "Выброшено."

func refresh() -> void:
	for key in slot_btns.keys():
		var parts := str(key).split(":")
		var area := parts[0]
		var i := int(parts[1])
		var b: SlotButton = slot_btns[key]
		var st := Inventory.get_slot(area, i)
		if st.is_empty():
			b.clear_item(_empty_hint(area, i))
		else:
			b.set_item(str(st["id"]), int(st["n"]))
	health_lab.text = "Здоровье: %s\nСытость %d%%\nБодрость %d%%" % [_health_word(), int(float(Survival.get("hunger"))), int(float(Survival.get("fatigue")))]
	queue_redraw()

func _empty_hint(area: String, i: int) -> String:
	if area == "wear" and i < WEAR_HINT.size():
		return WEAR_HINT[i]
	if area == "acc" and i < ACC_HINT.size():
		return ACC_HINT[i]
	if area == "hand":
		return "Рука"
	return ""

func _health_word() -> String:
	var h := float(Survival.get("hunger"))
	var f := float(Survival.get("fatigue"))
	if h < 15.0 or f < 15.0:
		return "Критическое!"
	if h < 30.0 or f < 30.0:
		return "Плохое"
	if h < 60.0 or f < 60.0:
		return "Среднее"
	return "Хорошее"

func _health_color() -> Color:
	var w := _health_word()
	if w == "Критическое!":
		return Color(1.0, 0.25, 0.2)
	if w == "Плохое":
		return Color(1.0, 0.7, 0.2)
	if w == "Среднее":
		return Color(1.0, 1.0, 0.4)
	return Color(0.4, 1.0, 0.5)
