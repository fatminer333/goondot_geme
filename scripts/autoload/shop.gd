extends Node
var catalog: Dictionary = {"snack": {"price": 15, "hunger": 20.0}, "mre": {"price": 30, "hunger": 45.0}, "coffee": {"price": 10, "fatigue": 25.0}, "filter": {"price": 40}, "battery": {"price": 20}, "repair": {"price": 50}}
func buy(id: String) -> bool:
	# Покупка кладёт предмет в сумку (применение — через инвентарь).
	if not catalog.has(id):
		return false
	var price: int = catalog[id].price
	if GameState.money < price:
		return false
	if Inventory.add_item(id, 1) > 0:
		return false
	GameState.money -= price
	return true
