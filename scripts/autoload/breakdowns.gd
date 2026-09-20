extends Node
var wear: Dictionary = {"antenna": 0.0, "generator": 0.0, "server": 0.0}
func _process(_delta: float) -> void:
	pass # +10/день начисляется в next_day
func add_daily_wear() -> void:
	for k in wear.keys():
		wear[k] = minf(100.0, float(wear[k]) + 10.0)
func repair(id: String) -> bool:
	if not wear.has(id):
		return false
	if float(wear[id]) <= 0.0:
		return false
	# Чинит за ремкомплект из сумки, а не за деньги.
	if not Inventory.remove_total("repair", 1):
		return false
	wear[id] = maxf(0.0, float(wear[id]) - 40.0)
	return true
func server_can_process() -> bool:
	return float(wear.get("server", 0.0)) < 100.0
