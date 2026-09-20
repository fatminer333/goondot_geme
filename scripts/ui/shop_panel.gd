extends Control
# ShopPanel Task 4: каталог + кнопка Купить + доставка-заглушка 30с. Тексты на русском.
var selected_id: String = "mre"
var delivery_left: float = 0.0
const NAMES_RU: Dictionary = {
	"snack": "Перекус — 15 кр.",
	"mre": "Паёк MRE — 30 кр.",
	"coffee": "Кофе — 10 кр.",
	"filter": "Фильтр — 40 кр.",
	"battery": "Батарея — 20 кр.",
	"repair": "Ремкомплект — 50 кр.",
}
func _ready() -> void:
	position = Vector2(800, 60)
	size = Vector2(340, 340)
	var title: Label = get_node_or_null("ShopStatusLabel") as Label
	if title != null:
		title.position = Vector2(0, 0)
		title.size = Vector2(340, 24)
	var list: ItemList = get_node_or_null("ShopList") as ItemList
	if list != null:
		list.position = Vector2(0, 28)
		list.size = Vector2(340, 200)
		list.item_selected.connect(_on_item_selected)
	var buy: Button = get_node_or_null("BuyButton") as Button
	if buy != null:
		buy.position = Vector2(0, 232)
		buy.size = Vector2(340, 32)
		buy.pressed.connect(_on_buy)
	var dl: Label = get_node_or_null("DeliveryLabel") as Label
	if dl != null:
		dl.position = Vector2(0, 268)
		dl.size = Vector2(340, 24)
	RefreshList()
func _process(delta: float) -> void:
	if delivery_left > 0.0:
		delivery_left = maxf(0.0, delivery_left - delta)
		_set_delivery("Доставка: %dс" % int(ceilf(delivery_left)))
		if delivery_left <= 0.0:
			_set_delivery("Доставка прибыла")
func RefreshList() -> void:
	var list: ItemList = get_node_or_null("ShopList") as ItemList
	if list == null:
		return
	list.clear()
	var shop: Node = get_node_or_null("/root/Shop")
	if shop == null:
		return
	var catalog: Dictionary = shop.get("catalog")
	for id in catalog.keys():
		list.add_item(str(NAMES_RU.get(str(id), str(id))))
func _catalog_keys() -> Array:
	var shop: Node = get_node_or_null("/root/Shop")
	if shop == null:
		return []
	return (shop.get("catalog") as Dictionary).keys()
func _on_item_selected(idx: int) -> void:
	var keys: Array = _catalog_keys()
	if idx >= 0 and idx < keys.size():
		selected_id = str(keys[idx])
func _on_buy() -> void:
	var shop: Node = get_node_or_null("/root/Shop")
	if shop == null:
		return
	var keys: Array = _catalog_keys()
	var list: ItemList = get_node_or_null("ShopList") as ItemList
	if list != null and not list.get_selected_items().is_empty():
		var idx: int = list.get_selected_items()[0]
		if idx >= 0 and idx < keys.size():
			selected_id = str(keys[idx])
	var ok: bool = bool(shop.call("buy", selected_id))
	if ok:
		delivery_left = 30.0
		_set_status("Куплено: %s" % str(NAMES_RU.get(selected_id, selected_id)))
		_set_delivery("Доставка: 30с")
	else:
		_set_status("Недостаточно денег!")
func _set_status(t: String) -> void:
	var lab: Label = get_node_or_null("ShopStatusLabel") as Label
	if lab != null:
		lab.text = t
func _set_delivery(t: String) -> void:
	var lab: Label = get_node_or_null("DeliveryLabel") as Label
	if lab != null:
		lab.text = t
