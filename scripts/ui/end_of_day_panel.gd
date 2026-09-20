extends Control
# Task 5: EndOfDayPanel — доход/квота/штраф/долг + кнопка «Следующий день».
# Кнопка: GameState.next_day + SignalManager.spawn_day + Breakdowns.add_daily_wear + HorrorDirector.refresh_budget.
var sold_today: int = 0

func _ready() -> void:
	# Центр экрана + раскладка: до этого панель 0x0 и дети в (0,0).
	position = Vector2(376, 200)
	size = Vector2(400, 240)
	_place_label("IncomeLabel", 0)
	_place_label("QuotaLabel", 32)
	_place_label("PenaltyLabel", 64)
	_place_label("DebtLabel", 96)
	var btn: Button = get_node_or_null("NextDayButton") as Button
	if btn != null:
		btn.position = Vector2(0, 140)
		btn.size = Vector2(400, 44)
	visible = false

func _place_label(n: String, y: float) -> void:
	var lab: Label = get_node_or_null(n) as Label
	if lab != null:
		lab.position = Vector2(0, y)
		lab.size = Vector2(400, 28)

func show_result(sold: int) -> void:
	sold_today = sold
	var gs: Node = get_node_or_null("/root/GameState")
	var eco: Node = get_node_or_null("/root/Economy")
	if gs == null or eco == null:
		return
	var day: int = int(gs.get("day"))
	var res: Dictionary = eco.call("apply_day_result", sold, day)
	_set_text("IncomeLabel", "Доход за день: %d кр." % int(res.get("sold", 0)))
	_set_text("QuotaLabel", "Квота дня: %d кр." % int(res.get("quota", 0)))
	_set_text("DebtLabel", "Долг: %d кр." % int(res.get("debt", 0)))
	if bool(res.get("failed", false)):
		_set_text("PenaltyLabel", "Штраф: квота не выполнена!")
	else:
		_set_text("PenaltyLabel", "Штраф: нет. Квота выполнена!")
	visible = true

func _on_next_day_pressed() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var bd: Node = get_node_or_null("/root/Breakdowns")
	var hd: Node = get_node_or_null("/root/HorrorDirector")
	var eb: Node = get_node_or_null("/root/EventBus")
	if gs != null:
		gs.call("next_day")
	if bd != null:
		bd.call("add_daily_wear")
	if hd != null:
		var day: int = int(gs.get("day")) if gs != null else 1
		hd.call("refresh_budget", day)
	if eb != null:
		eb.emit_signal("day_ended", int(gs.get("day")) if gs != null else 1)
	visible = false

func _set_text(n: String, t: String) -> void:
	var lab: Label = get_node_or_null(n) as Label
	if lab != null:
		lab.text = t
