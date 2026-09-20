extends Node
signal blips_updated(blips: Dictionary)
var range_m: float = 80.0
var sweep_speed_deg: float = 90.0
var tick_sec: float = 0.25
var sweep_angle: float = 0.0
var blips: Dictionary = {}
var _tick_accum: float = 0.0
func _process(delta: float) -> void:
	sweep_angle = fposmod(sweep_angle + sweep_speed_deg * delta, 360.0)
	for id in blips.keys():
		var b: Dictionary = blips[id]
		var a: float = float(b.get("angle_deg", 0.0))
		if absf(_angle_diff(sweep_angle, a)) >= 5.0:
			b["alpha"] = maxf(0.0, float(b.get("alpha", 0.0)) - delta * 0.4)
			blips[id] = b
	_tick_accum += delta
	while _tick_accum >= tick_sec:
		_tick_accum -= tick_sec
		_rebuild_blips()
func _rebuild_blips() -> void:
	var sm: Node = get_node_or_null("/root/SignalManager")
	if sm == null:
		return
	var active: Dictionary = sm.get("active")
	var fresh: Dictionary = {}
	for id in active.keys():
		var angle: float = float(absi(hash(id)) % 360)
		var dist: float = float(20 + (absi(hash(id)) % 60))
		var prev: float = 0.0
		if blips.has(id):
			prev = float((blips[id] as Dictionary).get("alpha", 0.0))
		var alpha: float = prev
		if absf(_angle_diff(sweep_angle, angle)) < 5.0:
			alpha = 1.0
		fresh[id] = {"angle_deg": angle, "dist_m": dist, "alpha": alpha}
	blips = fresh
	blips_updated.emit(blips)
func _angle_diff(a: float, b: float) -> float:
	return fposmod(a - b + 180.0, 360.0) - 180.0
