extends Node
var day: int = 1
var money: int = 120
var phase: String = "day"
var failed: bool = false
func next_day() -> void:
	day += 1
func fail(reason: String) -> void:
	failed = true
	push_error("GAME OVER: " + reason)
func reset() -> void:
	day = 1
	money = 120
	phase = "day"
	failed = false
