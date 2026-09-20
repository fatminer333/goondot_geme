extends Node
signal phase_changed(phase: String)
var t_day: float = 600.0
var time_06_24: float = 8.0
var is_night: bool = false
func _process(delta: float) -> void:
	time_06_24 += (24.0 / t_day) * delta
	if time_06_24 >= 24.0:
		time_06_24 -= 24.0
		GameState.day += 1
	# ночь 00:00-06:00
	is_night = (time_06_24 >= 0.0 and time_06_24 < 6.0)
