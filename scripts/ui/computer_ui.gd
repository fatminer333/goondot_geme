extends Control
# Терминал 3 — компьютер: продажа настроенных сигналов, магазин, состояние базы, камеры.

var sale_page: Control
var shop_page: Control
var base_page: Control
var cam_page: Control
var sale_list: ItemList
var sale_quota_lab: Label
var sale_status_lab: Label
var sale_ids: Array = []
var shop_list: ItemList
var shop_status_lab: Label
var shop_ids: Array = []
var base_lab: Label

func _ready() -> void:
	position = Vector2(140, 60)
	size = Vector2(870, 540)
	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.position = Vector2(0, 0)
	top.size = Vector2(870, 40)
	add_child(top)
	var names: Array = ["Продажа", "Магазин", "База", "Камеры"]
	for i in names.size():
		var b := Button.new()
		b.name = "Tab%d" % i
		b.text = str(names[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_show_page.bind(i))
		top.add_child(b)
	var content := Control.new()
	content.name = "Content"
	content.position = Vector2(0, 48)
	content.size = Vector2(870, 492)
	add_child(content)
	sale_page = _make_page(content, "SalePage")
	shop_page = _make_page(content, "ShopPage")
	base_page = _make_page(content, "BasePage")
	cam_page = _make_page(content, "CamPage")
	_build_sale()
	_build_shop()
	_build_base()
	_build_cam()
	_show_page(0)
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	if base_page != null and base_page.visible and base_lab != null:
		base_lab.text = _base_text()

func _make_page(parent: Control, pname: String) -> Control:
	var p := Control.new()
	p.name = pname
	p.position = Vector2(0, 0)
	p.size = Vector2(870, 492)
	parent.add_child(p)
	return p

func _show_page(idx: int) -> void:
	var pages: Array = [sale_page, shop_page, base_page, cam_page]
	for i in pages.size():
		var p: Control = pages[i] as Control
		if p != null:
			p.visible = (i == idx)
	if idx == 0:
		refresh_sale()
	elif idx == 1:
		refresh_shop()
	elif idx == 2 and base_lab != null:
		base_lab.text = _base_text()

func _build_sale() -> void:
	sale_list = ItemList.new()
	sale_list.name = "SaleList"
	sale_list.position = Vector2(0, 0)
	sale_list.size = Vector2(870, 360)
	sale_page.add_child(sale_list)
	var sell_btn := Button.new()
	sell_btn.name = "SellBtn"
	sell_btn.text = "Продать"
	sell_btn.position = Vector2(0, 368)
	sell_btn.size = Vector2(870, 36)
	sell_btn.pressed.connect(_on_sell_pressed)
	sale_page.add_child(sell_btn)
	sale_quota_lab = Label.new()
	sale_quota_lab.name = "QuotaLab"
	sale_quota_lab.position = Vector2(0, 408)
	sale_quota_lab.size = Vector2(870, 24)
	sale_page.add_child(sale_quota_lab)
	sale_status_lab = Label.new()
	sale_status_lab.name = "SaleStatusLab"
	sale_status_lab.position = Vector2(0, 436)
	sale_status_lab.size = Vector2(870, 48)
	sale_status_lab.autowrap_mode = 2
	sale_page.add_child(sale_status_lab)
	refresh_sale()

func refresh_sale() -> int:
	sale_ids.clear()
	if sale_list == null:
		return 0
	sale_list.clear()
	var items: Array = SignalManager.tuned_for_sale()
	for s in items:
		var nm := str((s as Resource).get("name_ru"))
		var rw := int((s as Resource).get("reward"))
		sale_ids.append(str((s as Resource).get("id")))
		sale_list.add_item("%s — %d кр." % [nm, rw])
	if sale_quota_lab != null:
		var q := int(Economy.quota_for(int(GameState.day)))
		sale_quota_lab.text = "Квота дня %d: %d кр." % [int(GameState.day), q]
	return sale_ids.size()

func update_sale_list() -> int:
	return refresh_sale()

func _on_sell_pressed() -> void:
	if sale_list == null:
		return
	var sel := sale_list.get_selected_items()
	if sel.is_empty():
		if sale_status_lab != null:
			sale_status_lab.text = "Выбери сигнал для продажи."
		return
	var idx := int(sel[0])
	if idx < 0 or idx >= sale_ids.size():
		return
	var sid := str(sale_ids[idx])
	var price := int(Economy.sell(sid))
	if price > 0:
		if sale_status_lab != null:
			sale_status_lab.text = "Продано за %d кр." % price
	else:
		if sale_status_lab != null:
			sale_status_lab.text = "Не удалось продать."
	refresh_sale()

func _build_shop() -> void:
	shop_list = ItemList.new()
	shop_list.name = "ShopList"
	shop_list.position = Vector2(0, 0)
	shop_list.size = Vector2(870, 360)
	shop_page.add_child(shop_list)
	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = "Купить"
	buy_btn.position = Vector2(0, 368)
	buy_btn.size = Vector2(870, 36)
	buy_btn.pressed.connect(_on_buy_pressed)
	shop_page.add_child(buy_btn)
	shop_status_lab = Label.new()
	shop_status_lab.name = "ShopStatusLab"
	shop_status_lab.position = Vector2(0, 408)
	shop_status_lab.size = Vector2(870, 76)
	shop_status_lab.autowrap_mode = 2
	shop_page.add_child(shop_status_lab)
	refresh_shop()

func refresh_shop() -> int:
	shop_ids.clear()
	if shop_list == null:
		return 0
	shop_list.clear()
	var cat: Dictionary = Shop.catalog
	for key in cat.keys():
		var price := int((cat[key] as Dictionary).get("price", 0))
		shop_ids.append(str(key))
		shop_list.add_item("%s — %d кр." % [str(key), price])
	return shop_ids.size()

func _on_buy_pressed() -> void:
	if shop_list == null:
		return
	var sel := shop_list.get_selected_items()
	if sel.is_empty():
		if shop_status_lab != null:
			shop_status_lab.text = "Выбери товар для покупки."
		return
	var idx := int(sel[0])
	if idx < 0 or idx >= shop_ids.size():
		return
	var sid := str(shop_ids[idx])
	if bool(Shop.buy(sid)):
		if shop_status_lab != null:
			shop_status_lab.text = "Куплено: %s. Деньги: %d кр." % [sid, int(GameState.money)]
	else:
		if shop_status_lab != null:
			shop_status_lab.text = "Не удалось купить: %s." % sid

func _build_base() -> void:
	base_lab = Label.new()
	base_lab.name = "BaseLab"
	base_lab.position = Vector2(0, 0)
	base_lab.size = Vector2(870, 492)
	base_lab.autowrap_mode = 2
	base_page.add_child(base_lab)
	base_lab.text = _base_text()

func _base_text() -> String:
	var ant := float(Breakdowns.wear.get("antenna", 0.0))
	var gen := float(Breakdowns.wear.get("generator", 0.0))
	var srv := float(Breakdowns.wear.get("server", 0.0))
	var t := "База\n"
	t += "Износ антенна: %.0f%%\n" % ant
	t += "Износ генератор: %.0f%%\n" % gen
	t += "Износ сервер: %.0f%%\n" % srv
	t += "Голод: %.0f\n" % float(Survival.hunger)
	t += "Усталость: %.0f\n" % float(Survival.fatigue)
	t += "Деньги: %d кр.\n" % int(GameState.money)
	t += "День: %d" % int(GameState.day)
	return t

func refresh_base() -> void:
	if base_lab != null:
		base_lab.text = _base_text()

func _build_cam() -> void:
	var lab := Label.new()
	lab.name = "CamLab"
	lab.text = "Камеры будут добавлены позже"
	lab.position = Vector2(0, 0)
	lab.size = Vector2(870, 492)
	lab.autowrap_mode = 2
	cam_page.add_child(lab)
