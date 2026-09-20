class_name SlotButton
extends Button
# Кнопка слота: иконка-фигура по типу предмета + счётчик. Названия убраны.
const TYPE_COLOR := {
	"food": Color(0.95, 0.55, 0.15),
	"clothes": Color(0.25, 0.5, 0.95),
	"acc": Color(0.7, 0.35, 0.9),
	"tool": Color(0.85, 0.8, 0.3),
	"misc": Color(0.5, 0.5, 0.55),
}
# 0 круг (еда), 1 квадрат (одежда), 2 треугольник (аксессуар), 3 ромб (инструмент).
const TYPE_SHAPE := {"food": 0, "clothes": 1, "acc": 2, "tool": 3}

var area := ""
var idx := 0
var ui: Control
var item_id := ""
var item_n := 0

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_item(id: String, n: int) -> void:
	item_id = id
	item_n = n
	text = ""
	queue_redraw()

func clear_item(hint: String) -> void:
	item_id = ""
	item_n = 0
	text = hint
	queue_redraw()

func _draw() -> void:
	if item_id == "":
		return
	var t := str(Inventory.def(item_id).get("type", "misc"))
	var col: Color = TYPE_COLOR.get(t, Color(0.5, 0.5, 0.55))
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 8.0
	if r <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.11))
	match int(TYPE_SHAPE.get(t, 3)):
		0:
			draw_circle(c, r, col)
		1:
			draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), col)
		2:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r), c + Vector2(-r, r)]), col)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)
	if item_n > 1:
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(4, size.y - 6), "x%d" % item_n, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func _get_drag_data(_at: Vector2):
	var st: Dictionary = Inventory.get_slot(area, idx)
	if st.is_empty():
		return null
	var lab := Label.new()
	lab.text = str(Inventory.def(str(st["id"]))["name"])
	set_drag_preview(lab)
	return {"farea": area, "fi": idx}

func _can_drop_data(_at: Vector2, data) -> bool:
	if ui == null or not (data is Dictionary):
		return false
	return ui.can_accept(data, area, idx)

func _drop_data(_at: Vector2, data) -> void:
	if ui != null:
		ui.accept_drop(data, area, idx)
