extends Node
var hunger: float = 100.0
var fatigue: float = 100.0
func _process(delta: float) -> void:
	hunger = maxf(0.0, hunger - (100.0 / 480.0) * delta)
	fatigue = maxf(0.0, fatigue - (100.0 / 780.0) * delta)
	if hunger <= 0.0 and not GameState.failed:
		GameState.fail("голод")
func eat(a: float) -> void:
	hunger = minf(100.0, hunger + a)
func sleep(sec: float) -> void:
	fatigue = minf(100.0, fatigue + (100.0 / 110.0) * sec)
	hunger = maxf(0.0, hunger - 30.0 * (sec / 110.0))
