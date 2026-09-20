extends Node
# Инвентарь: сумка 20, одежда 3 (0 голова,1 тело,2 ноги), аксессуары 2,
# хотбар 9, рука 1. Стек до 16 предметов одного типа.
signal changed

const MAX_STACK := 16
const SIZES := {"bag": 20, "wear": 3, "acc": 2, "hot": 9, "hand": 1}
const ORDER := ["bag", "wear", "acc", "hot", "hand"]

const DB := {
	"snack": {"name": "Перекус", "desc": "Быстрый перекус. +20 сытости.", "type": "food", "hunger": 20.0},
	"mre": {"name": "Паёк MRE", "desc": "Сухпаёк. +45 сытости.", "type": "food", "hunger": 45.0},
	"coffee": {"name": "Кофе", "desc": "Бодрит. +25 к бодрости.", "type": "food", "fatigue": 25.0},
	"filter": {"name": "Фильтр", "desc": "Фильтр для сервера. Запчасть.", "type": "tool"},
	"battery": {"name": "Батарейка", "desc": "Запасная батарея для фонаря.", "type": "tool"},
	"repair": {"name": "Ремкомплект", "desc": "Применить: чинит самый изношенный узел (-40%).", "type": "tool"},
	"hat": {"name": "Шапка", "desc": "Тёплая шапка. Слот: голова.", "type": "clothes", "slot": 0},
	"jacket": {"name": "Куртка", "desc": "Рабочая куртка. Слот: тело.", "type": "clothes", "slot": 1},
	"boots": {"name": "Ботинки", "desc": "Прочные ботинки. Слот: ноги.", "type": "clothes", "slot": 2},
	"watch": {"name": "Часы", "desc": "Показывают время. Аксессуар.", "type": "acc"},
	"charm": {"name": "Амулет", "desc": "На удачу. Аксессуар.", "type": "acc"},
}

var slots := {}

func _ready() -> void:
	for area in ORDER:
		var arr: Array = []
		arr.resize(int(SIZES[area]))
		arr.fill(null)
		slots[area] = arr

func def(id: String) -> Dictionary:
	return DB.get(id, {"name": id, "desc": "Без описания.", "type": "misc"})

func get_slot(area: String, i: int) -> Dictionary:
	if not slots.has(area):
		return {}
	var arr: Array = slots[area]
	if i < 0 or i >= arr.size():
		return {}
	return arr[i] if arr[i] != null else {}

func add_item(id: String, n: int = 1) -> int:
	if not DB.has(id) or n <= 0:
		return n
	var left := n
	var arr: Array = slots["bag"]
	for i in arr.size():
		if left <= 0:
			break
		if arr[i] != null and str(arr[i]["id"]) == id and int(arr[i]["n"]) < MAX_STACK:
			var room: int = MAX_STACK - int(arr[i]["n"])
			var put: int = mini(room, left)
			arr[i]["n"] = int(arr[i]["n"]) + put
			left -= put
	for i in arr.size():
		if left <= 0:
			break
		if arr[i] == null:
			var put: int = mini(MAX_STACK, left)
			arr[i] = {"id": id, "n": put}
			left -= put
	if left != n:
		changed.emit()
	return left

func count_total(id: String) -> int:
	var total := 0
	for area in ORDER:
		for st in slots[area]:
			if st != null and str(st["id"]) == id:
				total += int(st["n"])
	return total

func remove_total(id: String, n: int) -> bool:
	if count_total(id) < n:
		return false
	var left := n
	for area in ORDER:
		var arr: Array = slots[area]
		for i in arr.size():
			if left <= 0:
				break
			if arr[i] != null and str(arr[i]["id"]) == id:
				var take: int = mini(int(arr[i]["n"]), left)
				arr[i]["n"] = int(arr[i]["n"]) - take
				left -= take
				if int(arr[i]["n"]) <= 0:
					arr[i] = null
	changed.emit()
	return true

func can_place(area: String, i: int, id: String) -> bool:
	if not slots.has(area):
		return false
	if i < 0 or i >= (slots[area] as Array).size():
		return false
	var t := str(def(id).get("type", "misc"))
	match area:
		"wear":
			return t == "clothes" and int(def(id).get("slot", -1)) == i
		"acc":
			return t == "acc"
		"hand":
			return t != "clothes"
	return true

func move(farea: String, fi: int, tarea: String, ti: int, count: int = -1) -> bool:
	var src := get_slot(farea, fi)
	if src.is_empty():
		return false
	if farea == tarea and fi == ti:
		return false
	var id := str(src["id"])
	var have: int = int(src["n"])
	var want: int = have if count < 0 else mini(count, have)
	if not can_place(tarea, ti, id):
		return false
	if tarea == "hand":
		want = 1
	var dst := get_slot(tarea, ti)
	var farr: Array = slots[farea]
	var tarr: Array = slots[tarea]
	if dst.is_empty():
		tarr[ti] = {"id": id, "n": want}
		_shrink(farr, fi, want)
		changed.emit()
		return true
	if str(dst["id"]) == id:
		var room: int = MAX_STACK - int(dst["n"])
		if tarea == "hand":
			room = mini(room, 1 - int(dst["n"]))
		if room <= 0:
			return false
		var put: int = mini(room, want)
		tarr[ti]["n"] = int(dst["n"]) + put
		_shrink(farr, fi, put)
		changed.emit()
		return true
	if count >= 0:
		return false
	if not can_place(farea, fi, str(dst["id"])):
		return false
	tarr[ti] = {"id": id, "n": have}
	farr[fi] = {"id": str(dst["id"]), "n": int(dst["n"])}
	changed.emit()
	return true

func _shrink(arr: Array, i: int, n: int) -> void:
	arr[i]["n"] = int(arr[i]["n"]) - n
	if int(arr[i]["n"]) <= 0:
		arr[i] = null

func drop(area: String, i: int) -> bool:
	if get_slot(area, i).is_empty():
		return false
	(slots[area] as Array)[i] = null
	changed.emit()
	return true

func apply(area: String, i: int) -> String:
	var src := get_slot(area, i)
	if src.is_empty():
		return "Пусто."
	var id := str(src["id"])
	var d := def(id)
	var t := str(d.get("type", "misc"))
	if t == "food":
		if d.has("hunger"):
			Survival.eat(float(d["hunger"]))
		if d.has("fatigue"):
			Survival.fatigue = minf(100.0, float(Survival.get("fatigue")) + float(d["fatigue"]))
		_use_one(area, i)
		return "Применено: %s." % str(d["name"])
	if id == "repair":
		var worst := ""
		var worst_v := 0.0
		for k in Breakdowns.wear.keys():
			var w := float(Breakdowns.wear[k])
			if w > worst_v:
				worst_v = w
				worst = str(k)
		if worst == "":
			return "Всё цело, ремонт не нужен."
		Breakdowns.wear[worst] = maxf(0.0, worst_v - 40.0)
		_use_one(area, i)
		return "Отремонтировано: %s." % worst
	if t == "clothes":
		var ti: int = int(d.get("slot", 1))
		if move(area, i, "wear", ti):
			return "Надето: %s." % str(d["name"])
		return "Слот одежды занят."
	if t == "acc":
		for k in 2:
			if get_slot("acc", k).is_empty():
				if move(area, i, "acc", k):
					return "Надето: %s." % str(d["name"])
		return "Слоты аксессуаров заняты."
	return "Не применяется."

func _use_one(area: String, i: int) -> void:
	var arr: Array = slots[area]
	_shrink(arr, i, 1)
	changed.emit()

func to_hand(area: String, i: int) -> String:
	var src := get_slot(area, i)
	if src.is_empty():
		return "Пусто."
	var cur := get_slot("hand", 0)
	if not cur.is_empty():
		if add_item(str(cur["id"]), int(cur["n"])) > 0:
			return "Рука занята, в сумке нет места."
		(slots["hand"] as Array)[0] = null
	if move(area, i, "hand", 0, 1):
		return "В руке: %s." % str(def(str(src["id"]))["name"])
	return "Нельзя взять в руку."
